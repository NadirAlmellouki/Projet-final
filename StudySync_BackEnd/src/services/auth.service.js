import crypto from "crypto";
import bcrypt from "bcryptjs";
import ApiError from "../utils/ApiError.js";
import { signToken } from "../utils/jwt.util.js";
import User from "../models/User.js";
import { sendPasswordResetEmail } from "./email.service.js";
import { verifyGoogleIdToken } from "./googleAuth.service.js";

const SALT_ROUNDS = 10;

export const register = async (userData) => {
  const existing = await User.findOne({ where: { email: userData.email } });
  if (existing) {
    throw ApiError.conflict("Email already in use");
  }

  const { password, ...profile } = userData;
  const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

  const user = await User.create({
    ...profile,
    password_hash,
    role: "student",
  });

  const token = signToken({ id: user.id, email: user.email, role: user.role });

  return { user: user.toJSON(), token };
};

export const login = async ({ email, password }) => {
  const user = await User.findOne({ where: { email } });
  if (!user) {
    throw ApiError.unauthorized("Invalid email or password");
  }

  if (!user.password_hash) {
    throw ApiError.badRequest(
      "Ce compte utilise Google. Connectez-vous avec Google."
    );
  }

  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    throw ApiError.unauthorized("Invalid email or password");
  }

  const token = signToken({ id: user.id, email: user.email, role: user.role });

  const { password_hash: _, ...safeUser } = user.toJSON();
  return { user: safeUser, token };
};

export const adminLogin = async ({ email, password }) => {
  const found = await User.findOne({ where: { email } });
  if (!found) {
    throw ApiError.unauthorized("Invalid email or password");
  }

  const isMatch = await bcrypt.compare(password, found.password_hash);
  if (!isMatch) {
    throw ApiError.unauthorized("Invalid email or password");
  }

  const role = found.getDataValue("role");
  if (!["admin", "super_admin"].includes(role)) {
    throw ApiError.forbidden("Admin access required");
  }

  const token = signToken({ id: found.id, email: found.email, role });
  const { password_hash: _, ...safeUser } = found.toJSON();
  return { user: { ...safeUser, role }, token };
};

export const getProfile = async (userId) => {
  const user = await User.findByPk(userId);
  if (!user) {
    throw ApiError.notFound("User not found");
  }
  return user;
};

const sanitizeUser = (user) => {
  const { password_hash, reset_password_token, reset_password_expires, ...safe } =
    user.toJSON();
  return safe;
};

export const requestPasswordReset = async (email) => {
  const user = await User.findOne({ where: { email: email.toLowerCase().trim() } });

  if (!user || !user.password_hash) {
    return { message: "Si un compte existe, un email a été envoyé." };
  }

  const token = crypto.randomBytes(32).toString("hex");
  const expires = new Date(Date.now() + 60 * 60 * 1000);

  await user.update({
    reset_password_token: token,
    reset_password_expires: expires,
  });

  const appUrl =
    process.env.FRONTEND_RESET_URL ||
    process.env.APP_RESET_URL ||
    "http://localhost:8080";
  const resetUrl = `${appUrl.replace(/\/$/, "")}/reset-password?token=${token}`;

  try {
    const mailResult = await sendPasswordResetEmail({
      to: user.email,
      resetUrl,
    });

    return {
      message: "Si un compte existe, un email a été envoyé.",
      email_sent: mailResult.sent,
      ...(mailResult.devLink ? { dev_reset_link: mailResult.devLink } : {}),
    };
  } catch (err) {
    console.error("[email] Échec envoi SMTP:", err?.message || err);
    const isDev = process.env.NODE_ENV !== "production";
    return {
      message: "Si un compte existe, un email a été envoyé.",
      email_sent: false,
      ...(isDev
        ? {
            dev_reset_link: resetUrl,
            email_error:
              "L'email n'a pas pu être envoyé (vérifiez SMTP / mot de passe d'application Gmail). Utilisez le lien ci-dessous.",
          }
        : {
            email_error:
              "L'email n'a pas pu être envoyé. Réessayez plus tard ou contactez le support.",
          }),
    };
  }
};

export const resetPassword = async ({ token, password }) => {
  if (!token || !password) {
    throw ApiError.badRequest("token et password requis");
  }
  if (password.length < 8) {
    throw ApiError.badRequest("Le mot de passe doit contenir au moins 8 caractères");
  }

  const user = await User.findOne({
    where: { reset_password_token: token },
  });

  if (!user || !user.reset_password_expires) {
    throw ApiError.badRequest("Lien invalide ou expiré");
  }

  if (new Date(user.reset_password_expires) < new Date()) {
    throw ApiError.badRequest("Lien expiré. Demandez un nouveau lien.");
  }

  const password_hash = await bcrypt.hash(password, SALT_ROUNDS);
  await user.update({
    password_hash,
    reset_password_token: null,
    reset_password_expires: null,
  });

  return { message: "Mot de passe mis à jour" };
};

export const loginWithGoogle = async (idToken) => {
  const profile = await verifyGoogleIdToken(idToken);

  let user = await User.findOne({ where: { google_id: profile.googleId } });
  let isNewUser = false;

  if (!user) {
    user = await User.findOne({ where: { email: profile.email } });
    if (user) {
      await user.update({
        google_id: profile.googleId,
        profile_photo: user.profile_photo || profile.picture,
      });
    }
  }

  if (!user) {
    isNewUser = true;
    const password_hash = await bcrypt.hash(
      crypto.randomBytes(24).toString("hex"),
      SALT_ROUNDS
    );
    user = await User.create({
      first_name: profile.firstName,
      last_name: profile.lastName,
      email: profile.email,
      google_id: profile.googleId,
      password_hash,
      profile_photo: profile.picture,
      role: "student",
    });
  }

  const token = signToken({ id: user.id, email: user.email, role: user.role });
  return { user: sanitizeUser(user), token, isNewUser };
};
