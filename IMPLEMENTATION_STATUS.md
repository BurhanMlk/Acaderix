# Implementation Status

> Living checklist. A box is checked only when the corresponding code exists and
> has passed validation. "UI only / offline" means the code compiles and runs in
> offline mode but requires a linked Firebase project to operate end-to-end.

## Phase 1 — Project Foundation ✅

- [x] Flutter Android project, dependencies, feature-first structure
- [x] Material 3 theme, Riverpod, GoRouter with role-aware redirects
- [x] Firebase init (offline mode until configured)
- [x] Reusable widgets, splash/welcome/onboarding/login-selection, role shells
- [x] Freezed models, Cloud Functions skeleton, secure-by-default rules
- [x] `flutter analyze` clean, `flutter test` passing

## Phase 2 — Authentication ✅ (client complete; Firebase link pending)

- [x] Firebase Auth repository (email/password + custom-token student sign-in)
- [x] Academy admin / staff / student login screens + forgot password
- [x] Role-aware routing with per-role route guards
- [ ] End-to-end login requires `flutterfire configure` + deployed claims

## Phase 3 — Super Admin ✅ (client complete; data link pending)

- [x] Super Admin dashboard with live academy statistics
- [x] Academies list with search, filter, approve/suspend actions
- [ ] Subscription plans, billing, broadcasts, audit logs (next iteration)

## Phase 4 — Academy Registration & Setup ⏳

- [x] Academy Admin dashboard with module navigation
- [ ] Multi-step academy registration flow (next iteration)

## Phase 5 — Admission & Student Management ✅ (client complete; secure path pending)

- [x] Students list + admission form
- [x] Atomic roll-number allocation (Firestore transaction)
- [x] Temporary PIN generation + one-time credential slip
- [x] Student dashboard shell
- [x] Cloud Functions: `admitStudent` (hashed PIN), `studentSignIn`, `allocateRollNumber`
- [ ] Client flow must be switched to `admitStudent` callable (Phase 5 refinement)

## Phase 6 — Staff & Academics ⏳

- [x] Staff list screen, Staff/Branch models + repositories
- [ ] Classes, subjects, batches, timetables (next iteration)

## Phase 7 — Attendance & Fees ✅ (client complete; data link pending)

- [x] Attendance marking screen (idempotent per student/date)
- [x] Fees screen: invoices + payment collection (transactional posting)
- [x] Fee calculation helpers + tests

## Phase 8 — Exams, Homework & Payroll ⏳

- [x] Results screen with marks entry + auto grading
- [x] Result calculation helpers + tests
- [ ] Homework, payroll, expenses (next iteration)

## Phase 9 — Notifications & Advanced Features ⬜

- [ ] FCM push, broadcasts, PDF reports, search/filters (partial: search exists)

## Phase 10 — Security, Testing & Release ⏳

- [x] Secure-by-default Firestore/Storage rules
- [x] Privileged Cloud Functions with explicit authorization
- [ ] Granular role/tenant rules + Firebase Emulator tests (next iteration)

## Validation (latest)

- `flutter analyze` → No issues found
- `flutter test` → 17/17 passed

## Blocking configuration requirements

- A Firebase project must be created and linked via `flutterfire configure`
  before Firebase-backed features run end-to-end.
- `functions/` requires `npm install` and `npm run build` before `firebase deploy`.
- Android APK builds require a JDK 17+ (machine reports OpenJDK 11).
