import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Calendar, Zap, CheckCircle, AlertTriangle } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import StatCard from "../components/ui/StatCard";
import Card from "../components/ui/Card";
import FilterTabs from "../components/ui/FilterTabs";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import EmptyState from "../components/ui/EmptyState";
import DeleteReasonModal from "../components/modals/DeleteReasonModal";
import { listAllSessions } from "../api/sessions";
import { deleteSession } from "../api/admin";
import { listReports } from "../api/reports";
import { useDebounce } from "../hooks/useDebounce";
import { useToast } from "../context/ToastContext";
import { formatDateTime } from "../utils/format";
import { SESSION_STATUS } from "../utils/constants";
import "../components/layout/layout.css";

const STATUS_FILTERS = [{ value: "all", label: "Toutes" }, { value: "created", label: "Créées" }, { value: "active", label: "Actives" }, { value: "completed", label: "Terminées" }, { value: "cancelled", label: "Annulées" }];
const STATUS_BADGE = { created: "created", active: "session-active", completed: "completed", cancelled: "cancelled" };

export default function Sessions() {
  const navigate = useNavigate();
  const toast = useToast();
  const [sessions, setSessions] = useState([]);
  const [flaggedIds, setFlaggedIds] = useState(new Set());
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);
  const debouncedSearch = useDebounce(search);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [sessionsData, reportsData] = await Promise.all([listAllSessions({ subject: debouncedSearch }), listReports("pending")]);
      setSessions(sessionsData);
      setFlaggedIds(new Set((reportsData.reports || []).filter((r) => r.reported_session_id).map((r) => r.reported_session_id)));
    } catch (err) { toast.error(err.message); }
    finally { setLoading(false); }
  }, [debouncedSearch, toast]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const filtered = sessions.filter((s) => filter === "all" || s.status === filter);
  const stats = {
    active: sessions.filter((s) => s.status === "active").length,
    completedToday: sessions.filter((s) => s.status === "completed" && new Date(s.start_time).toDateString() === new Date().toDateString()).length,
    flagged: flaggedIds.size,
  };

  return (
    <div className="animate-in">
      <PageHeader eyebrow="Surveillance" title="Sessions" description="Surveillez et modérez les sessions." />
      <div className="grid-stats" style={{ gridTemplateColumns: "repeat(3, 1fr)" }}>
        <StatCard icon={Zap} label="Actives" value={stats.active} iconBg="#e6fffa" iconColor="var(--secondary-500)" />
        <StatCard icon={CheckCircle} label="Terminées aujourd'hui" value={stats.completedToday} iconBg="var(--success-50)" iconColor="var(--success-600)" />
        <StatCard icon={AlertTriangle} label="Signalées" value={stats.flagged} iconBg="var(--error-50)" iconColor="var(--error-500)" />
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16, marginBottom: 20 }}>
        <FilterTabs options={STATUS_FILTERS} value={filter} onChange={setFilter} />
        <input type="search" className="input input--search" placeholder="Filtrer par matière…" value={search} onChange={(e) => setSearch(e.target.value)} style={{ maxWidth: 400 }} />
      </div>
      <Card flush>
        {loading ? <div style={{ padding: 24 }}>{[1,2,3].map((i) => <div key={i} className="skeleton skeleton--text" style={{ height: 48, marginBottom: 12 }} />)}</div>
        : filtered.length === 0 ? <EmptyState icon={Calendar} title="Aucune session" />
        : <table className="data-table"><thead><tr><th>Matière</th><th>Créateur</th><th>Lieu</th><th>Participants</th><th>Statut</th><th>Date</th><th>Actions</th></tr></thead>
          <tbody>{filtered.map((session) => (
            <tr key={session.id} className="clickable" style={flaggedIds.has(session.id) ? { background: "var(--error-50)" } : undefined} onClick={() => navigate(`/sessions/${session.id}`)}>
              <td><div style={{ fontWeight: 600 }}>{session.subject}</div></td>
              <td style={{ fontSize: 13 }}>{session.creator_first_name} {session.creator_last_name}</td>
              <td style={{ fontSize: 13 }}>{session.location_name || "—"}</td>
              <td style={{ fontSize: 13 }}>{session.participant_count ?? 0}/{session.max_participants}</td>
              <td><Badge variant={STATUS_BADGE[session.status]}>{SESSION_STATUS[session.status]}</Badge>{flaggedIds.has(session.id) && <Badge variant="banned" style={{ marginLeft: 6 }}>Signalée</Badge>}</td>
              <td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatDateTime(session.start_time)}</td>
              <td onClick={(e) => e.stopPropagation()}><Button size="sm" variant="danger" onClick={() => setDeleteTarget(session)}>Supprimer</Button></td>
            </tr>
          ))}</tbody></table>}
      </Card>
      <DeleteReasonModal open={Boolean(deleteTarget)} onClose={() => setDeleteTarget(null)} title="Supprimer la session" description={`Supprimer « ${deleteTarget?.subject} » ?`} confirmLabel="Supprimer" loading={actionLoading}
        onConfirm={async (reason) => { setActionLoading(true); try { await deleteSession(deleteTarget.id, reason); toast.success("Supprimée"); setDeleteTarget(null); fetchData(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
    </div>
  );
}
