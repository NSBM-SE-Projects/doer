# Doer — Setup Guide

## Prerequisites

Before setting up the project, ensure you have the following installed:

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 18+ | Backend runtime |
| **npm** | 9+ | Package management |
| **Flutter** | 3.22+ | Mobile app development |
| **Dart** | 3.4+ | Comes with Flutter |
| **Docker Desktop** | Latest | PostgreSQL & Redis (local dev) |
| **Git** | 2.30+ | Version control |
| **Android Studio** | Latest | Android emulator & SDK |
| **VS Code** (recommended) | Latest | Code editor |

### Required Accounts & API Keys

| Service | Required | Purpose | Get it from |
|---------|----------|---------|-------------|
| **Firebase** | Yes | Auth, Push Notifications | [console.firebase.google.com](https://console.firebase.google.com) |
| **Google Maps** | Optional | Geocoding, Autocomplete, Distance | [console.cloud.google.com](https://console.cloud.google.com) |
| **Agora** | Optional | Video/Voice Calls | [console.agora.io](https://console.agora.io) |
| **Cloudinary** | Optional | Image Hosting | [cloudinary.com](https://cloudinary.com) |

---

## 1. Clone the Repository

```bash
git clone git@github.com:NSBM-SE-Projects/doer.git
cd doer
```

---

## 2. Backend Setup

### 2a. Start PostgreSQL & Redis

```bash
docker-compose up -d
```

This starts:
- **PostgreSQL** on `localhost:5432` (user: `doer`, password: `doer_password`, db: `doer_db`)
- **Redis** on `localhost:6379`

> **Using cloud databases?** Skip Docker and set `DATABASE_URL` and `REDIS_URL` in `.env` to your Neon/Upstash URLs.

### 2b. Install Dependencies

```bash
npm install
```

This installs dependencies for both `backend` and `admin` via npm workspaces.

### 2c. Configure Environment Variables

```bash
cp apps/backend/.env.example apps/backend/.env
```

Edit `apps/backend/.env`:

```env
# Required
DATABASE_URL="postgresql://doer:doer_password@localhost:5432/doer_db"
REDIS_URL="redis://localhost:6379"
JWT_SECRET="your-secret-key-at-least-32-characters-long"
JWT_EXPIRES_IN="7d"
PORT=3000

# Firebase (for push notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Google Maps (for geocoding, autocomplete, distance)
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Agora (for video calls)
AGORA_APP_ID=your-agora-app-id
AGORA_APP_CERTIFICATE=your-agora-primary-certificate

# Cloudinary (for image uploads — optional)
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### 2d. Run Database Migrations

```bash
cd apps/backend
npm run prisma:generate
npm run prisma:migrate
```

### 2e. Seed Admin User

```bash
npm run seed:admin
```

This creates an admin account:
- **Email:** `admin@doer.lk`
- **Password:** `admin123456`

### 2f. Start the Backend

```bash
cd ../..
npm run backend
```

The API server starts at `http://localhost:3000`. Verify it's running:

```bash
curl http://localhost:3000/api/categories
```

---

## 3. Customer App Setup

### 3a. Install Dependencies

```bash
cd apps/mobile-customer
flutter pub get
```

### 3b. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com) → your project
2. Add an Android app with package name `com.doer.doer`
3. Download `google-services.json` → place in `android/app/`
4. Add an iOS app with bundle ID `com.doer.doer`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`
6. Run FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 3c. Run the App

```bash
flutter run
```

> **API URL:** The app defaults to `http://10.0.2.2:3000/api` (Android emulator → host machine). For physical devices, set the `API_BASE_URL` and `SOCKET_URL` build environment:
> ```bash
> flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api --dart-define=SOCKET_URL=http://YOUR_IP:3000
> ```

---

## 4. Worker App Setup

### 4a. Install Dependencies

```bash
cd apps/mobile-worker
flutter pub get
```

### 4b. Firebase Configuration

Same as customer app but with package name `com.doer.doer_worker`:
1. Add another Android app in Firebase Console with `com.doer.doer_worker`
2. Download its `google-services.json` → place in `android/app/`
3. Repeat for iOS with bundle ID `com.doer.doerWorker`

### 4c. Run the App

```bash
flutter run
```

---

## 5. Admin Panel Setup

```bash
cd apps/admin
npm install
npm run dev
```

Opens at `http://localhost:5173`. API calls are proxied to `http://localhost:3000`.

---

## Running Everything Together

Open 4 terminals:

```bash
# Terminal 1 — Infrastructure
docker-compose up -d

# Terminal 2 — Backend
npm run backend

# Terminal 3 — Customer App
cd apps/mobile-customer && flutter run

# Terminal 4 — Worker App
cd apps/mobile-worker && flutter run -d <second-device-id>
```

> **Tip:** Use `flutter devices` to list connected devices/emulators.

---

## Useful Commands

### Backend
| Command | Description |
|---------|-------------|
| `npm run backend` | Start dev server with hot reload |
| `npm run prisma:studio` | Visual database browser |
| `npm run prisma:migrate` | Create and run migrations |
| `npm run seed:admin` | Create admin user |

### Flutter (from app directory)
| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device |
| `flutter analyze` | Lint and check for errors |
| `flutter test` | Run tests |
| `flutter build apk` | Build release APK |

### Docker
| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start PostgreSQL & Redis |
| `docker-compose down` | Stop services |
| `docker-compose down -v` | Stop and delete data |

---

## Troubleshooting

### "Connection refused" on mobile app
The app can't reach the backend. If using a physical device, replace `10.0.2.2` with your computer's local IP address using `--dart-define`.

### "Core library desugaring" build error
Already configured. If it reappears, ensure `android/app/build.gradle.kts` has:
```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Agora "invalid token" error
Set `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` in the backend `.env`. Get the Primary Certificate from [Agora Console](https://console.agora.io) → Project Settings.

### Push notifications not working
- Ensure Firebase is configured with `google-services.json`
- FCM tokens are registered after login — sign out and sign back in if needed
- Check that `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, and `FIREBASE_CLIENT_EMAIL` are set in `.env`

### Database migration issues
```bash
cd apps/backend
npx prisma migrate reset    # Reset database (deletes all data)
npm run prisma:migrate       # Re-run migrations
npm run seed:admin           # Re-create admin user
```
