import "./ui.css";
export default function StatCard({ icon: Icon, label, value, trend, iconBg, iconColor }) {
  return (
    <div className="stat-card animate-in">
      <div className="stat-card__icon" style={{ background: iconBg || "var(--primary-50)", color: iconColor || "var(--primary-600)" }}>
        <Icon size={22} />
      </div>
      <div className="stat-card__value">{value ?? "—"}</div>
      <div className="stat-card__label">{label}</div>
      {trend && <div className="stat-card__trend">{trend}</div>}
    </div>
  );
}
