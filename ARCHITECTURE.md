# Architecture

Academy Management System is a multi-tenant Flutter Android SaaS application
powered by Firebase. This document describes the system architecture and the
decisions behind it.

## 1. High-level overview

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Android app (Material 3, Riverpod, GoRouter)       │
│  ┌───────────┐  ┌────────────┐  ┌─────────┐  ┌──────────┐  │
│  │ Super     │  │ Academy    │  │ Staff   │  │ Student  │  │
│  │ Admin     │  │ Admin      │  │         │  │ (Parent) │  │
│  └───────────┘  └────────────┘  └─────────┘  └──────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │ Firebase SDKs (Auth, Firestore,
                           │ Storage, Messaging, App Check,
                           │ Crashlytics, Analytics)
┌──────────────────────────▼──────────────────────────────────┐
│  Firebase backend                                          │
│  • Firebase Authentication + custom claims                 │
│  • Cloud Firestore (tenant-scoped subcollections)          │
│  • Cloud Storage (tenant-scoped paths)                     │
│  • Cloud Functions (Admin SDK — privileged operations)     │
│  • Security Rules (Auth + claims + tenant checks)          │
└─────────────────────────────────────────────────────────────┘
```

## 2. Roles

| Role | Experience |
| --- | --- |
| Super Admin | Platform-wide control: academy approvals, suspension, subscriptions, broadcasts |
| Academy Admin | Full management within one academy |
| Staff | Role-based permissions (teacher, accountant, receptionist, branch manager, …) |
| Student | Read-only view of own records; parents reuse this login |

A user holds exactly one top-level role in a session. Roles are derived from
Firebase **custom claims** (set by trusted Cloud Functions), never from the
client. Staff receive additional academy-scoped permission flags.

## 3. Multi-tenancy

Every academy has a unique `academyId` and a unique human-friendly
`academyCode`. Tenant data lives in subcollections under
`academies/{academyId}/...`.

Isolation is enforced in three layers:

1. **Authentication + custom claims** identify the user and their role.
2. **Firestore/Storage Security Rules** ensure a user can only read/write paths
   scoped to their own academy (and branch).
3. **Cloud Functions (Admin SDK)** handle privileged operations that rules
   cannot express. Admin SDK bypasses rules, so functions implement explicit
   authorization and never trust client-supplied roles, ids, prices, or
   subscription status.

Client code never contains Firebase service account credentials.

## 4. Firestore shape

Top-level collections: `users`, `academy_codes`, `academies`,
`subscription_plans`, `subscriptions`, `subscription_payments`,
`support_tickets`, `broadcasts`, `platform_settings`.

Academy subcollections include `branches`, `staff`, `students`, `guardians`,
`classes`, `courses`, `subjects`, `batches`, `enrollments`, `attendance`,
`staff_attendance`, `fee_structures`, `fee_invoices`, `fee_payments`, `exams`,
`results`, `homework`, `timetables`, `salaries`, `expenses`, `announcements`,
`audit_logs`, and `counters`.

`academies/{academyId}/counters/{counterId}` holds atomic counters (e.g. the
next roll number) so concurrent admissions never produce duplicate roll
numbers.

## 5. Flutter project structure

```
lib/
├── main.dart                # entrypoint
├── app/                     # app shell, router, bootstrap, Firebase options
├── core/                    # config, constants, errors, theme, utils, widgets
├── features/<feature>/
│   ├── data/                # repository implementations
│   ├── domain/              # models + repository interfaces
│   ├── application/         # Riverpod notifiers / state holders
│   └── presentation/        # screens + widgets
└── shared/                  # cross-feature shared widgets
```

The architecture is **feature-first** with a light repository pattern. Models
use Freezed for immutability and JSON (de)serialization. Riverpod 3 notifiers
own state; GoRouter handles role-aware navigation.

## 6. Security model

- **Firebase App Check** protects backend access from non-app clients.
- **Custom claims** (`role`, `academyId`, optionally `branchId`) drive routing
  and rules. Clients cannot modify claims.
- **Temporary student PINs** are never stored in plaintext, never re-exposed,
  expire, and are rate-limited; a stronger password is forced on first login.
- **Financial operations** (invoices, payments, adjustments, refunds) are
  modeled as separate immutable records with idempotent, server-side posting.
- **Audit logs** record sensitive authentication and administrative events.

## 7. Cloud Functions responsibilities

- Super Admin bootstrap (trusted provisioning) — never public registration.
- Academy registration/approval and academy code generation.
- Roll number allocation (transactional, unique per academy).
- Temporary PIN issuance and student custom-token sign-in.
- Subscription lifecycle enforcement and payment reconciliation.
- Push notification fan-out (FCM).
- Privileged corrections with audit trails.

## 8. Formatting & currency

All amounts default to **PKR**. Formatting uses `intl` with the always
available `en_US` number data (see `core/utils/currency.dart`), so formatting
never depends on runtime locale initialization.
