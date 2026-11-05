# Lumad Lingua - System & Production-Readiness Audit Report

**Date**: November 2026  
**Auditor**: Senior Principal Mobile Architect & Systems Security Auditor  
**Target Codebase**: Lumad Lingua Flutter (`lib/`, `firestore.rules`, `pubspec.yaml`, `test/`)  

---

## Executive Summary

An exhaustive static security, architectural, and quality audit was conducted on the **Lumad Lingua** Flutter application. The audit evaluated security posture (Firebase Auth, custom claims, security rules), state management (Riverpod, Hive caching, offline queueing), real-time synchronization (Lingua Duels state machine), gamification economy (Mist Crystals, XP, streaks, shop), localization coverage (`AppLocalization`), and accessibility.

Overall, the codebase demonstrates **strong architectural maturity**, featuring atomic transaction hardening in Lingua Duels matchmaking, pre-cached audio asset pipelines, hardware-accelerated shimmer loaders, and a unified administrative header design system. Minor vulnerabilities and polish opportunities were identified and categorized below.

---

## 🔴 P0 (Critical / Security / Integrity Risks)

### 1. Unrestricted Access Control on Invitation Collection
- **Location**: `firestore.rules#L182-L185`
- **Evidence**:
  ```protobuf
  match /invitations/{inviteId} {
    allow read: if true;
    allow create, update, delete: if isSignedIn();
  }
  ```
- **Impact**: Any authenticated user (including basic learners) can create, update, or delete staff invitations in `/invitations`, allowing potential privilege-escalation vectors or invitation spam.
- **Remediation**:
  ```protobuf
  match /invitations/{inviteId} {
    allow read: if true;
    allow create, update, delete: if isEducator();
  }
  ```

### 2. User Profile Creation Schema Validation Deficit
- **Location**: `firestore.rules#L28-L31`
- **Evidence**:
  ```protobuf
  allow create: if isSignedIn() && request.auth.uid == userId;
  ```
- **Impact**: Initial user creation verifies document ownership (`uid == userId`), but does not enforce explicit schema fields or restrict initial `role` assignment on creation. A malicious user constructing raw Firestore requests could attempt self-assigning `role: 'admin'`.
- **Remediation**: Enforce schema key constraints and restrict initial role assignment on document creation:
  ```protobuf
  allow create: if isSignedIn() 
    && request.auth.uid == userId
    && (!('role' in request.resource.data) || request.resource.data.role == 'learner');
  ```

---

## 🟡 P1 (High Priority / Architectural / Workflow Defects)

### 1. Queued Offline Currency Replay Validation Gap
- **Location**: `lib/services/upload_queue_service.dart#L260-L275`
- **Evidence**: When replaying offline pending sync actions (`addMistCrystals`, `addXp`), operations increment currency directly without reading server completion state or verifying transaction idempotency.
- **Impact**: Network dropouts during re-synchronization could potentially replay currency increments multiple times under unstable network conditions.
- **Remediation**: Use deterministic operation transaction keys (`op_id`) for queued offline reward transactions to ensure server-side idempotency.

### 2. Read-After-Write Ordering in Bulk Moderation Transactions
- **Location**: `lib/services/firebase_service.dart#L1685-L1710`
- **Evidence**: In bulk moderation methods, document writes are executed inside loops before subsequent transaction reads occur.
- **Impact**: Firestore transactions require all reads (`transaction.get`) to be executed prior to any writes (`transaction.set` / `transaction.update`). Transgressing this rule causes transaction execution failures under high concurrency.
- **Remediation**: Gather all document snapshots in an initial `Future.wait` batch before applying transaction updates.

---

## 🟢 P2 (Medium / UI / UX / Polish Improvements)

### 1. Incomplete Localization Coverage Across Specific Screens
- **Location**: 13 secondary screens (e.g. `educator_lessons_screen.dart`, `learning_path_screen.dart`, `daily_challenge_session_screen.dart`, `mansaka_history_screen.dart`).
- **Evidence**: While all primary admin screens and core student screens use `l10n.translate(...)`, several sub-views contain hardcoded English string literals.
- **Remediation**: Continue expanding `AppLocalization` key bindings across remaining sub-views.

### 2. Timezone Device Synchronization in Local Notifications
- **Location**: `lib/services/notification_service.dart#L45-L60`
- **Evidence**: `tz.initializeTimeZones()` is invoked, but explicit device timezone lookup (`tz.setLocalLocation`) relies on default system timezone fallback.
- **Remediation**: Explicitly resolve `flutter_timezone` during initialization prior to scheduling daily streak reminder alarms.

---

## 💡 Strengths & Best Practices

1. **Atomic Room Matchmaking (`DuelService`)**:
   - `canClaimMatchData` re-verifies room state inside an atomic Firestore transaction (`status == 'waiting' && player2Id == null`), accompanied by explicit security rule enforcement (`firestore.rules#L140-L155`), completely eliminating room-joining race conditions.
2. **Unified Admin Header Component (`AdminScreenHeader`)**:
   - Standardized `displayBold` gold headline typography (`fontSize: 28`), category eyebrow badges, and adaptive back-navigation across `AdminUsersScreen`, `AdminGamificationScreen`, `AdminDictionaryScreen`, `SentimentDashboardScreen`, and `AdminAssessmentsScreen`.
3. **Interactive Gamified Sentiment & History System**:
   - Daily Spirit Check-In ("Kasing-kasing") and Daily Tone Challenge ("Timbang sa Tingog") seamlessly integrate haptic feedback (`HapticService.celebration()`), spirit particle overlays (`showSpiritParticles`), and daily `SharedPreferences` idempotency checks.
4. **Hardware-Accelerated Repaint Boundaries**:
   - Shimmer skeleton loaders utilize optimized repaint boundaries (`_OptimizedShimmerBox`), preventing layout repaints on parent widget trees during data fetching.
