import Badge from "./Badge";
import { getUserStatus } from "../../utils/format";
const LABELS = { active: "Actif", suspended: "Suspendu", banned: "Banni" };
export default function StatusBadge({ user }) {
  return <Badge variant={getUserStatus(user)}>{LABELS[getUserStatus(user)]}</Badge>;
}
