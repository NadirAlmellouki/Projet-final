import { NavLink } from "react-router-dom";
import { LayoutDashboard, Users, Flag, Calendar, Shield, LogOut } from "lucide-react";
import { useAuth } from "../../context/AuthContext";
import { getFullName } from "../../utils/format";
import Avatar from "../ui/Avatar";
import "./layout.css";

const NAV = [
  { to: "/", icon: LayoutDashboard, label: "Tableau de bord", end: true },
  { to: "/users", icon: Users, label: "Utilisateurs" },
  { to: "/reports", icon: Flag, label: "Signalements" },
  { to: "/sessions", icon: Calendar, label: "Sessions" },
  { to: "/moderators", icon: Shield, label: "Modérateurs" },
];

export default function Sidebar({ open, onClose }) {
  const { user, logout } = useAuth();
  return (
    <>
      {open && <div className="sidebar-overlay" onClick={onClose} />}
      <aside className={`sidebar ${open ? "sidebar--open" : ""}`}>
        <div className="sidebar__brand">
          <div className="sidebar__logo">
            <div className="sidebar__logo-mark">SS</div>
            <div><div className="sidebar__logo-text">StudySync</div><div className="sidebar__logo-sub">Administration</div></div>
          </div>
        </div>
        <nav className="sidebar__nav">
          <div className="sidebar__section">Menu</div>
          {NAV.map(({ to, icon: Icon, label, end }) => (
            <NavLink key={to} to={to} end={end} onClick={onClose} className={({ isActive }) => `sidebar__link ${isActive ? "sidebar__link--active" : ""}`}>
              <Icon size={18} />{label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar__footer">
          <div className="sidebar__user">
            <Avatar user={user} />
            <div className="sidebar__user-info">
              <div className="sidebar__user-name">{getFullName(user)}</div>
              <div className="sidebar__user-role">{user?.role?.replace("_", " ")}</div>
            </div>
            <button type="button" className="btn btn--ghost btn--icon" onClick={logout} title="Déconnexion" style={{ color: "rgba(255,255,255,0.5)" }}>
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
