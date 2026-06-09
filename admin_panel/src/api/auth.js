import client from "./client";

export async function adminLogin(email, password) {
  const { data } = await client.post("/auth/admin/login", { email, password });
  return data.data;
}

export async function getMe() {
  const { data } = await client.get("/auth/me");
  return data.data.user;
}
