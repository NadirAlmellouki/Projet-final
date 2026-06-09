import client from "./client";

export async function getHealthStats() {
  const { data } = await client.get("/health");
  return data.database;
}
