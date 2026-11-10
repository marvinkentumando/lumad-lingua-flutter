# Lesson Session Online Completion & Offline Fallback Robustness

## Problem Statement

During a lesson session, completing a lesson sometimes triggers the offline fallback message and queues progress offline instead of successfully committing to the backend, even when the user has internet connectivity. This occurs because `_db.runTransaction` in `completeLesson` can fail due to transient network timeouts, strict Firestore transaction constraints, or offline cache states on Flutter Web.

## Proposed Changes

### [Service Layer] [firebase_service.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/services/firebase_service.dart)
- Refactor `completeLesson` to support a robust fallback: if the atomic Firestore transaction fails due to transient network errors, fall back to non-transactional batch/set updates or retry logic before failing to offline storage.

### [UI / Lesson Session] [lesson_session_screen.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/screens/lesson_session_screen.dart)
- Improve network state check and error differentiation: ensure that offline fallback is only triggered on true network absence (`ConnectivityResult.none`) rather than generic Firestore transaction/timeout exceptions when online.

## Verification Plan

### Automated Tests
- Run `flutter analyze`.

### Manual Verification
- Test lesson completion while online and verify that records sync instantly to the backend without triggering the offline fallback message.
