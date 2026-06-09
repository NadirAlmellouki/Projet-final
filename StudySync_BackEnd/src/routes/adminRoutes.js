import { Router } from "express";
import { authenticate } from "../middlewares/auth.middleware.js";
import authorizeRoles from "../middleware/authorizeRoles.js";
import adminController from "../controllers/adminController.js";

const router = Router();

router.use(authenticate);
router.use(authorizeRoles("admin", "super_admin"));

router.get("/users", adminController.listUsers);
router.get("/users/:id", adminController.getUserDetail);
router.patch("/users/:id/suspend", adminController.suspendUser);
router.patch("/users/:id/unsuspend", adminController.unsuspendUser);
router.patch("/users/:id/ban", adminController.banUser);
router.delete("/sessions/:id", adminController.deleteSession);
router.patch("/messages/:id/delete", adminController.deleteMessage);

export default router;
