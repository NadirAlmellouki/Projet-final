import express from "express";
import sequelize from "../config/db.config.js";
import { authMiddleware } from "../middleware/auth.middleware.js";

const router = express.Router();

// Toutes les routes locations nécessitent un JWT valide
router.use(authMiddleware);

// POST /api/locations/saved — Sauvegarder un lieu
router.post("/saved", async (req, res) => {
  const { name, latitude, longitude } = req.body;
  const userId = req.user.id; // ✅ depuis JWT, pas du body

  if (!name || !latitude || !longitude) {
    return res.status(400).json({ error: "name, latitude et longitude sont requis" });
  }

  try {
    await sequelize.query(`
      INSERT INTO saved_locations (user_id, name, location, created_at, updated_at)
      VALUES (:userId, :name, ST_MakePoint(:lng, :lat)::geography, NOW(), NOW())
    `, {
      replacements: { userId, name, lat: parseFloat(latitude), lng: parseFloat(longitude) },
      type: sequelize.QueryTypes.INSERT,
    });

    res.status(201).json({ success: true, message: `Lieu "${name}" sauvegardé !` });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

// GET /api/locations/saved — Récupérer ses lieux sauvegardés
router.get("/saved", async (req, res) => {
  const userId = req.user.id;
  try {
    const locations = await sequelize.query(`
      SELECT
        id, name,
        ST_X(location::geometry) AS longitude,
        ST_Y(location::geometry) AS latitude,
        created_at
      FROM saved_locations
      WHERE user_id = :userId
      ORDER BY created_at DESC
    `, {
      replacements: { userId },
      type: sequelize.QueryTypes.SELECT,
    });

    res.json({ success: true, count: locations.length, locations });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

// DELETE /api/locations/saved/:id — Supprimer un lieu sauvegardé
router.delete("/saved/:id", async (req, res) => {
  const userId = req.user.id;
  try {
    // Vérifier que le lieu appartient bien à cet utilisateur
    await sequelize.query(`
      DELETE FROM saved_locations WHERE id = :id AND user_id = :userId
    `, {
      replacements: { id: req.params.id, userId },
      type: sequelize.QueryTypes.DELETE,
    });

    res.json({ success: true, message: "Lieu supprimé !" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

export default router;
