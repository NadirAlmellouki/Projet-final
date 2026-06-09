import axios from "axios";

const API_BASE = import.meta.env.VITE_API_URL || "/api";

const client = axios.create({
  baseURL: API_BASE,
  headers: { "Content-Type": "application/json" },
  timeout: 30000,
});

client.interceptors.request.use((config) => {
  const token = localStorage.getItem("studysync_admin_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const message =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message ||
      "Une erreur est survenue";
    if (status === 401 && !error.config?.skipAuthRedirect) {
      localStorage.removeItem("studysync_admin_token");
      localStorage.removeItem("studysync_admin_user");
      if (!window.location.pathname.includes("/login")) {
        window.location.href = "/login";
      }
    }
    return Promise.reject({ status, message, original: error });
  }
);

export default client;
