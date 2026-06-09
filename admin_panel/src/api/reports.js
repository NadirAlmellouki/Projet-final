import client from "./client";

export async function listReports(status) {
  const params = status ? { status } : {};
  const { data } = await client.get("/reports", { params });
  return data;
}

export async function resolveReport(id, { status, reason }) {
  const { data } = await client.patch(`/reports/${id}/resolve`, { status, reason });
  return data;
}
