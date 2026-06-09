import Badge from "./Badge";
import { ROLE_LABELS } from "../../utils/constants";
export default function RoleBadge({ role }) {
  return <Badge variant={role || "student"}>{ROLE_LABELS[role] || role}</Badge>;
}
