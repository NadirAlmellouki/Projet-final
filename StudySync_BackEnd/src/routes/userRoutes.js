import { Router } from "express";
import userController from "../controllers/userController.js";
import { authenticate } from "../middlewares/auth.middleware.js";

const router = Router();

router.get("/me", authenticate, userController.getMe);
router.put("/me", authenticate, userController.updateMe);
router.get("/blocked", authenticate, userController.getBlockedUsers);
router.post("/block", authenticate, userController.blockUser);
router.delete("/block/:blockedUserId", authenticate, userController.unblockUser);
router.get("/:id", userController.getUserById);

export default router;
