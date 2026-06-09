import express from "express";
import {
  getRecommendations,
  getSessionMatchScore,
  verifyCheckin,
  getHeatmap,
  getDistanceRings,
  getNearbySessions,
} from "../controllers/matchingController.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = express.Router();

// Toutes les routes matching nécessitent un JWT valide
router.use(authMiddleware);

router.get("/recommend",             getRecommendations);      // liste recommandations
router.get("/score/:sessionId",      getSessionMatchScore);    // score pour 1 session
router.post("/checkin-verify",       verifyCheckin);           // vérif geofence
router.get("/heatmap",               getHeatmap);              // spots populaires
router.get("/distance-rings",        getDistanceRings);        // anneaux 500m/1km/2km
router.get("/nearby-sessions",       getNearbySessions);       // sessions fuzzy location

export default router;
