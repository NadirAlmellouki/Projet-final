# StudySync Flutter App

Application mobile Flutter connectée au backend REST **StudySync_BackEnd**.

## Prérequis

1. Backend lancé : `cd StudySync_BackEnd && npm run dev` (port **3000**)
2. Base de données seedée : `npm run db:seed:test`
3. Flutter stable installé

## Lancer l'app

```bash
cd studysync_app
flutter pub get
flutter run
```

### URL selon l'environnement

| Plateforme | URL automatique |
|---|---|
| Chrome / Windows / Edge | `http://localhost:3000` |
| Émulateur Android | `http://10.0.2.2:3000` |

### Lancer (recommandé sur Windows)

```bash
# Desktop Windows — évite les bugs Chromium à la fermeture
flutter run -d windows

# Ou Chrome
flutter run -d chrome
```

Si Chromium reste bloqué après `q` : Gestionnaire des tâches → fermer `chrome.exe` / `dart.exe`.

Override :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

## Stack

- **State** : Riverpod
- **HTTP** : Dio (+ intercepteur JWT)
- **Routing** : go_router
- **Storage** : flutter_secure_storage

## Architecture

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/app_config.dart
│   ├── constants/api_endpoints.dart
│   ├── network/dio_client.dart
│   ├── storage/token_storage.dart
│   ├── router/app_router.dart
│   └── theme/
├── domain/
├── data/
└── presentation/
```

## Endpoints consommés

| Action | Méthode | Endpoint |
|---|---|---|
| Register | POST | `/api/auth/register` |
| Login | POST | `/api/auth/login` |
| Profil (auth) | GET | `/api/auth/me` |
| Profil (détail) | GET | `/api/users/me` |
| Mise à jour profil | PUT | `/api/users/me` |
| Sessions recommandées | GET | `/api/matches/recommend` |
| Liste sessions | GET | `/api/sessions` |
| Mes sessions | GET | `/api/sessions/mine` |

## Comptes de test

- Étudiant : `sara@univ.ma` / `Password123`
