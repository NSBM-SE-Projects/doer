# 🛠️ Doer - Home Services Marketplace

**PUSL2021 - Computing Group Project (CGP)**

<div>
    <img src="./assets/logo/doer_logo.png" alt="Doer Logo" height="300">
</div>

## 🗄️ Overview

Through a mobile platform. It features real-time messaging and video calls, job posting with location-based worker matching, a full job lifecycle from posting to payment release - powered by a suite of frameworks with a singular backend, 1 vite web app and 2 flutter apps, making it one of our most tough projects by far.

![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)
![Zod](https://img.shields.io/badge/Zod-3E67B1?style=for-the-badge)
![Socket.IO](https://img.shields.io/badge/Socket.IO-010101?style=for-the-badge&logo=socket.io&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Maps](https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white)
![Agora](https://img.shields.io/badge/Agora-099DFD?style=for-the-badge)
![Helmet](https://img.shields.io/badge/Helmet-000000?style=for-the-badge)
![CORS](https://img.shields.io/badge/CORS-00599C?style=for-the-badge)
![Morgan](https://img.shields.io/badge/Morgan-FF6C37?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dio](https://img.shields.io/badge/Dio-0175C2?style=for-the-badge)
![Socket.io](https://img.shields.io/badge/Socket.IO-010101?style=for-the-badge&logo=socket.io&logoColor=white)
![Google Maps](https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white)
![Google Sign-In](https://img.shields.io/badge/Google-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Permissions](https://img.shields.io/badge/Permissions-9C27B0?style=for-the-badge)
![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)
![Neon](https://img.shields.io/badge/Neon-00E599?style=for-the-badge)
![Upstash](https://img.shields.io/badge/Upstash-00E9A3?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![npm](https://img.shields.io/badge/npm-CB3837?style=for-the-badge&logo=npm&logoColor=white)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

## 📌 Features 
- Real-time messaging & video calls
- Full job lifecycle management
- Location-aware worker matching
- Dual push notification system 
- Identity verification & trust system

## Folder Structure
```
Doer/doer/
  ├── apps/
  │   ├── backend/
  │   │   ├── prisma/
  │   │   └── src/
  │   │       ├── config/
  │   │       ├── middleware/
  │   │       ├── routes/
  │   │       ├── sockets/
  │   │       └── utils/
  │   │
  │   ├── mobile-customer/
  │   │   ├── android/
  │   │   ├── ios/
  │   │   └── lib/
  │   │       ├── app/
  │   │       ├── core/
  │   │       │   ├── config/
  │   │       │   ├── constants/
  │   │       │   ├── router/
  │   │       │   ├── services/
  │   │       │   ├── theme/
  │   │       │   └── widgets/
  │   │       ├── features/
  │   │       │   ├── auth/screens/
  │   │       │   ├── home/screens/
  │   │       │   ├── jobs/screens/
  │   │       │   ├── messaging/screens/
  │   │       │   ├── notifications/screens/
  │   │       │   ├── payments/screens/
  │   │       │   ├── profile/screens/
  │   │       │   ├── reviews/screens/
  │   │       │   ├── video/
  │   │       │   └── workers/screens/
  │   │       └── services/
  │   │
  │   ├── mobile-worker/
  │   │   ├── android/
  │   │   ├── ios/
  │   │   └── lib/
  │   │       ├── app/
  │   │       ├── core/
  │   │       │   ├── config/
  │   │       │   ├── constants/
  │   │       │   ├── router/
  │   │       │   ├── services/
  │   │       │   ├── theme/
  │   │       │   └── widgets/
  │   │       └── features/
  │   │           ├── auth/screens/
  │   │           ├── dashboard/screens/
  │   │           ├── earnings/screens/
  │   │           ├── jobs/screens/
  │   │           ├── messaging/screens/
  │   │           ├── notifications/screens/
  │   │           ├── profile/screens/
  │   │           ├── verification/screens/
  │   │           └── video/
  │   │
  │   └── admin/
  │       └── src/
  │
  └── References/
  ```

## 🏁 Quick Start

### Prerequisites
- Node.js 20+ and npm
- Git
- VS Code (recommended)

### Setup Instructions
1. Clone the repository
2. Follow `SETUP-GUIDE.md` for detailed environment setup
3. Configure ENV Variables (Tokens/Keys)
4. Install dependencies for backend and frontend on all 3 apps
5. Run development servers

## 🤼 The Team 

All members who have contributed in this project can be found in the contributors list.

## 📫 Contact 

If you have any feedback or questions, feel free to contact me. [@dwainXDL](https://github.com/dwainXDL)
