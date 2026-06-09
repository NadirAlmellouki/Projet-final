import { useCallback, useEffect, useState } from "react";
import { Flag } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import Card from "../components/ui/Card";
import FilterTabs from "../components/ui/FilterTabs";
import Badge from "../components/ui/Badge";
import UserCell from "../components/ui/UserCell";
import Button from "../components/ui/Button";
import EmptyState from "../components/ui/EmptyState";
import ResolveReportModal from "../components/modals/ResolveReportModal";
import SuspendModal from "../components/modals/SuspendModal";
import DeleteReasonModal from "../components/modals/DeleteReasonModal";
import { listReports, resolveReport } from "../api/reports";
import { suspendUser, deleteSession, deleteMessage } from "../api/admin";
import { useToast } from "../context/ToastContext";
import { formatDateTime, truncate } from "../utils/format";
import { REPORT_REASONS } from "../utils/constants";

const FILTERS = [{ value: "all", label: "Tous" }, { value: "pending", label: "En attente" }, { value: "resolved", label: "Résolus" }, { value: "dismissed", label: "Rejetés" }];

export default function Reports() {
  const toast = useToast();
  const [reports, setReports] = useState([]);
  const [filter, setFilter] = useState("pending");
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [resolveTarget, setResolveTarget] = useState(null);
  const [resolveMode, setResolveMode] = useState("resolved");
  const [suspendTarget, setSuspendTarget] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const fetchReports = useCallback(async () => {
    setLoading(true);
    try { const data = await listReports(filter === "all" ? undefined : filter); setReports(data.reports || []); }
    catch (err) { toast.error(err.message); }
    finally { setLoading(false); }
  }, [filter, toast]);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  const getTarget = (r) => {
    if (r.reportedUser) return <UserCell user={r.reportedUser} />;
    if (r.reported_session_id) return <span style={{ fontSize: 13 }}>Session</span>;
    if (r.reported_message_id) return <span style={{ fontSize: 13 }}>Message</span>;
    return "—";
  };

  return (
    <div className="animate-in">
      <PageHeader eyebrow="Modération" title="Signalements" description="Traitez les rapports de la communauté." />
      <div style={{ marginBottom: 20 }}><FilterTabs options={FILTERS} value={filter} onChange={setFilter} /></div>
      <Card flush>
        {loading ? <div style={{ padding: 24 }}>{[1,2,3].map((i) => <div key={i} className="skeleton skeleton--text" style={{ height: 56, marginBottom: 12 }} />)}</div>
        : reports.length === 0 ? <EmptyState icon={Flag} title="Aucun signalement" />
        : <table className="data-table"><thead><tr><th>Signalé par</th><th>Cible</th><th>Type</th><th>Description</th><th>Statut</th><th>Date</th><th>Actions</th></tr></thead>
          <tbody>{reports.map((report) => (
            <tr key={report.id}>
              <td><UserCell user={report.reporter} showEmail={false} /></td>
              <td>{getTarget(report)}</td>
              <td><Badge variant="pending">{REPORT_REASONS[report.reason] || report.reason}</Badge></td>
              <td style={{ fontSize: 13, maxWidth: 200 }}>{truncate(report.description, 60) || "—"}</td>
              <td><Badge variant={report.status}>{report.status}</Badge></td>
              <td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatDateTime(report.created_at)}</td>
              <td>{report.status === "pending" && <div className="data-table__actions">
                {report.reportedUser && <Button size="sm" variant="warning" onClick={() => setSuspendTarget(report)}>Suspendre</Button>}
                {(report.reported_session_id || report.reported_message_id) && <Button size="sm" variant="danger" onClick={() => setDeleteTarget(report)}>Supprimer</Button>}
                <Button size="sm" variant="primary" onClick={() => { setResolveMode("resolved"); setResolveTarget(report); }}>Résoudre</Button>
                <Button size="sm" variant="secondary" onClick={() => { setResolveMode("dismissed"); setResolveTarget(report); }}>Rejeter</Button>
              </div>}</td>
            </tr>
          ))}</tbody></table>}
      </Card>
      <ResolveReportModal open={Boolean(resolveTarget)} onClose={() => setResolveTarget(null)} mode={resolveMode} loading={actionLoading}
        onConfirm={async ({ status, reason }) => { setActionLoading(true); try { await resolveReport(resolveTarget.id, { status, reason }); toast.success("Traité"); setResolveTarget(null); fetchReports(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <SuspendModal open={Boolean(suspendTarget)} onClose={() => setSuspendTarget(null)} userName={suspendTarget?.reportedUser ? `${suspendTarget.reportedUser.first_name} ${suspendTarget.reportedUser.last_name}` : ""} loading={actionLoading}
        onConfirm={async (p) => { setActionLoading(true); try { await suspendUser(suspendTarget.reportedUser.id, p); await resolveReport(suspendTarget.id, { status: "resolved", reason: p.reason }); toast.success("Suspendu et résolu"); setSuspendTarget(null); fetchReports(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <DeleteReasonModal open={Boolean(deleteTarget)} onClose={() => setDeleteTarget(null)} title="Supprimer le contenu" description="Contenu supprimé et rapport résolu." confirmLabel="Supprimer" loading={actionLoading}
        onConfirm={async (reason) => { setActionLoading(true); try {
          if (deleteTarget.reported_session_id) await deleteSession(deleteTarget.reported_session_id, reason);
          else if (deleteTarget.reported_message_id) await deleteMessage(deleteTarget.reported_message_id, reason);
          await resolveReport(deleteTarget.id, { status: "resolved", reason }); toast.success("Supprimé"); setDeleteTarget(null); fetchReports();
        } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
    </div>
  );
}
