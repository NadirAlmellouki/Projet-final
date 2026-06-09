import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";

export default function ResolveReportModal({ open, onClose, onConfirm, loading, mode = "resolved" }) {
  const [reason, setReason] = useState("");
  const dismiss = mode === "dismissed";
  return (
    <Modal open={open} onClose={onClose} title={dismiss ? "Rejeter le rapport" : "Résoudre le rapport"}
      footer={<><Button variant="secondary" onClick={onClose} disabled={loading}>Annuler</Button>
        <Button variant={dismiss ? "secondary" : "primary"} loading={loading} disabled={!reason.trim()} onClick={() => onConfirm({ status: mode, reason })}>{dismiss ? "Rejeter" : "Marquer résolu"}</Button></>}>
      <div className="field"><label className="field__label">Notes</label>
        <textarea className="textarea" value={reason} onChange={(e) => setReason(e.target.value)} /></div>
    </Modal>
  );
}
