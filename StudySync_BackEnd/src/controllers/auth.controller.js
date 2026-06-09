import * as authService from "../services/auth.service.js";
import {
  validateLogin,
  validateRegister,
  validateForgotPassword,
  validateResetPassword,
  validateGoogleAuth,
} from "../validators/auth.validator.js";

export const register = async (req, res) => {
  const data = validateRegister(req.body);
  const { user, token } = await authService.register(data);

  res.status(201).json({
    success: true,
    message: "User registered successfully",
    data: { user, token },
  });
};

export const login = async (req, res) => {
  const data = validateLogin(req.body);
  const { user, token } = await authService.login(data);

  res.status(200).json({
    success: true,
    message: "Login successful",
    data: { user, token },
  });
};

export const adminLogin = async (req, res) => {
  const data = validateLogin(req.body);
  const { user, token } = await authService.adminLogin(data);

  res.status(200).json({
    success: true,
    message: "Admin login successful",
    data: { user, token },
  });
};

export const getMe = async (req, res) => {
  const userId = req.user.id ?? req.user.userId;
  const user = await authService.getProfile(userId);

  res.status(200).json({
    success: true,
    data: { user },
  });
};

export const forgotPassword = async (req, res) => {
  const { email } = validateForgotPassword(req.body);
  const result = await authService.requestPasswordReset(email);

  res.status(200).json({
    success: true,
    ...result,
  });
};

export const resetPassword = async (req, res) => {
  const data = validateResetPassword(req.body);
  const result = await authService.resetPassword(data);

  res.status(200).json({
    success: true,
    ...result,
  });
};

export const googleAuth = async (req, res) => {
  const { id_token } = validateGoogleAuth(req.body);
  const { user, token } = await authService.loginWithGoogle(id_token);

  res.status(200).json({
    success: true,
    message: "Google login successful",
    data: { user, token },
  });
};
