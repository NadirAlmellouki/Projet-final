import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import PageHeader from "../components/ui/PageHeader";
import Card from "../components/ui/Card";
import Badge from "../components/ui/Badge";
import Button from "../components/ui/Button";
import DeleteReasonModal from "../components/modals/DeleteReasonModal";
import { getSession, getSessionMessages } from "../api/sessions";
import { deleteSession, deleteMessage } from "../api/admin";
import { useToast } from "../context/ToastContext";
import { formatDateTime } from "../utils/format";
import { SESSION_STATUS } from "../utils/constants";
import "../components/layout/layout.css";

export default function SessionDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const [session, setSession] = useState(null);
  const [participants, setParticipants] = useState([]);
  const [messages, setMessages] = useState([]);
  const [messagesError, setMessagesError] = useState(null);
  const [loading, setLoading] = useState(true);
  const [deleteSessionOpen, setDeleteSessionOpen] = useState(false);
  const [deleteMessageTarget, setDeleteMessageTarget] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const sessionData = await getSession(id);
      setSession(sessionData.session);
      setParticipants(sessionData.participants || []);
      try {
        const messagesData = await getSessionMessages(id);
        setMessages(messagesData.messages || []);
        setMessagesError(null);
      } catch (err) {
        setMessages([]);
        setMessagesError(err.message || "Impossible de charger les messages");
      }
    } catch (err) { toast.error(err.message); navigate("/sessions"); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [id]);

  if (loading) return <><div className="skeleton skeleton--title" /><div className="skeleton skeleton--card" style={{ height: 240 }} /></>;
  if (!session) return null;

  return (
    <div className="animate-in">
      <Button variant="ghost" size="sm" onClick={() => navigate("/sessions")} style={{ marginBottom: 16 }}><ArrowLeft size={16} /> Retour</Button>
      <PageHeader title={session.subject} description={session.location_name || "Session d'étude"}
        action={<Button variant="danger" onClick={() => setDeleteSessionOpen(true)}>Supprimer la session</Button>} />
      <div className="grid-2" style={{ marginBottom: 24 }}>
        <Card title="Informations">
          <dl style={{ display: "grid", gridTemplateColumns: "140px 1fr", gap: 10, fontSize: 13 }}>
            <dt style={{ color: "var(--neutral-500)" }}>Statut</dt><dd><Badge variant={session.status}>{SESSION_STATUS[session.status]}</Badge></dd>
            <dt style={{ color: "var(--neutral-500)" }}>Début</dt><dd>{formatDateTime(session.start_time)}</dd>
            <dt style={{ color: "var(--neutral-500)" }}>Durée</dt><dd>{session.duration_minutes} min</dd>
            <dt style={{ color: "var(--neutral-500)" }}>Lieu</dt><dd>{session.location_name || "—"}</dd>
          </dl>
        </Card>
        <Card title={`Participants (${participants.length})`}>
          {participants.length === 0 ? <p style={{ fontSize: 13, color: "var(--neutral-500)" }}>Aucun participant.</p> : (
            <ul style={{ listStyle: "none", display: "flex", flexDirection: "column", gap: 8 }}>
              {participants.map((p) => (
                <li key={p.id} style={{ fontSize: 13, display: "flex", justifyContent: "space-between" }}>
                  <span>{p.user?.first_name} {p.user?.last_name}</span><Badge variant="neutral">{p.status}</Badge>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
      <Card title="Messages" subtitle={`${messages.length} message(s)`} flush>
        {messagesError ? <p style={{ padding: 24, color: "var(--error-600)" }}>{messagesError}</p>
        : messages.length === 0 ? <p style={{ padding: 24, color: "var(--neutral-500)" }}>Aucun message.</p>
        : <table className="data-table"><thead><tr><th>Expéditeur</th><th>Contenu</th><th>Date</th><th>Actions</th></tr></thead>
          <tbody>{messages.map((msg) => (
            <tr key={msg.id} style={msg.is_deleted ? { opacity: 0.5 } : undefined}>
              <td style={{ fontSize: 13 }}>{msg.sender ? `${msg.sender.first_name} ${msg.sender.last_name}` : msg.sender_id?.slice(0, 8)}</td>
              <td style={{ fontSize: 13, maxWidth: 300 }}>{msg.is_deleted ? <em style={{ color: "var(--neutral-400)" }}>Message supprimé</em> : (msg.content || "—")}</td>
              <td style={{ fontSize: 13, color: "var(--neutral-500)" }}>{formatDateTime(msg.sent_at || msg.created_at)}</td>
              <td>{!msg.is_deleted && <Button size="sm" variant="danger" onClick={() => setDeleteMessageTarget(msg)}>Supprimer</Button>}</td>
            </tr>
          ))}</tbody></table>}
      </Card>
      <DeleteReasonModal open={deleteSessionOpen} onClose={() => setDeleteSessionOpen(false)} title="Supprimer la session" description="Action irréversible." confirmLabel="Supprimer" loading={actionLoading}
        onConfirm={async (reason) => { setActionLoading(true); try { await deleteSession(id, reason); toast.success("Supprimée"); navigate("/sessions"); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
      <DeleteReasonModal open={Boolean(deleteMessageTarget)} onClose={() => setDeleteMessageTarget(null)} title="Supprimer le message" description="Message masqué pour tous." confirmLabel="Supprimer" loading={actionLoading}
        onConfirm={async (reason) => { setActionLoading(true); try { await deleteMessage(deleteMessageTarget.id, reason); toast.success("Supprimé"); setDeleteMessageTarget(null); load(); } catch (e) { toast.error(e.message); } finally { setActionLoading(false); } }} />
    </div>
  );
}
