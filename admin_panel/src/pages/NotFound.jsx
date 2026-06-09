import { Link } from "react-router-dom";
import Button from "../components/ui/Button";

export default function NotFound() {
  return (
    <div style={{ textAlign: "center", padding: "80px 24px" }}>
      <h1 style={{ fontFamily: "var(--font-display)", fontSize: 64, color: "var(--neutral-300)" }}>404</h1>
      <p style={{ marginBottom: 24, color: "var(--neutral-600)" }}>Page introuvable</p>
      <Link to="/"><Button>Retour au tableau de bord</Button></Link>
    </div>
  );
}
