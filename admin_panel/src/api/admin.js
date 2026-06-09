import client from "./client";

export async function listUsers({ page = 1, limit = 15, q = "", role = "" } = {}) {
  const params = { page, limit };
  if (q) params.q = q;
  if (role) params.role = role;
  const { data } = await client.get("/admin/users", { params });
  return data;
}

export async function getUserDetail(id) {
  const { data } = await client.get(`/admin/users/${id}`);
  return data.user;
}

export async function suspendUser(id, { suspended_until, reason }) {
  const { data } = await client.patch(`/admin/users/${id}/suspend`, { suspended_until, reason });
  return data;
}

export async function unsuspendUser(id, reason) {
  const { data } = await client.patch(`/admin/users/${id}/unsuspend`, { reason });
  return data;
}

export async function banUser(id, reason) {
  const { data } = await client.patch(`/admin/users/${id}/ban`, { reason });
  return data;
}

export async function deleteSession(id, reason) {
  const { data } = await client.delete(`/admin/sessions/${id}`, { data: { reason } });
  return data;
}

export async function deleteMessage(id, reason) {
  const { data } = await client.patch(`/admin/messages/${id}/delete`, { reason });
  return data;
}
