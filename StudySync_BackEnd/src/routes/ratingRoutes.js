import { Router } from "express";
import ratingController from "../controllers/ratingController.js";
import { authenticate } from "../middlewares/auth.middleware.js";

const router = Router();

router.post("/", authenticate, ratingController.createRating);
router.get("/user/:userId", ratingController.getUserRatings);

export default router;
