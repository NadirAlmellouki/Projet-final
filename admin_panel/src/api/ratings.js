import client from "./client";

export async function getUserRatings(userId) {
  const { data } = await client.get(`/ratings/user/${userId}`);
  return data;
}
