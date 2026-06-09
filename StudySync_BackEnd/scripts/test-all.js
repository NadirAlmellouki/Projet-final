import "dotenv/config";
import { withServer, BASE } from "./test-helpers.js";

const log = (icon, msg) => console.log(`${icon} ${msg}`);

const runStep = async (name, fn) => {
  try {
    await fn();
    log("✓", name);
    return true;
  } catch (err) {
    log("✗", `${name} — ${err.message}`);
    return false;
  }
};

const fetchJson = async (url, options = {}) => {
  const res = await fetch(url, options);
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`${res.status} — ${body.message || JSON.stringify(body)}`);
  }
  return body;
};

let ok = true;

ok =
  (await runStep("Import modèles + associations", async () => {
    await import("../src/models/index.js");
  })) && ok;

ok =
  (await runStep("Connexion BDD", async () => {
    const { default: sequelize } = await import("../src/config/db.config.js");
    await sequelize.authenticate();
    await sequelize.close();
  })) && ok;

await withServer(async () => {
  ok =
    (await runStep(`GET ${BASE}/`, async () => {
      const res = await fetch(`${BASE}/`);
      const text = await res.text();
      if (!res.ok || !text.includes("StudySync")) throw new Error("réponse invalide");
    })) && ok;

  ok =
    (await runStep(`GET ${BASE}/api/health`, async () => {
      const body = await fetchJson(`${BASE}/api/health`);
      if (!body.success) throw new Error(body.message);
      console.log("   BDD:", body.database);
    })) && ok;

  ok =
    (await runStep("POST /api/auth/admin/login", async () => {
      const body = await fetchJson(`${BASE}/api/auth/admin/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "admin@studysync.ma",
          password: "Password123",
        }),
      });
      if (!body.data?.token) throw new Error("token manquant");
      if (body.data?.user?.role !== "admin") {
        throw new Error(`rôle attendu admin, reçu: ${body.data?.user?.role}`);
      }
    })) && ok;
});

console.log(ok ? "\n✅ test:all OK" : "\n❌ test:all échoué");
process.exit(ok ? 0 : 1);
