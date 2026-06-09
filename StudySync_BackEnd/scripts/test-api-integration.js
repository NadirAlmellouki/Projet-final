/**
 * Tests d'intégration HTTP — tous les groupes d'endpoints.
 * Prérequis : npm run db:seed:test
 * Usage     : npm run test:api
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
  BASE,
} from "./test-helpers.js";

const CASABLANCA = { latitude: 33.9716, longitude: -6.8498 };

const login = async (email) =>
  api("POST", "/api/auth/login", { body: { email, password: PASSWORD } });

const adminLogin = async (email = "admin@studysync.ma") =>
  api("POST", "/api/auth/admin/login", { body: { email, password: PASSWORD } });

const run = async () => {
  let totalFailed = 0;

  await withServer(async () => {
    const auth = new TestRunner("Auth");
    console.log("\n══ Auth ══");

    const health = await api("GET", "/api/health");
    auth.check("GET /api/health → 200", health.status === 200 && health.data?.success);

    const root = await fetch(`${BASE}/`);
    auth.check("GET / → 200", root.ok);

    const adminRes = await adminLogin();
    const adminToken = getToken(adminRes);
    const adminUser = getUser(adminRes);
    auth.check("POST /api/auth/admin/login → 200", adminRes.status === 200);
    auth.check("Rôle admin en BDD (réponse login)", adminUser?.role === "admin", `role=${adminUser?.role}`);

    const superRes = await adminLogin("superadmin@studysync.ma");
    auth.check("POST admin/login super_admin → 200", superRes.status === 200);

    const saraRes = await login("sara@univ.ma");
    const saraToken = getToken(saraRes);
    auth.check("POST /api/auth/login (student) → 200", saraRes.status === 200);

    const saraAdmin = await adminLogin("sara@univ.ma");
    auth.check("Student refusé sur admin/login → 403", saraAdmin.status === 403);

    const me = await api("GET", "/api/auth/me", { token: saraToken });
    auth.check("GET /api/auth/me → 200", me.status === 200);

    totalFailed += auth.failed;
    auth.summary();

    const users = new TestRunner("Users");
    console.log("\n══ Users ══");

    const meUser = await api("GET", "/api/users/me", { token: saraToken });
    users.check("GET /api/users/me → 200", meUser.status === 200);

    const profile = await api("GET", `/api/users/${IDS.sara}`, { token: saraToken });
    users.check("GET /api/users/:id → 200", profile.status === 200);

    const blocked = await api("GET", "/api/users/blocked", { token: saraToken });
    users.check("GET /api/users/blocked → 200", blocked.status === 200);

    totalFailed += users.failed;
    users.summary();

    const sessions = new TestRunner("Sessions");
    console.log("\n══ Sessions ══");

    const list = await api("GET", "/api/sessions", { token: saraToken });
    sessions.check("GET /api/sessions → 200", list.status === 200);

    const mine = await api("GET", "/api/sessions/mine", { token: saraToken });
    sessions.check("GET /api/sessions/mine → 200", mine.status === 200);

    const detail = await api("GET", `/api/sessions/${IDS.sessionActive}`, { token: saraToken });
    sessions.check("GET /api/sessions/:id → 200", detail.status === 200);

    const startTime = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();
    const created = await api("POST", "/api/sessions", {
      token: saraToken,
      body: {
        subject: "Test API",
        topic: "Intégration",
        location_name: "Bibliothèque",
        latitude: CASABLANCA.latitude,
        longitude: CASABLANCA.longitude,
        start_time: startTime,
        duration_minutes: 90,
        max_participants: 4,
      },
    });
    sessions.check("POST /api/sessions → 201", created.status === 201);

    const modForJoin = getToken(await login("moderator@studysync.ma"));
    const join = await api("POST", `/api/sessions/${IDS.sessionUpcoming}/join`, {
      token: modForJoin,
      body: { message: "Je souhaite rejoindre" },
    });
    sessions.check(
      "POST /api/sessions/:id/join → 201 ou 409",
      join.status === 201 || join.status === 409,
      `status=${join.status}`,
    );

    totalFailed += sessions.failed;
    sessions.summary();

    const matchQ = `latitude=${CASABLANCA.latitude}&longitude=${CASABLANCA.longitude}`;
    const matches = new TestRunner("Matching");
    console.log("\n══ Matching ══");

    const recommend = await api("GET", `/api/matches/recommend?${matchQ}&radius=10`, {
      token: saraToken,
    });
    matches.check("GET /api/matches/recommend → 200", recommend.status === 200);

    const score = await api(
      "GET",
      `/api/matches/score/${IDS.sessionUpcoming}?${matchQ}`,
      { token: saraToken },
    );
    matches.check("GET /api/matches/score/:id → 200", score.status === 200);

    const checkin = await api("POST", "/api/matches/checkin-verify", {
      token: saraToken,
      body: {
        sessionLat: CASABLANCA.latitude,
        sessionLng: CASABLANCA.longitude,
        userLat: CASABLANCA.latitude,
        userLng: CASABLANCA.longitude,
      },
    });
    matches.check("POST /api/matches/checkin-verify → 200", checkin.status === 200);

    const heatmap = await api("GET", `/api/matches/heatmap?${matchQ}`, { token: saraToken });
    matches.check("GET /api/matches/heatmap → 200", heatmap.status === 200);

    const rings = await api("GET", `/api/matches/distance-rings?${matchQ}`, { token: saraToken });
    matches.check("GET /api/matches/distance-rings → 200", rings.status === 200);

    const nearby = await api("GET", `/api/matches/nearby-sessions?${matchQ}`, { token: saraToken });
    matches.check("GET /api/matches/nearby-sessions → 200", nearby.status === 200);

    totalFailed += matches.failed;
    matches.summary();

    const loc = new TestRunner("Locations");
    console.log("\n══ Locations ══");

    const saveLoc = await api("POST", "/api/locations/saved", {
      token: saraToken,
      body: { name: "Spot test", latitude: CASABLANCA.latitude, longitude: CASABLANCA.longitude },
    });
    loc.check("POST /api/locations/saved → 201", saveLoc.status === 201);

    const listLoc = await api("GET", "/api/locations/saved", { token: saraToken });
    loc.check("GET /api/locations/saved → 200", listLoc.status === 200);

    const savedId = listLoc.data?.locations?.[0]?.id;
    if (savedId) {
      const delLoc = await api("DELETE", `/api/locations/saved/${savedId}`, {
        token: saraToken,
      });
      loc.check("DELETE /api/locations/saved/:id → 200", delLoc.status === 200);
    }

    totalFailed += loc.failed;
    loc.summary();

    const ratings = new TestRunner("Ratings");
    console.log("\n══ Ratings ══");

    const userRatings = await api("GET", `/api/ratings/user/${IDS.jean}`);
    ratings.check("GET /api/ratings/user/:id → 200", userRatings.status === 200);

    const newRating = await api("POST", "/api/ratings", {
      token: saraToken,
      body: {
        session_id: IDS.sessionCompleted,
        rated_id: IDS.jean,
        score: 4,
      },
    });
    ratings.check(
      "POST /api/ratings → 201 ou 409 (déjà noté)",
      newRating.status === 201 || newRating.status === 409,
      `status=${newRating.status}`,
    );

    totalFailed += ratings.failed;
    ratings.summary();

    const reports = new TestRunner("Reports");
    console.log("\n══ Reports ══");

    const modRes = await login("moderator@studysync.ma");
    const modToken = getToken(modRes);

    const listReports = await api("GET", "/api/reports", { token: modToken });
    reports.check("GET /api/reports (modérateur) → 200", listReports.status === 200);

    const createReport = await api("POST", "/api/reports", {
      token: saraToken,
      body: {
        reported_user_id: IDS.jean,
        reason: "other",
        description: "Test intégration signalement",
      },
    });
    reports.check("POST /api/reports → 201", createReport.status === 201);

    const newReportId = createReport.data?.report?.id;
    const resolve = await api("PATCH", `/api/reports/${newReportId}/resolve`, {
      token: modToken,
      body: { status: "dismissed", reason: "Test auto intégration" },
    });
    reports.check("PATCH /api/reports/:id/resolve → 200", resolve.status === 200);

    totalFailed += reports.failed;
    reports.summary();

    const admin = new TestRunner("Admin");
    console.log("\n══ Admin ══");

    const forbidden = await api("GET", "/api/admin/users", { token: saraToken });
    admin.check("GET /api/admin/users (student) → 403", forbidden.status === 403);

    const listUsers = await api("GET", "/api/admin/users?page=1&limit=10", {
      token: adminToken,
    });
    admin.check("GET /api/admin/users → 200", listUsers.status === 200);

    const userDetail = await api("GET", `/api/admin/users/${IDS.sara}`, { token: adminToken });
    admin.check("GET /api/admin/users/:id → 200", userDetail.status === 200);

    totalFailed += admin.failed;
    admin.summary();
  });

  console.log("\n════════════════════════════════");
  if (totalFailed === 0) {
    console.log("✅ Tous les tests API passent");
    console.log("   Pour les actions admin destructives : npm run test:admin");
  } else {
    console.log(`❌ ${totalFailed} échec(s) — relancez : npm run db:seed:test`);
  }
  console.log("════════════════════════════════\n");

  process.exit(totalFailed > 0 ? 1 : 0);
};

run().catch((err) => {
  console.error("Erreur test:", err.message);
  process.exit(1);
});
