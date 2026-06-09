import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import * as authApi from "../api/auth";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const stored = localStorage.getItem("studysync_admin_user");
      return stored ? JSON.parse(stored) : null;
    } catch { return null; }
  });
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    localStorage.removeItem("studysync_admin_token");
    localStorage.removeItem("studysync_admin_user");
    setUser(null);
  }, []);

  const login = useCallback(async (email, password) => {
    const result = await authApi.adminLogin(email, password);
    localStorage.setItem("studysync_admin_token", result.token);
    localStorage.setItem("studysync_admin_user", JSON.stringify(result.user));
    setUser(result.user);
    return result.user;
  }, []);

  useEffect(() => {
    const token = localStorage.getItem("studysync_admin_token");
    if (!token) { setLoading(false); return; }
    authApi.getMe()
      .then((profile) => {
        if (!["admin", "super_admin"].includes(profile.role)) { logout(); return; }
        setUser(profile);
        localStorage.setItem("studysync_admin_user", JSON.stringify(profile));
      })
      .catch(() => logout())
      .finally(() => setLoading(false));
  }, [logout]);

  const value = useMemo(() => ({
    user, loading, isAuthenticated: Boolean(user),
    isSuperAdmin: user?.role === "super_admin", login, logout,
  }), [user, loading, login, logout]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
