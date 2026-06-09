import ApiError from "../utils/ApiError.js";
import { verifyToken } from "../utils/jwt.util.js";

export const normalizeAuthUser = (decoded) => {
  const id = decoded.id ?? decoded.userId;
  return {
    ...decoded,
    id,
    userId: id,
    role: decoded.role,
    email: decoded.email,
  };
};

export const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return next(ApiError.unauthorized("Access token required"));
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = verifyToken(token);
    req.user = normalizeAuthUser(decoded);
    next();
  } catch {
    return next(ApiError.unauthorized("Invalid or expired token"));
  }
};

export const authMiddleware = authenticate;
