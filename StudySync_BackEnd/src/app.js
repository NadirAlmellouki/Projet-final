import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import cors from "cors";

import sequelize from "./config/db.config.js";
import "./models/index.js";

import authRoutes from "./routes/auth.routes.js";
import healthRoutes from "./routes/health.routes.js";
import matchingRoutes from "./routes/matching.routes.js";
import locationsRoutes from "./routes/locations.routes.js";
import sessionsRoutes from "./routes/sessions.routes.js";
import ratingRoutes from "./routes/ratingRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";

import { initLocationSocket } from "./socket/locationHandler.js";
import { notFoundHandler, errorHandler } from "./middlewares/error.middleware.js";

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: "*" },
});

app.use(cors());
app.use(express.json());

app.get("/", (_req, res) => {
  res.send("StudySync API is running 🚀");
});

app.use("/api/auth", authRoutes);
app.use("/api/health", healthRoutes);
app.use("/api/matches", matchingRoutes);
app.use("/api/locations", locationsRoutes);
app.use("/api/sessions", sessionsRoutes);
app.use("/api/ratings", ratingRoutes);
app.use("/api/users", userRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/admin", adminRoutes);

sequelize
  .query(`
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url TEXT;
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
  ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS study_type VARCHAR(50) DEFAULT 'active_discussion';
  ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'public';
  ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS description VARCHAR(200);
  ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
  ALTER TABLE ratings ADD COLUMN IF NOT EXISTS overall_score INTEGER;
  ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
  ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_session_id UUID;
  ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_message_id UUID;
  ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_report_id UUID;
  ALTER TABLE reports ADD COLUMN IF NOT EXISTS resolution_action TEXT;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo TEXT;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS year INTEGER;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255);
  ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_password_token VARCHAR(255);
  ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_password_expires TIMESTAMPTZ;
  ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
`)
  .catch(() => {});

sequelize
  .query(
    `CREATE UNIQUE INDEX IF NOT EXISTS users_google_id_unique ON users (google_id) WHERE google_id IS NOT NULL;`
  )
  .catch(() => {});

sequelize
  .query(`
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'saved_locations'
          AND column_name = 'user_id'
          AND udt_name <> 'uuid'
      ) THEN
        DROP TABLE saved_locations;
      END IF;
    END $$;
  `)
  .then(() =>
    sequelize.query(`
      CREATE TABLE IF NOT EXISTS saved_locations (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        name VARCHAR(100) NOT NULL,
        location GEOGRAPHY(POINT, 4326),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `),
  )
  .then(() => console.log("✅ Table saved_locations prête"))
  .catch((err) => console.warn("saved_locations:", err.message));

initLocationSocket(io);

app.use(notFoundHandler);
app.use(errorHandler);

export { httpServer, app, io };
export default app;
