import "./ui.css";
export default function FilterTabs({ options, value, onChange }) {
  return (
    <div className="filter-tabs">
      {options.map((opt) => (
        <button key={opt.value} type="button" className={`filter-tab ${value === opt.value ? "filter-tab--active" : ""}`} onClick={() => onChange(opt.value)}>
          {opt.label}{opt.count != null ? ` (${opt.count})` : ""}
        </button>
      ))}
    </div>
  );
}
