import Modal from "../ui/Modal";
import Button from "../ui/Button";

export default function ConfirmModal({ open, onClose, title, description, confirmLabel = "Confirmer", variant = "primary", onConfirm, loading }) {
  return (
    <Modal open={open} onClose={onClose} title={title} description={description}
      footer={<><Button variant="secondary" onClick={onClose} disabled={loading}>Annuler</Button>
        <Button variant={variant} onClick={onConfirm} loading={loading}>{confirmLabel}</Button></>} />
  );
}
