# Test Plan for Doer — Home Services Marketplace

## ChangeLog

| Version | Change Date | By | Description |
|---------|------------|-----|-------------|
| 1.0 | 2026-03-23 | Dwain | Initial test plan |

---

## 1 Introduction

This document outlines the test plan for **Doer**, a home services marketplace platform connecting customers with workers (plumbers, electricians, cleaners, etc.) in Sri Lanka. The platform consists of four applications: a backend API server, an admin panel, a customer mobile app, and a worker mobile app.

Testing will cover functional, integration, and user acceptance testing across all four applications to ensure the platform meets its requirements and delivers a reliable user experience.

### 1.1 Scope

#### 1.1.1 In Scope

| Module | Features to Test |
|--------|-----------------|
| **Authentication** | Firebase registration, login, JWT token generation, role-based access (Customer/Worker/Admin) |
| **Job Lifecycle** | Job creation, applications, assignment, status transitions (OPEN → ASSIGNED → IN_PROGRESS → COMPLETED → REVIEWING → CLOSED), cancellation |
| **Escrow Payments** | Payment hold, 48-hour auto-release, manual release, dispute raising, dispute response, admin resolution, refund |
| **Matching Algorithm** | 2-phase geospatial matching (Haversine filter + weighted scoring), worker presence tracking, recommended workers after job posting |
| **Worker Verification** | Document upload (NIC, police clearance, qualifications), admin review, badge level calculation, verification status transitions |
| **Messaging** | Job-scoped messaging, real-time delivery via Socket.IO, conversation listing |
| **Admin Panel** | Dashboard stats, user management, worker verification, job management (close jobs), payment management (release/refund), dispute resolution, matching demo |
| **Notifications** | In-app notifications, FCM push notifications, Socket.IO real-time events |
| **Maps Integration** | Geocoding, reverse geocoding, places autocomplete, distance calculation, location picker |

#### 1.1.2 Out of Scope

- Performance and load testing
- Security penetration testing
- PayHere live payment gateway integration (stub only)
- iOS-specific testing (Android emulator only)
- Accessibility (WCAG) testing
- Cross-browser testing for admin panel (Chrome only)

### 1.2 Quality Objective

- Ensure all API endpoints return correct responses for valid and invalid inputs
- Ensure the job lifecycle flows correctly from creation to closure
- Ensure the escrow payment system holds, releases, and refunds correctly
- Ensure the matching algorithm returns ranked workers within the correct radius
- Ensure real-time features (messaging, notifications) work via Socket.IO
- Ensure admin panel correctly manages users, jobs, payments, and disputes
- Identify and document bugs before final submission

### 1.3 Roles and Responsibilities

| Role | Name | Responsibilities |
|------|------|-----------------|
| Backend Developer & Tester | Dwain | Backend API testing, integration testing, admin panel testing |
| Mobile Developer & Tester | Thamindu | Worker app testing, admin verification panel |
| Mobile Developer & Tester | Ashen | Customer app testing, matching algorithm testing |
| Test Coordinator | Dwain | Test plan creation, test case management, bug tracking |

---

## 2 Test Methodology

### 2.1 Overview

The project follows an **Agile** methodology with iterative development sprints. Testing is performed continuously alongside development using a combination of manual testing and API testing. Each feature is tested at the unit level (individual endpoints/screens) and integration level (end-to-end flows).

### 2.2 Test Levels

| Test Level | Description | Tools |
|-----------|-------------|-------|
| **Unit Testing** | Individual API endpoints tested with valid/invalid inputs | Postman, curl |
| **Integration Testing** | End-to-end flows (e.g., job creation → matching → application → payment) | Postman collections, Flutter app |
| **System Testing** | Full platform testing with all 4 apps running together | Manual testing |
| **User Acceptance Testing** | Verify the platform meets functional requirements from the specification | Manual testing with test scenarios |

### 2.3 Bug Triage

Bugs are tracked via GitHub Issues with the following severity levels:

| Severity | Description | Example |
|----------|-------------|---------|
| **High** | Feature is broken, blocks core workflow | Payment fails to hold in escrow |
| **Medium** | Feature works but with incorrect behavior | Wrong notification text sent |
| **Low** | Cosmetic or minor UX issue | Distance shows 0 km instead of actual value |

### 2.4 Suspension Criteria and Resumption Requirements

**Suspension Criteria:**
- Backend server crashes and cannot restart
- Database is corrupted or inaccessible
- Firebase authentication service is down

**Resumption Requirements:**
- Server is stable and all services are running
- Database is restored and accessible
- All blocking bugs from previous cycle are fixed

### 2.5 Test Completeness

Testing is considered complete when:
- All High and Medium severity test cases have been executed
- All High severity bugs are fixed
- At least 90% of test cases pass
- All core flows (auth, job lifecycle, payments, matching) pass end-to-end

---

## 3 Test Deliverables

| Deliverable | Description |
|-------------|-------------|
| Test Plan | This document |
| Test Cases | CSV spreadsheet with all test cases, expected/actual results, and status |
| Bug Reports | GitHub Issues with severity, steps to reproduce, and screenshots |
| Test Summary | Summary of pass/fail counts and coverage |

---

## 4 Resource & Environment Needs

### 4.1 Testing Tools

| Tool | Purpose |
|------|---------|
| Postman | API endpoint testing |
| Android Emulator (Android Studio) | Mobile app testing |
| Chrome DevTools | Admin panel testing and debugging |
| GitHub Issues | Bug tracking and management |
| curl | Quick API verification |

### 4.2 Test Environment

**Backend:**
- Node.js 20+ with Express 5 + TypeScript
- PostgreSQL (Neon cloud database)
- Redis (Upstash cloud instance)
- Running on localhost:3000 during testing

**Admin Panel:**
- React 19 + Vite dev server on localhost:5173
- Proxies API calls to localhost:3000

**Mobile Apps:**
- Flutter 3.x
- Android emulator (API 34, Google APIs image)
- Connects to backend at 10.0.2.2:3000

**External Services:**
- Firebase Authentication (test project)
- Cloudinary (image uploads)
- Google Maps API (geocoding, autocomplete)

---

## 5 Terms/Acronyms

| Term/Acronym | Definition |
|-------------|------------|
| API | Application Program Interface |
| AUT | Application Under Test |
| JWT | JSON Web Token |
| FCM | Firebase Cloud Messaging |
| NIC | National Identity Card (Sri Lanka) |
| CRUD | Create, Read, Update, Delete |
| Escrow | Payment held by platform until job completion confirmed |
| Haversine | Formula to calculate distance between two GPS coordinates |
| Socket.IO | Real-time bidirectional communication library |
| Prisma | TypeScript ORM for database access |
