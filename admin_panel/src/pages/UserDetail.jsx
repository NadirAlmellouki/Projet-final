import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Star } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import Card from "../components/ui/Card";
import Avatar from "../components/ui/Avatar";
import RoleBadge from "../components/ui/RoleBadge";
import StatusBadge from "../components/ui/StatusBadge";
import Button from "../components/ui/Button";
import Badge from "../components/ui/Badge";
import SuspendModal from "../components/modals/SuspendModal";
import BanModal from "../components/modals/BanModal";
import ConfirmModal from "../components/modals/ConfirmModal";
import { getUserDetail, suspendUser, unsuspendUser, banUser } from "../api/admin";
import { getUserRatings } from "../api/ratings";
import { listReports } from "../api/reports";
import { useToast } from "../context/ToastContext";
import { formatDateTime, getFullName, trustTier } from "../utils/format";
import { REPORT_REASONS } from "../utils/constants";
import "../components/layout/layout.css";

export default function UserDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const [user, setUser] = useState(null);
  const [ratings, setRatings] = useState(null);
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [suspendOpen, setSuspendOpen] = useState(false);
  const [banOpen, setBanOpen] = useState(false);
  const [unsuspendOpen, setUnsuspendOpen] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const [userData, ratingsData, reportsData] = await Promise.all([
        getUserDetail(id), getUserRatings(id).catch(() => null), listReports(),
      ]);
      setUser(userData);
      setRatings(ratingsData);
      setReports((reportsData.reports || []).filter((r) => r.reported_user_id === id || r.reporter_id === id));
    } catch (err) { toast.error(err.message); navigate("/users"); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [id]);

  if (loading) return <><div className="skeleton skeleton--title" /><div className="skeleton skeleton--card" style={{ height: 200 }} /></>;
  if (!user) return null;

  return (
    <div className="animate-in">
      <Button variant="ghost" size="sm" onClick={() => navigate("/users")} style={{ marginBottom: 16 }}><ArrowLeft size={16} /> Retour</Button>
      <PageHeader title={getFullName(user)} description={user.email} action={
        <div style={{ display: "flex", gap: 8 }}>
          {!user.is_banned && !user.is_suspended && <><Button variant="warning" onClick={() => setSuspendOpen(true)}>Suspendre</Button><Button variant="danger" onClick={() => setBanOpen(true)}>Bannir</Button></>}
          {user.is_suspended && !user.is_banned && <><Button variant="primary" onClick={() => setUnsuspendOpen(true)}>Réactiver</Button><Button variant="danger" onClick={() => setBanOpen(true)}>Bannir</Button></>}
        </div>
      } />
      <div className="grid-2" style={{ marginBottom: 24 }}>
        <Card title="Profil">
          <div style={{ display: "flex", gap: 20 }}><Avatar user={user} size="lg" />
            <div><div style={{ display: "flex", gap: 8, marginBottom: 12 }}><RoleBadge role={user.role} /><StatusBadge user={user} /></div>
              <dl style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: 8, fontSize: 13 }}>
                <dt style={{ color: "var(--neutral-500)" }}>Université</dt><dd>{user.university || "—"}</dd>
                <dt style={{ color: "var(--neutral-500)" }}>Filière</dt><dd>{user.major || "—"}</dd>
                <dt style={{ color: "var(--neutral-500)" }}>Inscrit le</dt><dd>{formatDateTime(user.created_at)}</dd>
              </dl></div></div>
        </Card>
        <Card title="Confiance">
          <div style={{ textAlign: "center", padding: 12 }}>
            <div style={{ fontFamily: "var(--font-display)", fontSize: 48 }}>{Number(user.trust_score || 0).toFixed(1)}</div>
            <Badge variant="primary">{trustTier(user.trust_score).label}</Badge>
            {ratings && <p style={{ marginTop: 12, fontSize: 13, color: "var(--neutral-500)" }}><Star size={14} style={{ display: "inline" }} /> {ratings.ratings_count} évaluations</p>}
          </div>
        </Card>
      </div>
      <Card title="Signalements associés" flush>
        {reports.length === 0 ? <p style={{ padding: 24, color: "var(--neutral-500)" }}>Aucun signalement.</p> : (
          <table className="data-table"><thead><tr><th>Type</th><th>Statut</th><th>Description</th><th>Date</th></tr></thead>
            <tbody>{reports.map((r) => (
              <tr key={r.id}><td><Badge variant="pending">{REPORT_REASONS[r.reason]}</Badge></td><td><Badge variant={r.status}>{r.status}</Badge></td>
                <td>{r.description || "—"}</td><td>{formatDateTime(r.created_at)}</td></tr>
            ))}</tbody></table>
        )}
      </Card>
      <SuspendModal open={suspendOpen} onClose={() => setSuspendOpen(false)} userName={getFullName(user)} loading={actionLoading}
        onConfirm={async (p) => { setActionLoading(true); try { await suspendUser(id, p); toast.success("Suspendu"); setSuspendOpen(false); load(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <BanModal open={banOpen} onClose={() => setBanOpen(false)} userName={getFullName(user)} loading={actionLoading}
        onConfirm={async (r) => { setActionLoading(true); try { await banUser(id, r); toast.success("Banni"); setBanOpen(false); load(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <ConfirmModal open={unsuspendOpen} onClose={() => setUnsuspendOpen(false)} title="Réactiver" description={`Réactiver ${getFullName(user)} ?`} confirmLabel="Réactiver" loading={actionLoading}
        onConfirm={async () => { setActionLoading(true); try { await unsuspendUser(id, "Réactivation admin"); toast.success("Réactivé"); setUnsuspendOpen(false); load(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
    </div>
  );
}
