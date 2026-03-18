# Doer — Home Services Marketplace

A hyperlocal platform connecting clients with verified skilled workers in Sri Lanka.

## Project Structure

```
doer/
├── apps/
│   ├── backend/          # Node.js + Express + TypeScript + Prisma
│   ├── admin/            # React + Vite + TypeScript
│   ├── mobile-customer/  # Flutter (Customer app — "Doer")
│   └── mobile-worker/    # Flutter (Worker app — "Doer Worker")
├── docker-compose.yml    # Local PostgreSQL + Redis
└── .env.example
```

## Getting Started

### Prerequisites
- Node.js v20+
- Flutter 3.x
- Docker Desktop

### 1. Clone the repo
```bash
git clone https://github.com/dwainXDL/doer.git
cd doer
```

### 2. Start local database
```bash
docker compose up -d
```

### 3. Backend setup
```bash
cd apps/backend
cp .env.example .env   # fill in your values
npm install
npx prisma migrate dev
npm run dev
```

### 4. Admin setup
```bash
cd apps/admin
npm install
npm run dev
```

### 5. Flutter apps
```bash
cd apps/mobile-customer   # or mobile-worker
flutter pub get
flutter run
```

## Tech Stack
| App | Stack |
|-----|-------|
| Backend | Node.js, Express, TypeScript, Prisma, PostgreSQL, Redis, Socket.io |
| Admin | React, Vite, TypeScript |
| Mobile | Flutter, Riverpod, GoRouter, Dio, Google Maps |
| Auth | Firebase Auth + JWT |
| Media | Cloudinary |
| Payments | PayHere |
| Hosting | Docker, Render/Railway |
