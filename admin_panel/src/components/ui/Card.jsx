import "./ui.css";
export default function Card({ title, subtitle, action, children, flush = false, className = "" }) {
  return (
    <div className={`card ${className}`.trim()}>
      {(title || action) && (
        <div className="card__header">
          <div>{title && <h3 className="card__title">{title}</h3>}{subtitle && <p className="card__subtitle">{subtitle}</p>}</div>
          {action}
        </div>
      )}
      <div className={flush ? "card__body card__body--flush" : "card__body"}>{children}</div>
    </div>
  );
}
