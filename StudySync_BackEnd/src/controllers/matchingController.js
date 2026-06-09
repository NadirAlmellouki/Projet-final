import { getRecommendedSessions, calculateMatchScore } from "../services/matchingService.js";
import { isWithinGeofence, getHeatmapData, findSessionsNearby } from "../services/geoService.js";
import { calculateDistance } from "../utils/haversine.js";
import sequelize from "../config/db.config.js";

// GET /api/matches/recommend
export const getRecommendations = async (req, res) => {
  try {
    const { latitude, longitude, radius = 5 } = req.query;
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "latitude et longitude sont requis" });
    }
    const userProfile = {
      ...req.user,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
    };
    const sessions = await getRecommendedSessions(userProfile, parseFloat(radius));
    res.json({ success: true, count: sessions.length, sessions });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// GET /api/matches/score/:sessionId
export const getSessionMatchScore = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { latitude, longitude } = req.query;
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "latitude et longitude sont requis" });
    }
    const results = await sequelize.query(
      `SELECT *,
        ST_X(location::geometry) AS longitude,
        ST_Y(location::geometry) AS latitude
       FROM study_sessions
       WHERE id = :sessionId AND status = 'created'`,
      { replacements: { sessionId }, type: sequelize.QueryTypes.SELECT }
    );
    if (!results.length) return res.status(404).json({ error: "Session non trouvée" });
    const session = results[0];
    const userProfile = {
      ...req.user,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
    };
    const score = calculateMatchScore(session, userProfile);
    const distanceKm = calculateDistance(
      userProfile.latitude, userProfile.longitude,
      session.latitude, session.longitude
    );
    res.json({
      success: true,
      session_id: sessionId,
      match_score: score,
      distance_km: parseFloat(distanceKm.toFixed(2)),
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// POST /api/matches/checkin-verify
export const verifyCheckin = async (req, res) => {
  try {
    const { sessionLat, sessionLng, userLat, userLng } = req.body;

    const withinGeofence = await isWithinGeofence(
      sessionLat, sessionLng,
      userLat, userLng
    );

    res.json({
      success: true,
      can_checkin: withinGeofence,
      message: withinGeofence
        ? "Tu es dans la zone, tu peux te check-in !"
        : "Tu es trop loin de la session (rayon 100m requis)",
    });
  } catch (error) {
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// GET /api/matches/heatmap
export const getHeatmap = async (req, res) => {
  try {
    const data = await getHeatmapData();
    res.json({ success: true, spots: data });
  } catch (error) {
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// GET /api/matches/distance-rings?latitude=...&longitude=...
export const getDistanceRings = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "latitude et longitude sont requis" });
    }
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const sessions = await findSessionsNearby(lat, lng, 5);
    const rings = { ring_500m: [], ring_1km: [], ring_2km: [], ring_5km: [] };
    sessions.forEach((session) => {
      const d = parseFloat(session.distance_km);
      if (d <= 0.5)      rings.ring_500m.push(session);
      else if (d <= 1)   rings.ring_1km.push(session);
      else if (d <= 2)   rings.ring_2km.push(session);
      else               rings.ring_5km.push(session);
    });
    res.json({
      success: true,
      center: { latitude: lat, longitude: lng },
      rings: {
        ring_500m: { label: "< 500m", count: rings.ring_500m.length, sessions: rings.ring_500m },
        ring_1km:  { label: "< 1km",  count: rings.ring_1km.length,  sessions: rings.ring_1km },
        ring_2km:  { label: "< 2km",  count: rings.ring_2km.length,  sessions: rings.ring_2km },
        ring_5km:  { label: "< 5km",  count: rings.ring_5km.length,  sessions: rings.ring_5km },
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
};

// GET /api/matches/nearby-sessions — fuzzy location (coords masquées avant check-in)
export const getNearbySessions = async (req, res) => {
  try {
    const { latitude, longitude, radius = 5 } = req.query;
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "latitude et longitude sont requis" });
    }
    const sessions = await findSessionsNearby(parseFloat(latitude), parseFloat(longitude), parseFloat(radius));
    const safeSessions = sessions.map((s) => {
      const d = parseFloat(s.distance_km);
      let fuzzyDistance;
      if (d <= 0.5)    fuzzyDistance = "< 500m";
      else if (d <= 1) fuzzyDistance = "< 1km";
      else if (d <= 2) fuzzyDistance = "< 2km";
      else             fuzzyDistance = "< 5km";
      const { latitude: _lat, longitude: _lng, location, ...safeSession } = s;
      return { ...safeSession, fuzzy_distance: fuzzyDistance };
    });
    res.json({ success: true, count: safeSessions.length, sessions: safeSessions });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
};
