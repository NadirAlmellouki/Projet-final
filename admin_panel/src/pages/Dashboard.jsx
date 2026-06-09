import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Users, Calendar, Flag, ShieldAlert, ArrowRight } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import StatCard from "../components/ui/StatCard";
import Card from "../components/ui/Card";
import Badge from "../components/ui/Badge";
import UserCell from "../components/ui/UserCell";
import EmptyState from "../components/ui/EmptyState";
import Button from "../components/ui/Button";
import { getHealthStats } from "../api/health";
import { listReports } from "../api/reports";
import { listUsers } from "../api/admin";
import { formatDateTime, formatRelative } from "../utils/format";
import { REPORT_REASONS } from "../utils/constants";
import "../components/layout/layout.css";

export default function Dashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [reports, setReports] = useState([]);
  const [recentUsers, setRecentUsers] = useState([]);
  const [suspendedCount, setSuspendedCount] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      getHealthStats(),
      listReports("pending"),
      listUsers({ page: 1, limit: 5 }),
      listUsers({ page: 1, limit: 100 }),
    ]).then(([health, reportsData, usersData, allUsers]) => {
      setStats(health);
      setReports((reportsData.reports || []).slice(0, 5));
      setRecentUsers(usersData.users || []);
      setSuspendedCount((allUsers.users || []).filter((u) => u.is_suspended && !u.is_banned).length);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="grid-stats">{[1,2,3,4].map((i) => <div key={i} className="skeleton skeleton--card" />)}</div>;

  return (
    <div className="animate-in">
      <PageHeader eyebrow="Vue d'ensemble" title="Tableau de bord"
        description="Surveillez l'activité de la plateforme."
        action={<Link to="/reports"><Button variant="primary">File des signalements <ArrowRight size={16} /></Button></Link>} />
      <div className="grid-stats">
        <StatCard icon={Users} label="Utilisateurs" value={stats?.users ?? 0} iconBg="var(--primary-50)" iconColor="var(--primary-600)" />
        <StatCard icon={Calendar} label="Sessions" value={stats?.study_sessions ?? 0} iconBg="#e6fffa" iconColor="var(--secondary-500)" />
        <StatCard icon={Flag} label="Signalements en attente" value={reports.length} trend={`${stats?.reports ?? 0} au total`} iconBg="var(--warning-50)" iconColor="var(--warning-600)" />
        <StatCard icon={ShieldAlert} label="Suspensions actives" value={suspendedCount} iconBg="var(--error-50)" iconColor="var(--error-500)" />
      </div>
      <div className="grid-2">
        <Card title="Signalements récents" flush action={<Link to="/reports"><Button variant="ghost" size="sm">Voir tout</Button></Link>}>
          {reports.length === 0 ? <EmptyState icon={Flag} title="Aucun signalement en attente" /> : (
            <table className="data-table"><thead><tr><th>Signalé par</th><th>Type</th><th>Date</th></tr></thead>
              <tbody>{reports.map((r) => (
                <tr key={r.id} className="clickable" onClick={() => navigate("/reports")}>
                  <td><UserCell user={r.reporter} showEmail={false} /></td>
                  <td><Badge variant="pending">{REPORT_REASONS[r.reason] || r.reason}</Badge></td>
                  <td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatRelative(r.created_at)}</td>
                </tr>
              ))}</tbody></table>
          )}
        </Card>
        <Card title="Inscriptions récentes" flush action={<Link to="/users"><Button variant="ghost" size="sm">Voir tout</Button></Link>}>
          {recentUsers.length === 0 ? <EmptyState icon={Users} title="Aucun utilisateur" /> : (
            <table className="data-table"><thead><tr><th>Utilisateur</th><th>Rôle</th><th>Date</th></tr></thead>
              <tbody>{recentUsers.map((u) => (
                <tr key={u.id} className="clickable" onClick={() => navigate(`/users/${u.id}`)}>
                  <td><UserCell user={u} /></td>
                  <td><Badge variant={u.role}>{u.role}</Badge></td>
                  <td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatDateTime(u.created_at)}</td>
                </tr>
              ))}</tbody></table>
          )}
        </Card>
      </div>
    </div>
  );
}
