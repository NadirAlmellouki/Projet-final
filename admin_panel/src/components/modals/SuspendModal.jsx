import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";
import { SUSPEND_DURATIONS } from "../../utils/constants";

export default function SuspendModal({ open, onClose, userName, onConfirm, loading }) {
  const [duration, setDuration] = useState(168);
  const [reason, setReason] = useState("");
  return (
    <Modal open={open} onClose={onClose} title="Suspendre l'utilisateur"
      description={`Suspendre ${userName}. Action enregistrée dans le journal d'audit.`}
      footer={<><Button variant="secondary" onClick={onClose} disabled={loading}>Annuler</Button>
        <Button variant="warning" loading={loading} disabled={!reason.trim()} onClick={() => onConfirm({ suspended_until: new Date(Date.now() + duration * 3600000).toISOString(), reason })}>Confirmer</Button></>}>
      <div className="field"><label className="field__label">Durée</label>
        <select className="select" value={duration} onChange={(e) => setDuration(Number(e.target.value))}>
          {SUSPEND_DURATIONS.map((d) => <option key={d.hours} value={d.hours}>{d.label}</option>)}
        </select></div>
      <div className="field"><label className="field__label">Motif</label>
        <textarea className="textarea" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Raison de la suspension…" /></div>
    </Modal>
  );
}
