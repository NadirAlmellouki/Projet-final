import jwt from "jsonwebtoken";
import { normalizeAuthUser } from "../middlewares/auth.middleware.js";

/**
 * Middleware JWT — routes matching / locations (membre 3)
 */
export const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token manquant ou invalide" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = normalizeAuthUser(decoded);
    next();
  } catch {
    return res.status(401).json({ error: "Token expiré ou invalide" });
  }
};

export const verifySocketToken = (token) => {
  if (!token) throw new Error("Token manquant");
  return jwt.verify(token, process.env.JWT_SECRET);
};
