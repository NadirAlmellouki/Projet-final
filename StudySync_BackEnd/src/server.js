import "dotenv/config";
import { httpServer } from "./app.js";
import sequelize from "./config/db.config.js";

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log("✅ Database connection verified");

    await sequelize.sync();
    console.log("✅ Database synced");

    httpServer.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error("❌ Failed to start server:", err.message);
    process.exit(1);
  }
};

startServer();
