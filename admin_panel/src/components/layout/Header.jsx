import { Menu } from "lucide-react";
import "./layout.css";
export default function Header({ title, onMenuClick }) {
  return (
    <header className="admin-header">
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <button type="button" className="mobile-menu-btn" onClick={onMenuClick}><Menu size={22} /></button>
        <div className="admin-header__breadcrumb">StudySync / <strong>{title}</strong></div>
      </div>
    </header>
  );
}
