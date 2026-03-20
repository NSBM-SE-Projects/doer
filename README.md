# Doer  Home Services Marketplace

### 1. Clone the repo
```bash
git clone https://github.com/dwainXDL/doer.git
cd doer
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
