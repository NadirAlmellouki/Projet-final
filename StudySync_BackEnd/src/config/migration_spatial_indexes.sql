-- ============================================================
--  StudySync — Migration : Index spatiaux GIST + saved_locations
--  Member 3 — Week 4 : Performance tuning
-- ============================================================

-- 1. Index GIST sur study_sessions.location
--    Accélère ST_DWithin et ST_Distance pour les requêtes "sessions proches"
CREATE INDEX IF NOT EXISTS idx_study_sessions_location
  ON study_sessions USING GIST (location);

-- 2. Index GIST sur users.current_location
--    Accélère getNearbyActiveUsers (utilisateurs actifs dans les 5 dernières minutes)
CREATE INDEX IF NOT EXISTS idx_users_current_location
  ON users USING GIST (current_location);

-- 3. Index sur users.last_seen (utilisé dans le filtre NOW() - INTERVAL '5 minutes')
CREATE INDEX IF NOT EXISTS idx_users_last_seen
  ON users (last_seen DESC);

-- 4. Index sur study_sessions.status (filtre fréquent : status = 'created')
CREATE INDEX IF NOT EXISTS idx_study_sessions_status
  ON study_sessions (status);

-- 5. Table saved_locations (si elle n'existe pas encore)
CREATE TABLE IF NOT EXISTS saved_locations (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  location    GEOGRAPHY(POINT, 4326) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index GIST sur saved_locations.location
CREATE INDEX IF NOT EXISTS idx_saved_locations_location
  ON saved_locations USING GIST (location);

-- Index sur saved_locations.user_id (récupérer les lieux d'un user)
CREATE INDEX IF NOT EXISTS idx_saved_locations_user_id
  ON saved_locations (user_id);

-- 6. Colonne current_location sur users (si elle n'existe pas)
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_location GEOGRAPHY(POINT, 4326);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP;
