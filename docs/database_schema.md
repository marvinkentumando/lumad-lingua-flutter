# Lumad Lingua - Database Schema (Firestore)

This document outlines the Firestore NoSQL database schema for the Lumad Lingua application, mapping collections to their conceptual models and indicating access rules.

## 👥 Users & Profiles
**Collection: `users/{userId}`**
- `uid` (String): Unique identifier from Firebase Auth.
- `displayName` (String): Public name.
- `role` (String): User role (`learner`, `contributor`, `educator`, `validator`, `admin`).
- `xp` (Number): Total experience points.
- `level` (Number): Current learner level.
- `streak` (Number): Daily login/learning streak.

### User Subcollections
- **`progress/{lessonId}`**: Tracks completion status and high scores for specific lessons.
- **`bookmarks/{wordId}`**: Saved dictionary entries for quick reference.
- **`notifications/{notifId}`**: In-app alerts (e.g., submission approved, daily reminder).
- **`achievements/{badgeId}`**: Earned cultural badges and milestones.
- **`artifacts/{artifactId}`**: Unlocked "Ancestral Vault" items and their associated lore.
- **`mastery/{wordId}`**: Tracks the SRS (Spaced Repetition) mastery tier for specific words.
- **`srs_progress/{wordId}`**: Detailed Leitner box data (next review date, consecutive correct answers).
- **`dailyQuests/{questId}`**: Active and completed daily/weekly objectives.

## 📚 Learning Content
**Collection: `lessons/{lessonId}`**
- `title` (String): Lesson name.
- `description` (String): Overview of what will be learned.
- `difficulty` (String): e.g., Beginner, Intermediate, Advanced.
- `tags` (Array<String>): Relevant topics or dialects.
- `tasks` (Array<Map>): Embedded lesson steps/activities (quizzes, audio matches, etc.).
- `authorId` (String): UID of the educator/contributor who created it.

**Collection: `words/{wordId}`** (Dictionary Entries)
- `term` (String): The indigenous word.
- `definition` (String): English/Tagalog translation.
- `pronunciationUrl` (String): Link to Firebase Storage audio file.
- `examples` (Array<String>): Contextual usage sentences.
- `dialect` (String): Specific dialect or language variant.
- `contributorId` (String): UID of the submitter.
- `status` (String): `pending`, `approved`, `rejected`.

## 🎙️ Community & Crowdsourcing
**Collection: `voice_submissions/{submissionId}`**
- `wordId` (String): Reference to the dictionary entry.
- `audioUrl` (String): Link to the submitted recording.
- `contributorId` (String): UID of the submitter.
- `status` (String): Validation status (`pending`, `approved`, `rejected`).
- `validatorFeedback` (String): Notes from the validator.

**Collection: `contributor_requests/{requestId}`**
- `uid` (String): User requesting contributor/educator status.
- `reason` (String): Justification or background of the user.
- `status` (String): `pending`, `approved`, `rejected`.

## 🗺️ Geospatial & Cultural
**Collection: `municipalities/{muniId}`**
- `name` (String): Name of the region/municipality.
- `description` (String): Cultural context.
  - **Subcollection: `recordings/{recId}`**
    - Geo-tagged language recordings specific to this region.

## ⚙️ System & Admin
**Collection: `config/{docId}`**
- App-wide settings, feature flags, and global variables managed by Admins.

**Collection: `badges/{badgeId}`**
- Master definitions of achievements/badges available to be earned.

**Collection: `announcements/{announcementId}`**
- Global messages displayed to all users (e.g., new dialect added, maintenance).

**Collection: `telemetry/{docId}`**
- Usage logs, crash reports, and learning analytics.
  - **Subcollection: `points/{pointId}`**: Specific telemetry data points.

**Collection: `global_stats/{docId}`**
- Aggregated statistics (total words learned, active users) used for community impact dashboards.

**Collection: `community_feed/{activityId}`**
- Social feed showing recent activities like users reaching new levels or new words being approved.

---
*Note: All collections are secured via `firestore.rules` which strictly enforce Role-Based Access Control (RBAC). Only authenticated users can write data, and sensitive operations (approvals, config changes) are restricted to `validators` and `admins`.*
