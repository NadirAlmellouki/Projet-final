import "dotenv/config";
import sequelize from "../src/config/db.config.js";

const run = async () => {
  await sequelize.authenticate();
  const [rows] = await sequelize.query(`
    SELECT email, role::text AS role, id
    FROM users
    ORDER BY email;
  `);
  console.log("\nRôles en base de données :\n");
  console.table(rows);
  await sequelize.close();
};

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
