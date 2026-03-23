# Doer — Setup Guide

## Prerequisites

Before setting up the project, ensure you have the following installed:

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 20+ | Backend runtime |
| **npm** | 10+ | Package management |
| **Flutter** | 3.22+ | Mobile app development |
| **Dart** | 3.4+ | Comes with Flutter |
| **Docker Desktop** | Latest | PostgreSQL & Redis (local dev) |
| **Git** | 2.30+ | Version control |
| **Android Studio** | Latest | Android emulator & SDK |
| **Ollama** | Latest | AI document pre-screening (local LLM) |
| **VS Code** (recommended) | Latest | Code editor |

### Required Accounts & API Keys

| Service | Required | Purpose | Get it from |
|---------|----------|---------|-------------|
| **Firebase** | Yes | Auth, Push Notifications | [console.firebase.google.com](https://console.firebase.google.com) |
| **Google Maps** | Optional | Geocoding, Autocomplete, Distance | [console.cloud.google.com](https://console.cloud.google.com) |
| **Agora** | Optional | Video/Voice Calls | [console.agora.io](https://console.agora.io) |
| **Cloudinary** | Optional | Image Hosting | [cloudinary.com](https://cloudinary.com) |
| **Ollama** | Optional | AI Document Screening | [ollama.com](https://ollama.com) |

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

# Firebase (for auth & push notifications)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Google Maps (geocoding, autocomplete, distance)
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Agora (video calls)
AGORA_APP_ID=your-agora-app-id
AGORA_APP_CERTIFICATE=your-agora-primary-certificate

# Cloudinary (image uploads)
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# PayHere (payment gateway — stub)
PAYHERE_MERCHANT_ID=
PAYHERE_SECRET=

# AI Document Pre-Screening
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llava
ANTHROPIC_API_KEY=
AI_SCREENING_ENABLED=true
AI_SCREENING_TIMEOUT_MS=30000
AI_CONFIDENCE_PASS_THRESHOLD=0.75
AI_CONFIDENCE_FLAG_THRESHOLD=0.40
```

### 2d. Generate Prisma Client & Push Schema

```bash
cd apps/backend
npx prisma generate
npx prisma db push
```

> **Note:** Use `prisma db push` instead of `prisma migrate dev` to avoid migration drift issues with cloud databases.

### 2e. Seed Data

```bash
# Create admin user
npm run seed:admin

# Seed matching algorithm test data (15 workers around Colombo)
npx ts-node src/seed-matching.ts
```

Admin credentials:
- **Email:** `admin@doer.lk`
- **Password:** `admin123456`

### 2f. Start the Backend

```bash
cd ../..
npm run backend
```

The API server starts at `http://localhost:3000`. Verify:

```bash
curl http://localhost:3000/api/categories
```

You should see the escrow cron message in the console:
```
Escrow auto-release cron started (checking every hour)
Server running on port 3000
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

> **API URL:** The app defaults to `http://10.0.2.2:3000/api` (Android emulator → host machine). For physical devices:
> ```bash
> flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api --dart-define=SOCKET_URL=http://YOUR_IP:3000
> ```

### Customer App Features
- Firebase auth (register/login)
- Post jobs with Google Maps location picker
- **Recommended workers** shown after posting (matching algorithm)
- Browse and hire workers
- **Escrow payments** — hold funds, raise disputes, view payment history
- Job-scoped messaging (Socket.IO real-time)
- Video calls (Agora)
- Job timeline with status tracking

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

### Worker App Features
- Firebase auth (register/login)
- Browse available jobs with distance/radius filter
- Apply to jobs with message + price
- **Earnings dashboard** — released/held/disputed breakdown with dispute response
- **Document verification with AI pre-screening** (NIC, qualifications, background check)
- GPS location tracking (sent via Socket.IO every 5 minutes for matching)
- Job-scoped messaging
- Video calls (Agora)

---

## 5. Admin Panel Setup

```bash
# From repo root
npm run admin
```

Opens at `http://localhost:5173`. API calls are proxied to `http://localhost:3000`.

Login with admin credentials from the seed script.

### Admin Panel Pages
| Page | Features |
|------|----------|
| **Dashboard** | Stats overview — users, jobs, payments, revenue charts |
| **Users** | User management — search, filter, toggle active, delete |
| **Verification** | Worker document verification with **AI pre-screening results** (extracted data, confidence, PASS/FLAG/REJECT). AI_FLAGGED workers sorted to top. |
| **Jobs** | Job listing — filter by status/category. **Close REVIEWING/COMPLETED jobs** from detail modal. |
| **Categories** | Service category CRUD |
| **Payments** | Escrow payment management — view held/released/disputed. **Release or refund** held payments directly. |
| **Disputes** | Resolve cancelled-job disputes + escrow disputes. Refund customer / pay worker / no compensation. |
| **Matching Demo** | Interactive Leaflet map — simulate worker presence, run matching algorithm, view ranked results with scores. |

---

## 6. AI Document Pre-Screening Setup (Ollama)

Worker verification uses a local vision LLM to pre-screen uploaded documents before admin review.

### Install Ollama

```bash
# Windows (PowerShell)
winget install Ollama.Ollama

# Or download from https://ollama.com/download
```

### Pull a Vision Model

```bash
ollama pull llava           # 4.7GB — general purpose vision
# or
ollama pull minicpm-v       # better at document/OCR tasks
```

### Verify

```bash
ollama list                 # should show llava or minicpm-v
curl http://localhost:11434/api/tags   # check API is running
```

### How the 3-Tier Pipeline Works

```
Worker uploads documents (NIC, police report, qualifications)
        ↓
┌─ TIER 1: AI Pre-Screening (Ollama LLM) ─┐
│  Analyzes document images                 │
│  Extracts: NIC number, name, dates        │
│  Cross-checks names across documents      │
│  Returns: PASS / FLAG / REJECT            │
└───────────────────────────────────────────┘
        ↓
  PASS → verificationStatus: AI_PASSED (worker continues)
  FLAG → verificationStatus: AI_FLAGGED (admin notified, priority review)
  REJECT → verificationStatus: AI_REJECTED (worker re-uploads)
        ↓
┌─ TIER 2: Admin Manual Review ─────────────┐
│  Admin sees AI results + original docs     │
│  Admin approves or rejects                 │
└────────────────────────────────────────────┘
        ↓
┌─ TIER 3: Trainee Period (First 10 Jobs) ──┐
│  Badge progression: TRAINEE → PLATINUM     │
└────────────────────────────────────────────┘
```

### Without Ollama

If Ollama is not running and no `ANTHROPIC_API_KEY` is set, the system falls back to FLAG (manual admin review). Everything still works — just without AI pre-screening.

---

## 7. Escrow Payment System

### Payment Flow

```
Customer confirms → payment HELD in escrow
        ↓
48-hour dispute window
        ↓
No dispute → auto-RELEASED to worker (hourly cron)
   — OR —
Dispute raised → DISPUTED → admin resolves
        ↓
Admin: release to worker / refund customer / no compensation
```

### Key Points
- Backend runs an **hourly cron job** that auto-releases HELD payments after 48 hours with no disputes
- Customer can **raise a dispute** during the hold window (reason + description)
- Worker can **respond to disputes** from the earnings screen
- Admin can **release or refund** from the Payments page, or resolve from the Disputes page

---

## 8. Matching Algorithm

### How It Works

1. Customer posts a job with location
2. Backend auto-triggers 2-phase matching:
   - **Phase 1:** Haversine filter — find online workers within 25km in the job's category
   - **Phase 2:** Weighted scoring — 40% distance + 25% rating + 20% completion rate + 15% badge level
3. Top 10 workers returned and shown on the **Recommended Workers** screen

### Worker Presence (Redis)

Workers must have Redis presence keys to be matched. In production, the worker app sends GPS via Socket.IO every 5 minutes. For demo:

1. Admin panel → **Matching Demo**
2. Click **"Simulate Presence"** (seeds Redis with all worker locations)
3. Select a job → Click **"Run Matching"**
4. Map shows workers, job location, 25km radius, and ranked results

### Seed Data

```bash
cd apps/backend
npx ts-node src/seed-matching.ts
```

Creates 15 workers around Colombo (5 plumbers, 5 electricians, 5 cleaners) with varying ratings, badge levels, and locations.

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

Admin panel: `npm run admin` (opens at localhost:5173)

---

## Useful Commands

### Backend
| Command | Description |
|---------|-------------|
| `npm run backend` | Start dev server with hot reload |
| `npm run prisma:studio` | Visual database browser |
| `npx prisma db push` | Sync schema to database |
| `npx prisma generate` | Regenerate Prisma client |
| `npm run seed:admin` | Create admin user |
| `npx ts-node src/seed-matching.ts` | Seed matching test data |

### Flutter (from app directory)
| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device |
| `flutter clean` | Clean build cache |
| `flutter analyze` | Lint and check for errors |
| `flutter test` | Run tests |
| `flutter build apk` | Build release APK |

### Docker
| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start PostgreSQL & Redis |
| `docker-compose down` | Stop services |
| `docker-compose down -v` | Stop and delete data |

### Ollama
| Command | Description |
|---------|-------------|
| `ollama list` | List installed models |
| `ollama pull llava` | Download LLaVA vision model |
| `ollama stop llava` | Stop running model |
| `ollama serve` | Start Ollama server |

---

## Ports Summary

| Service | Port | URL |
|---------|------|-----|
| Backend API | 3000 | http://localhost:3000 |
| Admin Panel | 5173 | http://localhost:5173 |
| PostgreSQL | 5432 | (or Neon cloud) |
| Redis | 6379 | (or Upstash cloud) |
| Ollama | 11434 | http://localhost:11434 |

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

### Prisma schema issues
```bash
cd apps/backend
npx prisma generate        # Regenerate client after schema changes
npx prisma db push          # Sync schema to database (non-destructive)
```

> **Don't use `prisma migrate dev`** — it can conflict with cloud database state. Use `prisma db push` instead.

### Flutter app crashes on startup
```bash
flutter clean
flutter pub get
flutter run
```
- If Geolocator crashes: ensure emulator has Google Play Services and location enabled in Settings
- Try `flutter run --dds-port=8888` if connection drops

### Ollama not found after install
Restart your terminal, or:
```bash
export PATH="$PATH:/c/Users/$USER/AppData/Local/Programs/Ollama"
```

### AI screening falls back to FLAG
- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Check model is pulled: `ollama list`
- Set `AI_SCREENING_ENABLED=true` in `.env`
