import Avatar from "./Avatar";
import { getFullName } from "../../utils/format";
import "./ui.css";
export default function UserCell({ user, showEmail = true }) {
  if (!user) return <span style={{ color: "var(--neutral-400)" }}>—</span>;
  return (
    <div className="user-cell">
      <Avatar user={user} />
      <div><div className="user-cell__name">{getFullName(user)}</div>{showEmail && <div className="user-cell__email">{user.email}</div>}</div>
    </div>
  );
}
