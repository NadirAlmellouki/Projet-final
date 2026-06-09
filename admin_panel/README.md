# StudySync Admin Panel

Panneau d'administration React pour StudySync.

## Installation

```bash
cd admin_panel
npm install
npm run dev
```

Backend requis sur `http://localhost:3000`.

## Comptes test

| Email | Mot de passe |
|---|---|
| `admin@studysync.ma` | `Password123` |
| `superadmin@studysync.ma` | `Password123` |

## Structure

```
admin_panel/src/
├── api/          # Axios (auth, admin, reports, sessions…)
├── components/   # UI, layout, modals
├── context/      # Auth, Toast
├── pages/        # Dashboard, Users, Reports, Sessions…
├── routes/       # ProtectedRoute
└── utils/        # format, constants
```

## Backend

Le panneau consomme les endpoints existants sous `/api/admin/*`, `/api/reports`, `/api/sessions`, etc.

Modification backend pour les messages : les admins peuvent lire les messages de session via `GET /sessions/:id/messages` sans être participants.
