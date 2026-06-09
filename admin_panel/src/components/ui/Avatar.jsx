import { getInitials } from "../../utils/format";
import "./ui.css";
export default function Avatar({ user, size = "md", className = "" }) {
  const photo = user?.profile_photo || user?.profile_photo_url;
  return (
    <div className={`avatar ${size === "lg" ? "avatar--lg" : ""} ${className}`.trim()}>
      {photo ? <img src={photo} alt="" /> : getInitials(user)}
    </div>
  );
}
