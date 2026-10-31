# Implementation Status

> Living checklist. A box is checked only when the corresponding code exists and
> has passed validation. "UI only / offline" means the code compiles and runs in
> offline mode but requires a linked Firebase project to operate end-to-end.

## Phase 1 — Project Foundation ✅

- [x] Flutter Android project, dependencies, feature-first structure
- [x] Material 3 unified dark glass theme with brand gradients across all screens
- [x] Centralized transparent glass styling across all roles (Super Admin, Academy Admin, Staff, Student)
- [x] Riverpod state management & GoRouter with role-aware redirects
- [x] Firebase init (offline mode until configured)
- [x] Reusable widgets, splash/welcome/onboarding/login-selection, role shells
- [x] Freezed models, Cloud Functions skeleton, secure-by-default rules
- [x] `flutter analyze` clean, `flutter test` passing

## Phase 2 — Authentication & Access Control ✅

- [x] Firebase Auth repository (email/password + custom-token student sign-in)
- [x] Super Admin login screen + credentials auth
- [x] Academy admin / staff / student login screens + forgot password
- [x] Academy Admin password reset via direct reset link (no Blaze plan requirement)
- [x] Super Admin dedicated password change screen
- [x] Role-aware routing with per-role route guards

## Phase 3 — Super Admin Operations ✅

- [x] Super Admin dashboard with live academy statistics & real-time streams
- [x] Mobile navigation drawer with auto-close on selection
- [x] Academies list with real-time search, filter, approve/suspend actions
- [x] Dedicated Academy Details full screen (replacing mobile dialogs)
- [x] Academy status toggle (Active / Suspended) with instant Firestore updates
- [x] Dedicated Academy deletion flow with confirmation and cascade cleanup
- [x] Dedicated Academy Admin password reset screen

## Phase 3.1 — Platform Subscriptions & Billing ✅

- [x] Dual-collection Firestore real-time synchronization (`academies` & `subscriptions`)
- [x] Domain models: `SubscriptionPlan`, `AcademySubscription`, `SubscriptionPayment`
- [x] Subscriptions overview screen with real-time metrics (Monthly Revenue, Active, Expiring, Expired)
- [x] Non-overflowing responsive TabBar for mobile screens (`Academies`, `Plans`, `Payments`)
- [x] Dedicated `ExtendSubscriptionScreen`:
  - Quick duration presets (+1, +2, +3, +6 months)
  - Custom dark theme date picker
  - Dual-collection Firestore sync with immediate UI reflection
- [x] Dedicated `ChangePlanScreen`:
  - Standardized monthly plans (Basic, Standard, Premium)
  - Yearly plan toggle removed (strictly monthly for now, extensible in future)
  - Responsive layout with zero phone overflows
- [x] Dedicated `RecordPaymentScreen`:
  - Logs PKR fee receipts to `subscription_payments`
  - Automatically extends subscription duration (+30d) and activates status
- [x] Dedicated `EditPlanPriceScreen`:
  - Live tier fee adjustment with quick presets
- [x] Firestore security rules for subscriptions, plans, and payments

## Phase 4 — Academy Registration & Setup ⏳

- [x] Academy Admin dashboard with transparent glass theme & module navigation
- [x] Academy Admin Status & Subscription Access Gating (Real-Time):
  - **Pre-Login Security Check & Token Gating:** Uses admin info (email) to locate academy and verify standing BEFORE signing in:
    - If status is `pending`, `suspended`, `expired`, or payment is overdue: **no Firebase token is issued** and `signInWithEmailAndPassword` is never called. User is shown `AcademyStatusNoticeScreen` with Super Admin contact info without creating an authenticated session.
    - If status is `active`, subscription is valid, and payment is cleared: authenticates credentials and issues the session token into dashboard.
  - **Firestore Security Rules Reinforcement:** Subcollections (`students`, `staff`, `fees`, `branches`, `attendance`, `marks`) enforce `data.status == 'active'` so unapproved or suspended academies cannot query database subcollections even with an ID token.
  - Dedicated Super Admin contact card with phone (`+92 300 1234567`), email, one-tap copy to clipboard, and manual status check button
  - Real-time reactive stream & auto-revocation: immediately terminates session if academy is suspended or expires during an active session
  - Auth repository fallback: automatically resolves `academyId` from `academies` by `ownerUid` or `ownerEmail` if unlinked in `users/{uid}`
- [ ] Multi-step academy registration flow (next iteration)

## Phase 5 — Admission & Student Management ✅ (client complete; secure path pending)

- [x] Students list + admission form
- [x] Atomic roll-number allocation (Firestore transaction)
- [x] Temporary PIN generation + one-time credential slip
- [x] Student dashboard shell with unified transparent glass theme
- [x] Cloud Functions: `admitStudent` (hashed PIN), `studentSignIn`, `allocateRollNumber`
- [ ] Client flow switch to `admitStudent` callable (Phase 5 refinement)

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

- [x] Secure-by-default Firestore/Storage rules with subscriptions security
- [x] Privileged Cloud Functions with explicit authorization
- [x] Comprehensive automated test suite (48 unit & widget tests)
- [ ] Granular role/tenant rules + Firebase Emulator tests (next iteration)

## Validation (latest)

- `flutter analyze` → No issues found! (0 warnings/errors)
- `flutter test` → 48/48 tests passed!

## Notes

- Platform and device-specific local configuration files (`android/gradle.properties`, `firebase.json`, `pubspec.lock`) are kept local to the user environment.
