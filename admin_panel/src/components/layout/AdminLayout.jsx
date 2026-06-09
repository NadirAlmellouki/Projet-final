import { useState } from "react";
import { Outlet, useLocation } from "react-router-dom";
import Sidebar from "./Sidebar";
import Header from "./Header";
import "./layout.css";

const TITLES = { "/": "Tableau de bord", "/users": "Utilisateurs", "/reports": "Signalements", "/sessions": "Sessions", "/moderators": "Modérateurs" };

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  const base = location.pathname.startsWith("/users/") ? "/users" : location.pathname.startsWith("/sessions/") ? "/sessions" : location.pathname;
  return (
    <div className="admin-layout">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="admin-main">
        <Header title={TITLES[base] || "Admin"} onMenuClick={() => setSidebarOpen(true)} />
        <main className="admin-content"><Outlet /></main>
      </div>
    </div>
  );
}
