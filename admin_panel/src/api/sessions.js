import client from "./client";

const STATUSES = ["created", "active", "completed", "cancelled"];

export async function listAllSessions({ subject = "", limit = 50 } = {}) {
  const requests = STATUSES.map((status) =>
    client.get("/sessions", { params: { status, limit, subject } })
  );
  const results = await Promise.all(requests);
  const sessions = results.flatMap((r) => r.data.sessions || []);
  const unique = new Map();
  sessions.forEach((s) => unique.set(s.id, s));
  return Array.from(unique.values()).sort(
    (a, b) => new Date(b.start_time) - new Date(a.start_time)
  );
}

export async function getSession(id) {
  const { data } = await client.get(`/sessions/${id}`);
  return data;
}

export async function getSessionMessages(id) {
  const { data } = await client.get(`/sessions/${id}/messages`);
  return data;
}
