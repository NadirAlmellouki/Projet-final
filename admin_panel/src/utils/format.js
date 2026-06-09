export function formatDateTime(value) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleString("fr-FR", {
    day: "numeric", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}

export function formatRelative(value) {
  if (!value) return "—";
  const diff = Date.now() - new Date(value).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "À l'instant";
  if (minutes < 60) return `Il y a ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `Il y a ${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `Il y a ${days}j`;
  return formatDateTime(value);
}

export function getFullName(user) {
  if (!user) return "—";
  return `${user.first_name || ""} ${user.last_name || ""}`.trim() || user.email || "—";
}

export function getInitials(user) {
  if (!user) return "?";
  const first = user.first_name?.[0] || "";
  const last = user.last_name?.[0] || "";
  return (first + last).toUpperCase() || user.email?.[0]?.toUpperCase() || "?";
}

export function getUserStatus(user) {
  if (!user) return "unknown";
  if (user.is_banned) return "banned";
  if (user.is_suspended) return "suspended";
  return "active";
}

export function truncate(str, max = 80) {
  if (!str) return "";
  return str.length > max ? `${str.slice(0, max)}…` : str;
}

export function trustTier(score) {
  const n = Number(score) || 0;
  if (n <= 20) return { label: "Nouveau", color: "neutral" };
  if (n <= 50) return { label: "En progression", color: "warning" };
  if (n <= 80) return { label: "Fiable", color: "success" };
  return { label: "Très fiable", color: "primary" };
}
