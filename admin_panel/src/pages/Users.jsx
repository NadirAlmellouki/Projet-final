import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Users as UsersIcon } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import Card from "../components/ui/Card";
import FilterTabs from "../components/ui/FilterTabs";
import UserCell from "../components/ui/UserCell";
import RoleBadge from "../components/ui/RoleBadge";
import StatusBadge from "../components/ui/StatusBadge";
import Button from "../components/ui/Button";
import Pagination from "../components/ui/Pagination";
import EmptyState from "../components/ui/EmptyState";
import SuspendModal from "../components/modals/SuspendModal";
import BanModal from "../components/modals/BanModal";
import ConfirmModal from "../components/modals/ConfirmModal";
import { listUsers, suspendUser, unsuspendUser, banUser } from "../api/admin";
import { useDebounce } from "../hooks/useDebounce";
import { useToast } from "../context/ToastContext";
import { trustTier } from "../utils/format";

const FILTERS = [
  { value: "all", label: "Tous" }, { value: "active", label: "Actifs" },
  { value: "suspended", label: "Suspendus" }, { value: "banned", label: "Bannis" },
  { value: "moderator", label: "Modérateurs" },
];

export default function Users() {
  const navigate = useNavigate();
  const toast = useToast();
  const [users, setUsers] = useState([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [suspendTarget, setSuspendTarget] = useState(null);
  const [banTarget, setBanTarget] = useState(null);
  const [unsuspendTarget, setUnsuspendTarget] = useState(null);
  const debouncedSearch = useDebounce(search);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 15, q: debouncedSearch };
      if (filter === "moderator") params.role = "moderator";
      const data = await listUsers(params);
      let filtered = data.users || [];
      if (filter === "active") filtered = filtered.filter((u) => !u.is_suspended && !u.is_banned);
      else if (filter === "suspended") filtered = filtered.filter((u) => u.is_suspended && !u.is_banned);
      else if (filter === "banned") filtered = filtered.filter((u) => u.is_banned);
      setUsers(filtered);
      setTotalPages(data.total_pages || 1);
      setTotal(data.total || 0);
    } catch (err) { toast.error(err.message); }
    finally { setLoading(false); }
  }, [page, debouncedSearch, filter, toast]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);
  useEffect(() => { setPage(1); }, [debouncedSearch, filter]);

  return (
    <div className="animate-in">
      <PageHeader eyebrow="Gestion" title="Utilisateurs" description="Recherchez et modérez les comptes." />
      <div style={{ display: "flex", flexDirection: "column", gap: 16, marginBottom: 20 }}>
        <FilterTabs options={FILTERS} value={filter} onChange={setFilter} />
        <input type="search" className="input input--search" placeholder="Rechercher…" value={search} onChange={(e) => setSearch(e.target.value)} style={{ maxWidth: 400 }} />
      </div>
      <Card flush>
        {loading ? <div style={{ padding: 24 }}>{[1,2,3].map((i) => <div key={i} className="skeleton skeleton--text" style={{ height: 48, marginBottom: 12 }} />)}</div>
        : users.length === 0 ? <EmptyState icon={UsersIcon} title="Aucun utilisateur" />
        : (<><table className="data-table"><thead><tr><th>Utilisateur</th><th>Rôle</th><th>Confiance</th><th>Statut</th><th>Actions</th></tr></thead>
          <tbody>{users.map((user) => (
            <tr key={user.id} className="clickable" onClick={() => navigate(`/users/${user.id}`)}>
              <td><UserCell user={user} /></td>
              <td><RoleBadge role={user.role} /></td>
              <td>{Number(user.trust_score || 0).toFixed(1)} <span style={{ fontSize: 12, color: "var(--neutral-400)" }}>{trustTier(user.trust_score).label}</span></td>
              <td><StatusBadge user={user} /></td>
              <td onClick={(e) => e.stopPropagation()}><div className="data-table__actions">
                {!user.is_banned && !user.is_suspended && <><Button size="sm" variant="warning" onClick={() => setSuspendTarget(user)}>Suspendre</Button><Button size="sm" variant="danger" onClick={() => setBanTarget(user)}>Bannir</Button></>}
                {user.is_suspended && !user.is_banned && <><Button size="sm" variant="primary" onClick={() => setUnsuspendTarget(user)}>Réactiver</Button><Button size="sm" variant="danger" onClick={() => setBanTarget(user)}>Bannir</Button></>}
              </div></td>
            </tr>
          ))}</tbody></table><Pagination page={page} totalPages={totalPages} total={total} onPageChange={setPage} /></>)}
      </Card>
      <SuspendModal open={Boolean(suspendTarget)} onClose={() => setSuspendTarget(null)} userName={suspendTarget ? `${suspendTarget.first_name} ${suspendTarget.last_name}` : ""} loading={actionLoading}
        onConfirm={async (p) => { setActionLoading(true); try { await suspendUser(suspendTarget.id, p); toast.success("Suspendu"); setSuspendTarget(null); fetchUsers(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <BanModal open={Boolean(banTarget)} onClose={() => setBanTarget(null)} userName={banTarget ? `${banTarget.first_name} ${banTarget.last_name}` : ""} loading={actionLoading}
        onConfirm={async (r) => { setActionLoading(true); try { await banUser(banTarget.id, r); toast.success("Banni"); setBanTarget(null); fetchUsers(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <ConfirmModal open={Boolean(unsuspendTarget)} onClose={() => setUnsuspendTarget(null)} title="Réactiver" description={`Réactiver ${unsuspendTarget?.first_name} ?`} confirmLabel="Réactiver" loading={actionLoading}
        onConfirm={async () => { setActionLoading(true); try { await unsuspendUser(unsuspendTarget.id, "Réactivation admin"); toast.success("Réactivé"); setUnsuspendTarget(null); fetchUsers(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
    </div>
  );
}
