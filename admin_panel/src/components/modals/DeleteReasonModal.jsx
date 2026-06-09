import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";

export default function DeleteReasonModal({ open, onClose, title, description, confirmLabel = "Supprimer", onConfirm, loading }) {
  const [reason, setReason] = useState("");
  return (
    <Modal open={open} onClose={onClose} title={title} description={description}
      footer={<><Button variant="secondary" onClick={onClose} disabled={loading}>Annuler</Button>
        <Button variant="danger" loading={loading} disabled={!reason.trim()} onClick={() => onConfirm(reason)}>{confirmLabel}</Button></>}>
      <div className="field"><label className="field__label">Motif</label>
        <textarea className="textarea" value={reason} onChange={(e) => setReason(e.target.value)} /></div>
    </Modal>
  );
}
