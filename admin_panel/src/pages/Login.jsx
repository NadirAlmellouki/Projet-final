import { useState } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import Button from "../components/ui/Button";
import LoadingScreen from "../components/ui/LoadingScreen";
import "../components/layout/layout.css";
import "../components/ui/ui.css";

export default function Login() {
  const { login, isAuthenticated, loading: authLoading } = useAuth();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  if (authLoading) return <LoadingScreen />;
  if (isAuthenticated) return <Navigate to={location.state?.from?.pathname || "/"} replace />;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try { await login(email, password); }
    catch (err) { setError(err.message || "Identifiants invalides"); }
    finally { setLoading(false); }
  };

  return (
    <div className="login-page">
      <div className="login-page__hero">
        <h1 className="login-page__hero-title">Modération intelligente pour une communauté d'étude saine</h1>
        <p className="login-page__hero-desc">Gérez utilisateurs, signalements et sessions StudySync.</p>
      </div>
      <div className="login-page__form">
        <form className="login-form animate-in" onSubmit={handleSubmit}>
          <h2 className="login-form__title">Connexion admin</h2>
          <p className="login-form__subtitle">Accès réservé aux administrateurs.</p>
          {error && <div className="login-form__error">{error}</div>}
          <div className="field" style={{ marginBottom: 16 }}>
            <label className="field__label">Email</label>
            <input type="email" className="input" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </div>
          <div className="field" style={{ marginBottom: 24 }}>
            <label className="field__label">Mot de passe</label>
            <input type="password" className="input" value={password} onChange={(e) => setPassword(e.target.value)} required />
          </div>
          <Button type="submit" size="lg" loading={loading} style={{ width: "100%" }}>Se connecter</Button>
        </form>
      </div>
    </div>
  );
}
