import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";

export default function BanModal({ open, onClose, userName, onConfirm, loading }) {
  const [reason, setReason] = useState("");
  return (
    <Modal open={open} onClose={onClose} title="Bannir définitivement" description={`${userName} ne pourra plus accéder à la plateforme.`}
      footer={<><Button variant="secondary" onClick={onClose} disabled={loading}>Annuler</Button>
        <Button variant="danger" loading={loading} disabled={!reason.trim()} onClick={() => onConfirm(reason)}>Confirmer</Button></>}>
      <div className="field"><label className="field__label">Motif</label>
        <textarea className="textarea" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Violations des règles…" /></div>
    </Modal>
  );
}
