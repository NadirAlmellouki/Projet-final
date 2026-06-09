import { useEffect, useState } from "react";
import { Shield, Info } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import Card from "../components/ui/Card";
import UserCell from "../components/ui/UserCell";
import RoleBadge from "../components/ui/RoleBadge";
import EmptyState from "../components/ui/EmptyState";
import { listUsers } from "../api/admin";
import { formatDateTime } from "../utils/format";

export default function Moderators() {
  const [moderators, setModerators] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    listUsers({ role: "moderator", limit: 100 }).then((d) => setModerators(d.users || [])).finally(() => setLoading(false));
  }, []);
  return (
    <div className="animate-in">
      <PageHeader eyebrow="Rôles" title="Modérateurs" description="Équipe de modération." />
      <div className="alert-banner alert-banner--info" style={{ marginBottom: 24 }}>
        <Info size={18} style={{ flexShrink: 0 }} />
        <div>Promotion/rétrogradation non disponibles (endpoints backend manquants). Liste en lecture seule.</div>
      </div>
      <Card flush>
        {loading ? <div style={{ padding: 24 }}><div className="skeleton skeleton--text" style={{ height: 48 }} /></div>
        : moderators.length === 0 ? <EmptyState icon={Shield} title="Aucun modérateur" />
        : <table className="data-table"><thead><tr><th>Modérateur</th><th>Rôle</th><th>Confiance</th><th>Depuis</th></tr></thead>
          <tbody>{moderators.map((m) => (
            <tr key={m.id}><td><UserCell user={m} /></td><td><RoleBadge role={m.role} /></td>
              <td>{Number(m.trust_score || 0).toFixed(1)}</td><td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatDateTime(m.created_at)}</td></tr>
          ))}</tbody></table>}
      </Card>
    </div>
  );
}
