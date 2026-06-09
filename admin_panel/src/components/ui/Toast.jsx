import { X, CheckCircle, AlertCircle, Info, AlertTriangle } from "lucide-react";
import "./ui.css";
const ICONS = { success: CheckCircle, error: AlertCircle, warning: AlertTriangle, info: Info };
export default function Toast({ message, type = "info", onClose }) {
  const Icon = ICONS[type] || Info;
  return (
    <div className={`toast toast--${type}`} role="alert">
      <Icon size={18} /><span>{message}</span>
      <button type="button" className="toast__close" onClick={onClose}><X size={14} /></button>
    </div>
  );
}
