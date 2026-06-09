export const ROLE_LABELS = {
  student: "Étudiant",
  moderator: "Modérateur",
  admin: "Admin",
  super_admin: "Super Admin",
};

export const REPORT_REASONS = {
  harassment: "Harcèlement",
  spam: "Spam",
  fake_profile: "Faux profil",
  safety: "Sécurité",
  other: "Autre",
};

export const SESSION_STATUS = {
  created: "Créée",
  active: "Active",
  completed: "Terminée",
  cancelled: "Annulée",
};

export const SUSPEND_DURATIONS = [
  { label: "24 heures", hours: 24 },
  { label: "3 jours", hours: 72 },
  { label: "7 jours", hours: 168 },
  { label: "30 jours", hours: 720 },
  { label: "Indéfini (1 an)", hours: 8760 },
];
