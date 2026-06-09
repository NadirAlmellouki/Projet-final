import "./ui.css";
export default function LoadingScreen({ message = "Chargement…" }) {
  return (
    <div className="loading-screen">
      <div className="loading-screen__spinner" />
      <p style={{ color: "var(--neutral-500)", fontSize: 13 }}>{message}</p>
    </div>
  );
}
