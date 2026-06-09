import "./ui.css";
const VARIANTS = { primary: "btn--primary", secondary: "btn--secondary", ghost: "btn--ghost", danger: "btn--danger", warning: "btn--warning" };
const SIZES = { sm: "btn--sm", md: "", lg: "btn--lg", icon: "btn--icon" };
export default function Button({ children, variant = "primary", size = "md", className = "", loading = false, ...props }) {
  return (
    <button className={`btn ${VARIANTS[variant] || ""} ${SIZES[size] || ""} ${className}`.trim()} disabled={loading || props.disabled} {...props}>
      {loading && <span style={{ width: 14, height: 14, border: "2px solid currentColor", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.7s linear infinite" }} />}
      {children}
    </button>
  );
}
