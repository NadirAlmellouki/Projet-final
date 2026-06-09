import "./ui.css";
export default function EmptyState({ icon: Icon, title, description }) {
  return (
    <div className="empty-state">
      {Icon && <div className="empty-state__icon"><Icon size={24} /></div>}
      <h3 className="empty-state__title">{title}</h3>
      {description && <p className="empty-state__desc">{description}</p>}
    </div>
  );
}
