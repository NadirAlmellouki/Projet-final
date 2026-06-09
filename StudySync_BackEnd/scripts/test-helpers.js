import { spawn } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const root = path.resolve(__dirname, "..");
export const BASE = `http://localhost:${process.env.PORT || 3000}`;

export const IDS = {
  superAdmin: "00000000-0000-0000-0000-000000000001",
  admin: "00000000-0000-0000-0000-000000000002",
  moderator: "00000000-0000-0000-0000-000000000003",
  sara: "00000000-0000-0000-0000-000000000004",
  jean: "00000000-0000-0000-0000-000000000005",
  sessionCompleted: "aaaaaaaa-0000-0000-0000-000000000001",
  sessionActive: "aaaaaaaa-0000-0000-0000-000000000002",
  sessionUpcoming: "aaaaaaaa-0000-0000-0000-000000000003",
  sessionCancelled: "aaaaaaaa-0000-0000-0000-000000000004",
  messageActive: "bbbbbbbb-0000-0000-0000-000000000003",
  reportPending: "cccccccc-0000-0000-0000-000000000001",
};

export const PASSWORD = "Password123";

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export async function isServerUp() {
  try {
    const res = await fetch(`${BASE}/api/health`, {
      signal: AbortSignal.timeout(3000),
    });
    return res.ok;
  } catch {
    return false;
  }
}

export async function withServer(fn) {
  let server = null;
  const alreadyRunning = await isServerUp();

  if (!alreadyRunning) {
    console.log("Démarrage du serveur de test...");
    server = spawn("node", ["src/server.js"], {
      cwd: root,
      stdio: ["ignore", "pipe", "pipe"],
      env: process.env,
    });
    server.stderr.on("data", (d) => process.stderr.write(d));
    for (let i = 0; i < 20; i++) {
      if (await isServerUp()) break;
      await sleep(1000);
    }
    if (!(await isServerUp())) {
      throw new Error("Le serveur n'a pas démarré. Arrêtez npm run dev ou libérez le port 3000.");
    }
  } else {
    console.log("Serveur déjà actif sur le port 3000 — réutilisation.");
  }

  try {
    return await fn({ alreadyRunning });
  } finally {
    if (server) server.kill();
  }
}

export async function api(method, urlPath, { token, body } = {}) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE}${urlPath}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

export function getToken(loginResponse) {
  return loginResponse.data?.data?.token ?? loginResponse.data?.token;
}

export function getUser(loginResponse) {
  return loginResponse.data?.data?.user ?? loginResponse.data?.user;
}

export class TestRunner {
  constructor(title) {
    this.title = title;
    this.passed = 0;
    this.failed = 0;
  }

  check(name, condition, detail = "") {
    if (condition) {
      console.log(`  ✓ ${name}`);
      this.passed += 1;
      return true;
    }
    console.log(`  ✗ ${name}${detail ? ` — ${detail}` : ""}`);
    this.failed += 1;
    return false;
  }

  summary() {
    console.log(`\n[${this.title}] ${this.passed} OK, ${this.failed} échec(s)`);
    return this.failed === 0;
  }
}
