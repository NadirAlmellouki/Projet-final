import sequelize from "../config/db.config.js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Applique la migration des index GIST et de la table saved_locations
 * Commande : node src/scripts/runMigration.js
 */
const runMigration = async () => {
  try {
    console.log("🔌 Connexion à la base de données...");
    await sequelize.authenticate();
    console.log("✅ Connexion réussie");

    const sql = readFileSync(
      join(__dirname, "../config/migration_spatial_indexes.sql"),
      "utf8"
    );

    // Exécuter chaque statement séparément
    const statements = sql
      .split(";")
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && !s.startsWith("--"));

    for (const statement of statements) {
      console.log(`\n⚙️  Exécution : ${statement.slice(0, 60)}...`);
      await sequelize.query(statement);
      console.log("   ✅ OK");
    }

    console.log("\n🎉 Migration terminée avec succès !");
    process.exit(0);
  } catch (error) {
    console.error("❌ Erreur de migration :", error.message);
    process.exit(1);
  }
};

runMigration();
