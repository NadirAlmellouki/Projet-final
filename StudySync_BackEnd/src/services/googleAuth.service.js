import { OAuth2Client } from "google-auth-library";

const getClient = () => {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  if (!clientId) {
    throw new Error("GOOGLE_CLIENT_ID manquant dans .env");
  }
  return new OAuth2Client(clientId);
};

export const verifyGoogleIdToken = async (idToken) => {
  const client = getClient();
  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });
  const payload = ticket.getPayload();
  if (!payload?.email) {
    throw new Error("Token Google invalide : email manquant");
  }
  if (payload.email_verified === false) {
    throw new Error("Email Google non vérifié");
  }

  return {
    googleId: payload.sub,
    email: payload.email.toLowerCase(),
    firstName: payload.given_name || payload.name?.split(" ")[0] || "Utilisateur",
    lastName:
      payload.family_name ||
      payload.name?.split(" ").slice(1).join(" ") ||
      "Google",
    picture: payload.picture,
  };
};
