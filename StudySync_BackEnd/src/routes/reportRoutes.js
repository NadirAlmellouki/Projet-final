import { Router } from "express";
import reportController from "../controllers/reportController.js";
import { authenticate } from "../middlewares/auth.middleware.js";
import authorizeRoles from "../middleware/authorizeRoles.js";

const router = Router();

router.post("/", authenticate, reportController.createReport);
router.get(
  "/",
  authenticate,
  authorizeRoles("moderator", "admin", "super_admin"),
  reportController.listReports,
);
router.patch(
  "/:id/resolve",
  authenticate,
  authorizeRoles("moderator", "admin", "super_admin"),
  reportController.resolveReport,
);

export default router;
