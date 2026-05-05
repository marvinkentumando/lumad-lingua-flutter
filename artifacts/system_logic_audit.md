# 🏛️ Lumad Lingua - Logical Error Audit

## 1. Gamification & XP Discrepancy
*   **File**: `lib/screens/lesson_session_screen.dart`
*   **Issue**: The `_bonusXp` variable tracks extra points earned from speed and combos (lines 262-274). However, when calling `firebaseServiceProvider.completeLesson`, only the base parameters are sent.
*   **Impact**: Users are "cheated" out of their combo bonuses in their actual profile balance.
*   **Fix**: Update `completeLesson` in `FirebaseService` to accept a `bonusXp` parameter.

## 2. UI State Corruption in Content Editors
*   **File**: `lib/widgets/lesson_editors/matching_editor.dart` & `sentence_reordering_editor.dart`
*   **Issue**: List items are rendered using `for` loops with index-based keys (`ValueKey('..._$i')`). 
*   **Impact**: If a user deletes the first item in a list of 5, the remaining 4 items will shift indices, but their internal `TextEditingController` or `initialValue` state may not reconcile correctly, causing data to appear in the wrong rows.
*   **Fix**: Implement unique IDs for individual pairs/parts or use `Controller`-managed lists.

## 3. Community Feed Silent Failures
*   **File**: `lib/screens/community_feed_screen.dart`
*   **Issue**: The `addComment` logic (line 293) uses `ref.read(userProfileProvider).value`.
*   **Impact**: If a user opens the feed and tries to comment immediately before their profile stream has emitted (common on slow networks), `profile` will be null and the comment button will do nothing.
*   **Fix**: Use `ref.watch` in the bottom sheet to ensure the profile is available or show a loading state on the "Send" button.

## 4. Inaccurate SRS Mastery Levels
*   **File**: `lib/services/firebase_service.dart`
*   **Issue**: In `completeLesson` (lines 1046-1060), mastery is updated for every vocabulary word in the lesson tasks as long as `stars >= 2`.
*   **Impact**: A student could fail every "Native Word" task but still "master" those words simply by passing the overall lesson (e.g., getting all MCQ tasks right).
*   **Fix**: Pass the `taskPerformance` map into the mastery loop and only increment mastery if `mistakes == 0` for that specific task.

## 5. Hearts State Inconsistency
*   **Files**: `lib/providers/student_provider.dart` vs `lib/screens/lesson_session_screen.dart`
*   **Issue**: Both maintain a `hearts` state. `StudentState` initializes it to 5, but the session screen manages its own local `_hearts` variable.
*   **Impact**: Inconsistent UI if hearts are displayed in different parts of the app, and `studentProvider.decrementHeart()` is never actually utilized.
