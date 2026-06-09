/**
 * Test automatique des endpoints admin (actions destructives).
 * Prérequis : npm run db:seed:test
 * Usage     : npm run test:admin
 */
import "dotenv/config";
import {
  withServer,
  api,
  getToken,
  getUser,
  TestRunner,
  IDS,
  PASSWORD,
} from "./test-helpers.js";

const run = async () => {
  let failed = 0;

  await withServer(async () => {
    const t = new TestRunner("Admin endpoints");
    console.log("\n══ Tests admin ══\n");

    const adminLogin = await api("POST", "/api/auth/admin/login", {
      body: { email: "admin@studysync.ma", password: PASSWORD },
    });
    t.check("POST /api/auth/admin/login → 200", adminLogin.status === 200);
    const adminToken = getToken(adminLogin);
    const adminUser = getUser(adminLogin);
    t.check("Token admin reçu", Boolean(adminToken));
    t.check(
      "Rôle utilisateur = admin (pas student)",
      adminUser?.role === "admin",
      `role=${adminUser?.role}`,
    );

    const studentLogin = await api("POST", "/api/auth/login", {
      body: { email: "sara@univ.ma", password: PASSWORD },
    });
    const studentToken = getToken(studentLogin);

    const studentAdminLogin = await api("POST", "/api/auth/admin/login", {
      body: { email: "sara@univ.ma", password: PASSWORD },
    });
    t.check("Student ne peut pas admin/login → 403", studentAdminLogin.status === 403);

    const forbidden = await api("GET", "/api/admin/users", { token: studentToken });
    t.check("GET /api/admin/users (student) → 403", forbidden.status === 403);

    const listUsers = await api("GET", "/api/admin/users?page=1&limit=10&q=sara", {
      token: adminToken,
    });
    t.check("GET /api/admin/users → 200", listUsers.status === 200);
    t.check("Liste contient des users", (listUsers.data?.users?.length ?? 0) > 0);

    const userDetail = await api("GET", `/api/admin/users/${IDS.sara}`, {
      token: adminToken,
    });
    t.check("GET /api/admin/users/:id → 200", userDetail.status === 200);
    t.check("Détail user correct", userDetail.data?.user?.email === "sara@univ.ma");

    const suspend = await api("PATCH", `/api/admin/users/${IDS.jean}/suspend`, {
      token: adminToken,
      body: {
        suspended_until: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        reason: "Test auto suspend",
      },
    });
    t.check("PATCH suspend → 200", suspend.status === 200);
    t.check("Jean suspendu", suspend.data?.user?.is_suspended === true);

    const unsuspend = await api("PATCH", `/api/admin/users/${IDS.jean}/unsuspend`, {
      token: adminToken,
      body: { reason: "Test auto unsuspend" },
    });
    t.check("PATCH unsuspend → 200", unsuspend.status === 200);
    t.check("Jean non suspendu", unsuspend.data?.user?.is_suspended === false);

    const ban = await api("PATCH", `/api/admin/users/${IDS.jean}/ban`, {
      token: adminToken,
      body: { reason: "Test auto ban" },
    });
    t.check("PATCH ban → 200", ban.status === 200);
    t.check("Jean banni", ban.data?.user?.is_banned === true);

    const delSession = await api("DELETE", `/api/admin/sessions/${IDS.sessionCancelled}`, {
      token: adminToken,
      body: { reason: "Test auto delete session" },
    });
    t.check("DELETE session → 200", delSession.status === 200);

    const delSessionAgain = await api("DELETE", `/api/admin/sessions/${IDS.sessionCancelled}`, {
      token: adminToken,
      body: { reason: "Retry" },
    });
    t.check("DELETE session inexistante → 404", delSessionAgain.status === 404);

    const delMsg = await api("PATCH", `/api/admin/messages/${IDS.messageActive}/delete`, {
      token: adminToken,
      body: { reason: "Test auto delete message" },
    });
    t.check("PATCH delete message → 200", delMsg.status === 200);
    t.check("Message is_deleted=true", delMsg.data?.data?.is_deleted === true);

    failed = t.failed;
    t.summary();

    if (failed > 0) {
      console.log("\n→ Relancez : npm run db:seed:test puis npm run test:admin");
    }
  });

  process.exit(failed > 0 ? 1 : 0);
};

run().catch((err) => {
  console.error("Erreur test:", err.message);
  process.exit(1);
});
