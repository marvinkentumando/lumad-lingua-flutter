# Coding work needed

Date: 2026-11-02

## Scope and evidence

This report comes from a repository-wide static scan of application code, providers, models, widgets, tests, Firebase rules and indexes, platform configuration, and the local MCP server. `todo.md` was excluded and was not used as a source. Existing issue lists and audit reports were also not used as evidence. The scan inventoried 239 files under `lib`, 26 test files, and configuration/source files across Android, iOS, macOS, Linux, Windows, web, and `mcp_server`. Inventory and pattern scanning are not equivalent to a line-by-line audit of every file.

Findings below are grounded in the checked-in implementation. Flutter/Dart are unavailable in this instance, so no analyzer, build, emulator, device, or test-suite results are claimed. Deployed Firebase/Supabase policies and external model infrastructure were not inspected. Rule findings describe the checked-in rules if deployed.

Priorities: **P0** = access control/data integrity; **P1** = broken or incomplete core workflow; **P2** = reliability, product completeness, or release readiness. Each item includes implementation work and a meaningful completion check.

## P0 — Access control and data integrity

### 1. Prevent profile-based privilege escalation

**Evidence:** `firestore.rules`, `hasRole()` and `/users/{userId}`. Profile creation only verifies document ownership; it does not constrain `role`. Educators can update other profiles without a role-field restriction. `hasRole()` accepts the profile role as an alternative to a token claim.

**Code needed:** Restrict profile creation to an approved initial role and explicit field schema. Reserve elevated role assignment for a trusted administration path. Restrict educator updates to authorized students and permitted fields; do not allow educators to assign administrator privileges.

**Completion check:** Emulator tests reject self-creation with an elevated role and educator escalation; legitimate onboarding and administrator role changes still succeed.

### 2. Enforce privacy settings in the data access layer

**Evidence:** `firestore.rules` allows public reads of entire user profiles and several user subcollections. `FirebaseService.updatePrivacySettings()` saves `isPublicProfile` and `shareAnalytics`, but repository searches show no corresponding enforcement in rules or analytics reads. `impact_service.dart` reads all learners for educator reach.

**Code needed:** Separate public profile fields from private account data. Enforce visibility and analytics consent in the actual query/storage design and rules. Scope educator access to their classroom.

**Completion check:** Anonymous users and unrelated learners cannot read private profiles; analytics opt-out excludes a user's data from the intended aggregation path.

### 3. Make rewards and purchases authoritative and idempotent

**Evidence:** `firebase_service.dart`, `claimQuestReward()` increments crystals and marks a quest claimed without reading completion or claimed state. User rules permit owners to change all profile fields except role. `upload_queue_service.dart` replays `claimMilestone` as an unconditional currency increment and `buyHeart` as separate unvalidated increments.

**Code needed:** Validate quest completion, catalog prices, ownership, balances, and reward amounts in a trusted path. Use stable operation IDs and atomic claim/purchase records so retries cannot pay twice. Restrict direct mutation of protected economy fields.

**Completion check:** Concurrent claims and replay after a lost acknowledgement grant one reward; insufficient balances and arbitrary reward amounts are rejected.

### 4. Validate duel state transitions and scoring

**Evidence:** `firestore.rules`, `/duel_matches/{matchId}` allows broad updates by either participant; the waiting-match join condition does not constrain other changed fields. `duel_service.dart` exposes client-supplied damage, forfeiting identity, and result inputs.

**Code needed:** Define allowed transitions and changed fields per actor. Protect participant identities, questions, HP, winner, and rewards. Validate answer events and apply each round outcome once through an authoritative scoring path.

**Completion check:** A participant cannot rewrite the opponent, declare an arbitrary winner, replay damage, or change questions; legitimate concurrent play still completes.

### 5. Restrict invitations and user-generated record ownership

**Evidence:** `firestore.rules` gives any signed-in user create/update/delete access to invitations. Creation rules for words, voice submissions, feedback, contributor requests, and friend requests generally do not bind the submitted owner/sender field to `request.auth.uid`. Community feed writes are unrestricted among signed-in users.

**Code needed:** Bind ownership and sender identities on creation, make them immutable, validate schemas and status fields, and reserve role-bearing invitations and moderation transitions for authorized actors. Scope social edits/deletes to their owner or moderator.

**Completion check:** Rules tests reject forged ownership, forged invitations, and edits to another user's feed entries while preserving intended contribution flows.

## P1 — Core workflow defects

### 6. Reorder moderation transaction reads before writes

**Evidence:** `firebase_service.dart`, `approveWord()` writes version/audit/status before calling `transaction.get(contributorRef)`. Bulk moderation methods such as `bulkApproveWords()` read each document inside a loop that already wrote previous entries.

**Code needed:** Gather all required snapshots before any transaction write, then calculate and apply changes. Review lesson approval and the other bulk moderation methods for the same ordering. Chunk large operations according to current Firestore limits.

**Completion check:** Emulator integration tests approve a contributed word and moderate multiple entries without read-after-write failures; retries do not duplicate rewards or audit events.

### 7. Add rules for municipality and recording workflows

**Evidence:** `firebase_service.dart` reads/writes `/municipalities` and `/municipalities/{id}/recordings`; `firestore.rules` has no matching allow rules. Its final recursive match covers only specific progress collections, not these paths.

**Code needed:** Add collection-specific rules for the intended public/authorized reads, contributor uploads, and administrative edits, with ownership and field validation.

**Completion check:** Municipality discovery and authorized recording submission succeed under the emulator; unauthorized updates fail.

### 8. Preserve queued work when authentication is unavailable

**Evidence:** `upload_queue_service.dart`, `_syncProgress()` returns normally when no user is logged in, after which `processQueue()` removes offline progress. `_syncPendingAction()` also returns normally on missing type/UID and unknown actions, allowing the caller to remove the entry.

**Code needed:** Return typed success/deferred/permanent-failure outcomes. Remove an entry only after confirmed persistence. Retain unauthenticated work and quarantine malformed/unsupported entries with a visible recovery path. Resume processing on authentication changes.

**Completion check:** Processing while signed out leaves progress intact; signing in uploads it once; malformed actions are not silently discarded.

### 9. Isolate local state and queues by account

**Evidence:** `offline_service.dart` stores progress by lesson ID and the cached profile under `current_profile` in global boxes. Pending sync actions share one global queue. `auth_service.dart`, `signOut()` only signs out of Google and Firebase.

**Code needed:** Namespace private cache and queue entries by UID, migrate existing entries safely, and stop workers during account changes. Preserve unsynced work for its owner rather than replaying lesson progress using whichever user is currently signed in.

**Completion check:** User B cannot see or upload user A's progress/profile after an account switch; A's pending work remains recoverable.

### 10. Keep offline drafts from becoming published lessons automatically

**Evidence:** `upload_queue_service.dart` processes every draft with `saveLesson(lesson, status: 'PUBLISHED')`. `offline_service.dart` draft storage contains a lesson without a queued operation carrying intended publication status.

**Code needed:** Preserve save-versus-submit-versus-publish intent in the queue and validate the actor's permission on replay. Syncing a draft should not itself approve or publish it.

**Completion check:** Reconnecting after saving an offline draft keeps it a draft; an explicitly authorized publish action follows the intended moderation flow.

### 11. Reset the progress collection actually used by learning

**Evidence:** `firebase_service.dart`, `resetUserLearningProgress()` deletes `lessonProgress`, while `getUserLessonProgress()` and `completeLesson()` use `progress`. Reset errors are logged and swallowed after profile counters have already changed.

**Code needed:** Define reset semantics across progress, SRS, mastery, quests, achievements, and related counters. Remove the correct records in bounded, resumable operations and surface partial failures.

**Completion check:** Reset removes completed lessons from the learning path and analytics, survives partial failure, and does not restore old progress on refresh.

### 12. Implement a complete account-deletion workflow

**Evidence:** `auth_service.dart`, `deleteUserAccount()` deletes the profile before the Auth user. Checked-in rules allow profile deletion only to administrators. Deleting a Firestore parent does not recursively remove its subcollections; this method does not clean up owned storage or local queues.

**Code needed:** Add a reauthenticated, authorized deletion operation with an explicit retention policy, recursive cleanup/anonymization, local cleanup, and retry/recovery status. Avoid leaving an Auth account without a profile if the second step fails.

**Completion check:** An ordinary user can delete their own account; expired reauthentication causes no premature data removal; retained and removed records match the documented policy.

### 13. Connect validated sentiment posts to the dashboard

**Evidence:** `sentiment_service.dart`, `getValidatedSentimentPosts()` always returns an empty list. `sentiment_dashboard_screen.dart` watches that provider, so it cannot display real validated posts through this path.

**Code needed:** Implement a real data source and typed mapping for validated posts, filtering, ordering, pagination, refresh, and explicit error/empty states. Use one consistent schema with the sentiment data read by impact metrics.

**Completion check:** Seeded validated posts appear and affect dashboard counts; unvalidated posts stay excluded; fetch errors do not look like zero activity.

### 14. Replace simulated sentiment/model deployment behavior

**Evidence:** `sentiment_service.dart` averages a small hardcoded lexicon, generates seven sample posts, and falls back to those samples on Facebook errors. `admin/algorithm_selection_screen.dart` always displays a deployed Colab model without reading deployment status.

**Code needed:** Integrate the intended trained model or accurately present the existing lexicon as a heuristic. Add versioned model metadata, measured evaluation results, ingestion provenance, and explicit unavailable/demo states. If Facebook ingestion remains supported, implement pagination, supported API version management, authentication handling, and observable ingestion failures.

**Completion check:** Deployment status comes from verified metadata; production dashboards never silently substitute sample posts for a failed remote fetch; versioned evaluation data supports model claims.

### 15. Prevent duel question generation from looping forever

**Evidence:** `duel_service.dart`, `_generateQuestions()` checks that at least four word documents exist, then repeatedly samples until four unique translation strings exist. Four documents can contain fewer than four distinct translations.

**Code needed:** Build a finite pool of distinct valid translations before sampling, validate question data, and handle insufficient diversity explicitly.

**Completion check:** Four documents with identical or blank translations terminate with a documented fallback/error; diverse input produces valid unique options.

### 16. Finish notification scheduling and platform permissions

**Evidence:** `notification_service.dart` initializes timezone data but never selects the device timezone before using `tz.local`. It requests exact scheduling. The checked-in Android manifest lacks explicit scheduled-notification receivers and scheduling/notification permissions. iOS declares microphone usage but no speech-recognition usage description despite the speech feature.

**Code needed:** Resolve and set the device timezone, handle timezone changes and denied permissions, add the platform configuration required by the pinned plugins, and implement a supported fallback when exact alarms are unavailable. Add iOS speech permission descriptions and request flow.

**Completion check:** A reminder configured for 20:00 fires at local 20:00 in Asia/Manila; denied permissions surface an actionable state; scheduling survives reboot where supported; speech recognition requests permission safely on iOS.

## P2 — Product completeness, reliability, and release work

### 17. Make privacy export complete and platform-aware

**Evidence:** `firebase_service.dart`, `exportUserData()` returns only the profile, contributed words, and voice submissions. It omits learning history and other user subcollections. `data_privacy_screen.dart` writes the export through `dart:io File` without a web-specific branch.

**Code needed:** Define and implement the export scope for all stored personal data, include stable IDs/schema metadata, paginate large exports, and use a browser download implementation on web.

**Completion check:** A seeded account exports all promised categories; export works on supported mobile and web targets without filesystem API failures.

### 18. Persist sentiment saves and reactions

**Evidence:** `sentiment_dashboard_screen.dart` keeps saved/sparked post IDs only in state-local sets.

**Code needed:** If these controls promise lasting saves/reactions, store them per user with duplicate protection, counts, and appropriate rules; otherwise label them as temporary session actions.

**Completion check:** A saved post survives navigation/restart and account switching; repeated reaction taps do not inflate persistent counts.

### 19. Replace fabricated impact metrics with computed values

**Evidence:** `impact_service.dart` displays educator success as a constant `88%`, estimates reach as `totalPosts * 15`, and counts all learner profiles rather than the educator's students.

**Code needed:** Define each metric's denominator, time window, provenance, classroom scope, and unavailable-data behavior. Compute from authorized source records or clearly label estimates.

**Completion check:** Known fixtures produce the expected metrics; another educator's learners do not inflate classroom impact.

### 20. Make storage failure observable and persist access policy

**Evidence:** `supabase_storage_service.dart` catches deletion errors and returns normally; listing failures become empty lists. Uploads use public URLs and upsert. No Supabase migration/policy directory is present in this checkout.

**Code needed:** Return typed failures to callers so deletion/import workflows can report or retry failure. Define required bucket policies, ownership-scoped paths, overwrite behavior, and private versus public audio access in reproducible configuration. Inspect deployed policy before deciding which policy changes are necessary.

**Completion check:** Denied deletes never report success; a user cannot overwrite another user's recording; private content is not reachable through a public URL.

### 21. Make model evaluation reproducible

**Evidence:** `admin/algorithm_selection_screen.dart` calculates pronunciation comparison metrics from two inline numeric examples. `pronunciation_comparer_interface.dart` supplies fixed default run/config identifiers; `PronunciationService.compare()` selects DTW directly.

**Code needed:** Separate illustrative examples from actual research evaluation. Load versioned, representative labeled audio fixtures and record actual preprocessing/model configuration. Make the comparison contract's algorithm-selection behavior explicit and consistent with app settings.

**Completion check:** Reported metrics reference a real dataset/run; changing the configured algorithm affects the intended production comparison path, with regression fixtures proving it.

### 22. Make the local MCP health tool report actual results

**Evidence:** `mcp_server/bin/server.dart` always reports “Project health is optimal. Analysis is clean.” It does not execute health checks, and unsupported requests/tools receive no structured error response.

**Code needed:** Run bounded read-only checks with exit-status handling and return truthful structured health results. Validate JSON-RPC requests, return method/tool errors, and handle lifecycle/cancellation requirements for the supported protocol.

**Completion check:** A failing analyzer/build produces unhealthy status; invalid and unknown requests receive defined errors rather than hanging.

### 23. Add regression coverage and continuous validation

**Evidence:** Existing tests cover selected utilities, services, and widgets. No `.github` workflow, `integration_test` directory, or Firebase rules test harness is present. Some audio “flow” tests only construct result objects; for example, the candidate-XP test asserts a flag but does not exercise reward persistence.

**Code needed:** Add pinned-toolchain CI for locked dependency installation, analysis, meaningful unit/widget tests, representative builds, and Firebase emulator rules tests. Add regression coverage for items 1–16, especially transaction ordering, signed-out sync, account switching, reward replay, and deletion. Use integration tests where mocks cannot verify persistence or platform permissions.

**Completion check:** CI fails for the actual regressions described here, not only changes to flags/constants. Required test counts and build targets are recorded.

### 24. Finish release identity and signing

**Evidence:** `android/app/build.gradle.kts` uses `com.example.lumad_lingua` and signs release builds with the debug signing configuration. The README's minimum SDK guidance is older than the locked Dart >=3.11 / Flutter >=3.38.4 requirements.

**Code needed:** Configure the intended release identity and secure release signing, preserving compatibility with existing Firebase/OAuth registrations and any already published application. Pin a compatible Flutter toolchain and update development documentation to match it. Validate the supported platform matrix rather than assuming all generated desktop targets work.

**Completion check:** A release artifact uses the intended certificate/application identity, authentication works with that identity, and a clean environment can resolve the unchanged lockfile using the pinned SDK.

## Suggested implementation order

1. Establish emulator/CI validation, then close P0 authorization and economy gaps.
2. Repair transactions, missing collection rules, offline ownership/replay, reset, and deletion.
3. Complete sentiment ingestion/model integration and deterministic duel generation.
4. Validate platform notifications, speech, exports, and release builds.
5. Finish persistent social controls, honest analytics/model metrics, storage policy reproducibility, and MCP reporting.

Environment provisioning and SDK network access remain separate setup work. This document does not treat an unavailable SDK as an application defect, and does not claim external services or deployed policies were verified.
