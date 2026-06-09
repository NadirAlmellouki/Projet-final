import sequelize from "../config/db.config.js";

// Mettre à jour la position d'un utilisateur
export const updateUserLocation = async (userId, latitude, longitude) => {
  await sequelize.query(`
    UPDATE users 
    SET 
      current_location = ST_MakePoint(:lng, :lat)::geography,
      last_seen = NOW()
    WHERE id = :userId
  `, {
    replacements: { lat: latitude, lng: longitude, userId },
    type: sequelize.QueryTypes.UPDATE
  });
};

// Trouver les utilisateurs actifs proches (actifs dans les 5 dernières minutes)
export const getNearbyActiveUsers = async (latitude, longitude, radiusKm = 5) => {
  const users = await sequelize.query(`
    SELECT id, first_name, last_name, major, trust_score,
      ST_Distance(
        current_location::geography,
        ST_MakePoint(:lng, :lat)::geography
      ) / 1000 AS distance_km
    FROM users
    WHERE 
      last_seen > NOW() - INTERVAL '5 minutes'
      AND current_location IS NOT NULL
      AND ST_DWithin(
        current_location::geography,
        ST_MakePoint(:lng, :lat)::geography,
        :radius
      )
    ORDER BY distance_km ASC
  `, {
    replacements: { 
      lat: latitude, 
      lng: longitude, 
      radius: radiusKm * 1000 
    },
    type: sequelize.QueryTypes.SELECT
  });
  return users;
};