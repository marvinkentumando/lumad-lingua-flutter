# 🛠️ Lumad Lingua - Functionality Checklist

This document tracks UI elements, buttons, and display areas that are currently implemented but lack backend integration or intended functionality.

---

## 📖 How to Use This Checklist

This document serves as a living roadmap for developers and contributors to identify "functional gaps"—UI components that look finished but don't yet "work" as intended. 

### 🟢 Status Key
- [ ] **Pending**: Not yet started. Needs logic implementation.
- [w] **In Progress**: Currently being worked on.
- [x] **Completed**: Logic is fully integrated and tested with the backend.

### 🛠️ Developer Workflow
1. **Identify**: Find a UI element in the app that feels like a placeholder (e.g., a button that only shows a SnackBar).
2. **Verify**: Check this list to see if it's already documented.
3. **Claim**: If you start working on an item, mark it as `[w]` (Working) to avoid duplicate efforts.
4. **Implement**: Connect the UI to the appropriate Riverpod provider or Firebase service.
5. **Close**: Once verified, change the marker to `[x]`.

### 📝 Reporting New Gaps
When adding a new item, please use the following format:
`- [ ] **Feature Name**: Brief description of the missing functionality and the expected behavior.`

---

## 🏛️ Validator Home Screen
- [x] **Daily Goal Customization (Validator)**: Added a dialog to allow validators to set their own daily verification targets from the Home Screen.
- [x] **Profile/Shield Header Interaction (Validator)**: Linked the header area in Validator Home to the Profile screen.
- [x] **Daily Impact Stats Detail**: Tapping the Daily Impact card shows a breakdown of today's work (approved vs rejected vs flagged) with live data.
- [x] **Urgent Queue Management**:
    - [x] **Skip/Snooze Function**: Urgent items cannot be dismissed or snoozed if a validator is unable to process them immediately.
    - [x] **Empty State Action**: The "All caught up!" state is static. It could include a "Check History" or "Browse All" button.
- [ ] **Hardcoded Dialect Assignment**: Assignment of validators to specific dialects (e.g., Mansaka, Mandaya) is partially hardcoded based on email in the build logic. This should be moved to a proper User Management system.

## 📱 Global Layout (Validator)
- [x] **Top Bar "Validations" Stat Interaction**: The pill showing the number of validations in the top bar is non-interactive. It could link to a detailed **Validator Activity Log** or **History** page.

## 📖 Validator Entries Screen
- [x] **Search History Management**: Added functionality to clear all search history and delete specific terms from the search history list in the Validator Entries Screen.
- [x] **Infinite Scroll Indicator**: Added a themed loading spinner at the bottom of the list when fetching more entries to improve user feedback during pagination.
- [x] **Bulk Action Variety**: Bulk selection mode now supports "Approve", "Reject", and "Flag" options via a unified bulk action sheet.
- [x] **Audio Tip Recording**: Validators can now record and upload audio tips during the flagging process to provide oral corrections to contributors.
- [ ] **Contributor Reputation Accuracy**: Stats like "98% APPROVAL" on entry cards appear to be UI placeholders rather than live data synced with contributor profiles.
- [x] **Search Existing Logic**: The "Search Existing" button in the term detail view now queries the full dictionary database for duplicates, not just the local list.
- [x] **Feedback Display Persistence**: In the History view, the feedback is now interactive and can be edited to update decisions (e.g., change from Reject to Approve or update Flag comments).

## 🎙️ Validator Voices Screen
- [x] **Audio Speed Persistence**: Playback speed (0.5x, 1.0x) resets to 1.0x when switching between items or closing the screen.
- [x] **Waveform Interactivity**: The audio waveform is no longer just a visualization; validators can now tap or drag on the waveform to seek to a specific part of the audio during playback.
- [ ] **Dialect Filter UI**: Similar to the entries screen, there is a `_selectedDialect` variable and a list of `_dialects`, but no UI (chips/dropdown) to allow the validator to change the filter.
- [x] **Bulk Rejection/Flagging**: Bulk selection mode now supports "Approve", "Reject", and "Flag" options via a unified bulk action sheet.
- [x] **Submission ID Truncation**: The "Submission ID" display is now interactive; tapping it opens a detailed **Audit Trail** showing the full Firestore ID, contributor details, timestamps, and validation history.
- [ ] **Contributor Approval Rate**: The "96% APPROVAL" shown on contributor profiles is a UI placeholder and not based on actual historical data.
- [ ] **Transcript Editing**: Validators can view the transcript but cannot suggest a correction or edit it if there's a minor typo. They must either Approve, Flag, or Reject.

## 🎓 Validator Lessons Screen
- [ ] **Dialect Filter UI**: The `_buildDialectFilter` method exists in the code but is never called in the UI, making it impossible for validators to switch dialects.
- [ ] **Missing "Reject" Option**: The lesson cards only offer "Approve" or "Flag" (Request Changes). There is no "Reject" button for lessons that should be completely discarded.
- [ ] **Bulk Action Variety**: Bulk selection mode only supports "Approve". No bulk "Flag" or "Reject" options are available.
- [ ] **History Metrics**: Unlike the Entries and Voices screens, the Lesson History view lacks a summary of "Approved", "Flagged", and "Rejected" stats at the top.
- [ ] **Search History**: No search history chips or management functionality for the lesson search bar.
- [ ] **Preview Interaction Clarity**: In the lesson preview sheet, validators can interact with tasks (select MCQ options, etc.), but there's no visual indication that these interactions are for preview purposes only and not "grading" the lesson.

## 👤 Contributor Profile Screen (Staff Profile)
- [ ] **Hardcoded Profile Stats**: The "RATING" (4.9) and "RANK" (ELITE) displayed in the stats row are currently hardcoded UI placeholders. They should be linked to actual contributor performance metrics or rank data.
- [ ] **Contribution Count Completeness**: The "CONTRIBUTIONS" metric in the stats row only counts words; it should also include voice fragment submissions.
- [ ] **Impact Card Personalization**: The "Students Helped" and "Total Reach" metrics are global platform aggregates. They should be filtered to reflect the specific contributor's personal impact.
- [ ] **Artifacts Section for Staff**: Contributors who transition from being learners lose visibility of their "Earned Artifacts". There should be a way for them to view their collection or a staff-equivalent achievement system.
- [ ] **Role Transition UI**: No UI for a contributor to "Request Validator" or "Transition to Educator" if they wish to increase their responsibilities.
- [ ] **Location Edit Restriction**: Location is locked for contributors with a "Location is locked" hint. It should be editable or linked to their primary cultural region.
- [ ] **Legacy Tracker Access**: The profile screen lacks a direct link to the contributor's full activity history (Legacy Tracker), requiring them to navigate back to the home screen to find it.

## 👤 Validator Profile Screen (Staff Profile)
- [ ] **Hardcoded Profile Stats**: The "RATING" (4.9) and "RANK" (ELITE) displayed in the stats row are currently hardcoded UI placeholders. They should be linked to actual validator performance metrics or rank data.
- [ ] **Impact Card Accuracy**: The "Students Helped" and "Total Reach" metrics in the Impact Card might be using generic contributor formulas; they should be verified to accurately reflect a validator's specific impact (e.g., number of learners using words they validated).
- [ ] **Artifacts Section for Staff**: Non-learner roles like validators don't see the "Earned Artifacts" section. There is no equivalent staff-specific collection or achievement display.
- [ ] **Role Transition Logic**: The "Become a Contributor" button logic in `Journey Management` technically excludes validators but is redundant since they already have higher privileges; however, there's no UI for a validator to "Request Admin" or "Transition Role" if needed.

## 🏹 Contributor Home Screen
- [ ] **Guardian Header Interaction**: The header area showing the contributor's name and rank is currently non-interactive. It should ideally link to a **Profile Settings** or **Rank Progression** detail screen.
- [ ] **Impact Card Accuracy**: Stats like "Students Helped" and "Total Reach" are global aggregates. These should be filtered to reflect the specific contributor's impact (e.g., how many learners have seen or learned words they contributed).
- [x] **Batch Recording Mode**: The sequencer for recording multiple voice fragments now pulls real dictionary entries that currently lack audio recordings.
- [ ] **Legacy Tracker Card Interaction**: Contribution cards in the "Legacy Tracker" section (on the Home screen and in the detailed view) are non-interactive. They should navigate to an **Entry Detail** view showing full metadata and any validator feedback.
- [ ] **Recent Activity Search**: No search bar or filtering by date/keyword within the Legacy Tracker section to find specific past contributions.
- [ ] **Success Dialog XP Hardcoding**: The success message after an entry is submitted mentions "You earned 100 XP!", which appears to be a static text regardless of the actual XP reward logic.
- [ ] **Revised Entry State Management**: The "Revise Entry" button pre-fills the form but creates a new entry instead of updating the existing flagged one, leading to potential duplicates in the validation queue.
- [ ] **Add Entry: Real-time Duplicate Check**: No background check is performed while typing a new indigenous word to warn the contributor if the word already exists in the database (pending or approved).
- [ ] **Add Entry: Draft Preservation**: Lack of a "Save as Draft" feature for cultural entries; progress is lost if the submission sheet is closed prematurely.
- [x] **Record Fragment: Missing Metadata Fields**: Added fields for "Title" and "Transcription" to the recording sheet, ensuring submissions are properly indexed in the database.
- [ ] **Record Fragment: Audio Quality Indicator**: No visual feedback on recording quality (e.g., silence detection or background noise warning) before submission.

## 🏹 Learner Home Screen
- [x] **Scenario Hub Improvements**: Added Completion Badges ("Mastered") and Thematic Thumbnails for scenario stories.
- [x] **Village Echoes (Social Feed) Live Sync**: The feed is integrated with live activity from across the platform (contributions, lesson completions, achievements) and synced with Firestore.
- [x] **Village Echoes Avatar Interaction**: Tapping avatars in the Village Echoes feed now navigates to the corresponding **Member Profile**.
- [x] **Top Climbers Detail Link**: In the Top Climbers preview list, tapping an individual user now navigates to that user's **Member Profile**.
- [ ] **Sync Indicator Interaction**: The "Syncing offline changes..." indicator is non-interactive. It could show a progress detail or allow manual retry if a sync hangs.
- [ ] **Dynamic "New Locales" Indicator**: The "3 NEW LOCALES" badge on the map card is hardcoded and doesn't reflect actual new data in Firestore.
- [x] **Live Reset Timer**: The "RESET IN..." timer for Tribal Challenges now ticks down in real-time (updates every 30 seconds).
- [ ] **Hero Banner Interactivity**: The banner showing Level and Rank is non-interactive. It could link to a detailed rank progression or wisdom breakdown.

## 🗺️ Archive Map Screen (Learner & Contributor Map)
- [x] **Validated Audio Filtering**: The map now only displays audio recordings that have been explicitly approved by a validator, preventing unverified content from appearing to learners.
- [x] **Full Municipality Coverage**: Populated the map with all municipalities from Davao Region (Davao del Sur, del Norte, de Oro, Oriental, and Occidental) with regional coordinates.
- [ ] **Dynamic "New Locales" Indicator**: The "3 NEW LOCALES" badge on the Home Screen's map card is hardcoded and doesn't reflect actual new data in Firestore.
- [x] **Search History & Suggestions**: The map search bar now features a persistent history of previous searches and smart auto-complete suggestions for Davao municipalities and dialects.
- [x] **Active Filter Visibility**: When filters (e.g., specific dialects) are applied, a persistent row of chips is now displayed on the map, allowing users to see and quickly remove active filters.
- [x] **Filter Logic Implementation**: The map now supports a "Province -> Municipality -> Dialect" hierarchy. Filters for provinces and dialects correctly narrow down markers and filter recordings inside the municipality panel.
- [x] **Map Bounds & Region Lock**: The map is now constrained to the Mindanao region (Lat: 5.0-10.0, Lng: 121.0-127.5), keeping users focused on relevant cultural areas and preventing infinite global scrolling.
- [x] **User Location "Follow Me" Mode**: Added a persistent "Follow Me" mode that tracks user movement in real-time. The app now detects and alerts users if they are outside the covered cultural regions of Mindanao.
- [ ] **Municipality Detail Depth**: The information in the `MunicipalityPanel` (description and metadata) is largely template-based and doesn't yet include live stats like "Active Contributors" or "Last Updated".
- [ ] **Contribution CTA in Empty Areas**: Tapping on areas with no markers doesn't offer any interaction. It could suggest "Request a recording for this area" or "Contribute as a speaker".
- [ ] **Audio Recording Actions**: There is no way to "Save" (offline) or "Share" specific recordings found on the map.
- [ ] **Contributor: Add Recording from Map**: No way to add a site or recording directly via the map interface for contributor users.
- [x] **Contributor: Areas in Need Overlay**: Added a density-based heatmap toggle to the Archive Map to visualize linguistic documentation coverage.
- [ ] **Contributor: My Contributions Filter**: Lacks a filter to show only recordings or markers contributed by the current user.
- [ ] **Contributor: Validation Status Markers**: Map markers do not visually distinguish between pending, approved, or flagged recordings for contributors.
- [ ] **Contributor: Quick Recording from Panel**: When viewing a municipality, there's no button for a contributor to quickly start a recording for that specific locale.

## 🏔️ Learning Path Screen (The Ascent)
- [x] **Summit Interaction**: Reaching "The Peak of Wisdom" (the sun icon) now triggers a celebration with confetti, a "Summit Reached" overlay, and a certificate claim prompt when all lessons are completed.
- [x] **Path Background Interactivity**: The topographic background is static. It could be enhanced with subtle animations or parallax effects that respond to scrolling or device tilt.
- [ ] **Offline Lesson Indicators**: Although there's a sync indicator on the dashboard, the Learning Path doesn't clearly show which lessons are cached and available for offline use.
- [x] **Visual Progress Continuity**: In "Mountain" mode, the lines between nodes only turn gold when a lesson is completed. There's no "in-progress" state for a path segment that a user is currently working on.
- [x] **View Preference Persistence**: The toggle between "CLASSIC" and "MOUNTAIN" views is now saved using shared preferences and persists across app sessions.
- [x] **Auto-Scroll to Active Node**: On opening the path, the screen should automatically scroll to the user's first uncompleted lesson.

## 📓 Words & Dictionary Screen (Learner)
- [x] **Hardcoded Dialect Categories**: The category tabs (Mansaka, Mandaya, etc.) are now dynamic and sync with the available dialects in the database to avoid empty tabs.
- [ ] **Search History Quick-Access**: Although search history is recorded, it's not displayed as chips or a list for quick re-entry on the dictionary screen.
- [ ] **Mastery Legend/Detail**: The star icons indicating mastery (SRS levels) are non-interactive. They should link to an explanation of what each level means.
- [x] **Share Functionality**: The "SHARE" button in the word detail expansion now triggers a native share sheet with formatted word details using share_plus.

## 📓 Words & Dictionary Screen (Contributor)
- [ ] **Add Entry Integration**: No floating action button or header button to quickly trigger the "Add Cultural Entry" form from the dictionary screen.
- [ ] **Missing Audio Recording Action**: For words without audio, there is no "Contribute Recording" button for contributor-role users to quickly fill the gap.
- [ ] **My Contributions Toggle**: No filter to allow contributors to see their own pending, flagged, or rejected entries alongside the public validated words.
- [ ] **Direct Entry Revision**: No "Edit" or "Revise" button on word cards for contributors to update their own past submissions directly from the dictionary.
- [ ] **Validation Status Visibility**: Status badges (Pending/Approved/Flagged) are missing from the dictionary cards, which are essential for contributors tracking their work.
- [ ] **Full Database Duplicate Check**: The search bar only filters the local list of approved words; it doesn't query the full Firestore collection (including pending entries) to prevent duplicate submissions.
- [ ] **Contributor Attribution**: The word cards do not display the contributor's name or profile, which is important for community recognition among contributors.

## 🎓 Learning Screen (Hub)
- [ ] **Mist Crystal Store Placeholders**: Items like "Mountain Guide Map" and "Sacred Chant" in the store are functional for spending crystals but don't yet link to actual content unlocks (hidden map locales or specific gallery items).
- [x] **XP Leveling Logic Visibility**: The "Ancestral XP" card is now interactive, showing a detailed modal with level progress, XP needed for the next level, and a wisdom breakdown.
- [ ] **Dynamic Language Color Mapping**: The `_getLanguageColor` and `_getCategoryColor` methods are partially hardcoded and may default to a generic color for newer dialects or categories added via the admin panel.
- [ ] **Learning Hub "Continue Journey" Logic**: The hub calculates the "current" lesson by finding the first one with less than 100% score. It doesn't allow a user to manually pick an earlier lesson from the hub; they must go into the Path view for that.
- [ ] **Lesson Lock Explanation**: Tapping a locked lesson card shows a static text hint. It could be improved by explicitly naming which prerequisite lesson needs to be completed.
- [x] **Mastery Dashboard Integration**: The "Learning Progress" card links to the Mastery Dashboard, and the "Review Ready" action now correctly triggers an SRS Review Session if cards are due.
- [x] **Streak Detail Screen**: Added a dedicated screen for streak history, activity heatmap, milestone tracking, and shield management.
- [x] **Scenario Hub: Dynamic Content**: Moved scenario stories to Firestore, allowing educators/admins to add new cultural scenarios dynamically.
- [x] **Scenario Session Logic**: Implemented the interactive story engine with choice-based logic and dynamic path resolution.
- [x] **SRS Review Engine**: Transformed the flashcard system into a full SRS Review Session that automatically picks due cards for reinforcement.
- [x] **SRS Weekly Trend Accuracy**: The weekly progress chart in the Mastery Dashboard now pulls from a persistent `mastery_history` collection, providing a real 7-day view of learner growth.

## ⚔️ Challenge Hub
- [x] **Lingua Duel (Hardcoded Phase)**: P2P battle system with mock matchmaking against bots (e.g., "Datu Matu"). Includes battle loop, HP bars, and win/loss states.
- [x] **Lingua Duel Question Engine (Hardcoded)**: Vocabulary questions are hardcoded for the initial prototype phase.
- [x] **Saka (The Ascent) (Hardcoded Phase)**: Full 5-stage platformer loop with shrines, quizzes, and collectibles. Scores are currently local-only.
- [x] **Saka Narrative Content (Hardcoded)**: Narrative stages, questions, and glossary are pre-defined in the game logic.
- [x] **Shadowing (Audio Comparison) (Hardcoded)**: Prototype implementation of the "Record & Compare" UI with mock scoring and tone visualization.
- [x] **Warriors Circle (Friend Hub) (Mock Phase)**: Friend list UI with mock data and interactive "Duel" navigation.
- [x] **Challenge Hub Reward Simulation**: Mini-games simulate XP and crystal rewards at the end of sessions (currently updates local state only).

## 👤 Learner Profile Screen ("You" Screen)
- [x] **Profile Stats Accuracy**: The "Words" count in the stats row reflects unique mastered words (SRS Level 4+).
- [x] **Artifact Spotlight Consistency**: The profile view now sorts artifacts by tier and date, ensuring the most significant discoveries are featured.
- [x] **Role Transition Feedback**: Added a detailed view for pending contributor requests showing submission date and status.
- [ ] **Avatar Customization Options**: The "Ancestral Totem" picker is functional but limited to static assets. It could include unlocks based on achievements or levels.
- [ ] **Impact Card for Staff**: Non-learner roles see an "Impact Card" that appears to use a generic template; it should be verified if it pulls live analytics for contributors and educators.
- [ ] **Location "Locked" Logic**: In the edit profile dialog, the location field is hardcoded to be disabled with the hint "Location is locked". It should ideally be editable or linked to GPS/Map locales.

---

## 🏛️ Educator Dashboard
- [x] **Broadcast History**: The "Village Broadcast" allows sending announcements, and now features a dedicated History UI to view, edit, or delete previous broadcasts.
- [ ] **Struggling Student Heuristics**: The "Attention Needed" alert uses a simple hardcoded XP threshold (< 50) to identify struggling students. This should be replaced with a more dynamic analytics service that considers recent performance trends.
- [ ] **Dynamic Cultural Milestones**: Milestone targets are hardcoded to the next 100-word increment. Educators cannot set their own community goals or classroom targets.
- [ ] **Dashboard Activity Filter**: The activity feed shows all types of updates. It should include filters to show only "Struggling Students" or "New Contributions".
- [ ] **Custom Greeting Logic**: The time-based greeting (Maayong Buntag) could be extended to rotate through all supported dialects to set a cultural tone.
- [ ] **Task Management Depth**: The "Pending Tasks" section automatically lists all draft lessons. There's no way to manually add specific tasks (e.g., "Review X's request") or set actual due dates.
- [x] **Activity Feed Variety**: The recent activity is now a unified feed including student joins, lesson completions, high-score achievements, and new pending contributor submissions, providing educators with a comprehensive overview of village growth.
- [ ] **Quick Action Summaries**: Actions like "Manage Units" and "Analytics" are simple navigation buttons. They could be enhanced with "at-a-glance" stats (e.g., "3 Units need review").
- [x] **Unread Notification Indicator Sync**: Entering the Notification Screen now automatically marks all alerts as read, ensuring the "unread" dot on the dashboard syncs immediately.

## 👥 Educator Student Hub
- [x] **Hardcoded Student Data**: The student list and their detailed profiles (XP, Progress, Lessons Completed) are now synced with actual learner accounts in Firestore via the `educatorStudentsProvider`.
- [x] **Mock Lesson Breakdown**: The detailed "Lesson Breakdown" for individual students now reflects real-time progress and accuracy from the database.
- [x] **Attendance Heatmap Realism**: The 30-day activity heatmap now pulls from the students' actual login and activity history stored in Firestore, providing educators with accurate engagement data.
- [x] **Messaging & Guardian Contact**: The "Message Student" and "Contact Guardian" buttons now integrate with the internal notification system to provide direct feedback and simulated guardian alerts.
- [x] **Static Village Filters**: Filtering by "Village" now uses dynamic categories derived from the actual student database.
- [x] **Performance Tracking Accuracy**: The "Struggling" status and accuracy metrics are now backed by performance heuristics in the `educatorStudentsProvider`.
- [ ] **Direct Message Thread**: Tapping "Message Student" sends a notification, but there is no 1-on-1 chat history or thread UI for educators to see previous conversations.
- [ ] **Bulk Message to Village**: Add a way for educators to select multiple students or an entire village to send a targeted message without using the global broadcast.
- [ ] **Report Card Export**: No UI to generate and export an individual student's progress report (PDF) for parents or community leaders.

## 📈 Educator Analytics Screen
- [x] **Live Quiz Performance**: The "Quiz Performance" section now reflects actual student pass/fail rates derived from live lesson progress data in Firestore.
- [x] **Dynamic "Common Hurdles"**: Topics and struggle points are now automatically identified using mistake telemetry from student session logs, identifying exactly where learners are failing most.
- [x] **Growth Graph Accuracy**: The student growth visualization now reflects actual historical registration data from Firestore, providing a real-time cumulative view of village expansion.
- [x] **Export Functionality**: Educators can now export detailed analytics reports in CSV and PDF formats, including student growth, dialect distribution, and performance metrics.
- [x] **Monthly Activity Data**: The monthly view in the activity chart now queries real monthly engagement stats from the students' activity maps, showing active learner counts over the last 6 months.
- [ ] **Retention Heuristics**: Retention is calculated using a simple "XP > 0" proxy. It should be replaced with more accurate metrics like Daily Active Users (DAU) or 7-day retention rates.
- [x] **Feedback Management**: The unread feedback bell in the header now links to a dedicated Student Feedback screen, allowing educators to read, mark as read, and reply to student messages with live unread indicators.
- [ ] **Topic Mastery Heatmap**: A visualization showing which specific cultural categories (Rituals, Tools, Greeting) have the lowest accuracy rates across the entire class.
- [ ] **Engagement Trend Comparison**: No way to compare current weekly activity against the previous week to see if engagement is rising or falling.
- [ ] **Custom Date Range Search**: Analytics are locked to "Weekly" or "Monthly" views; educators cannot select a custom date range for their reports.

## 👤 Educator Profile Screen (Staff Profile)
- [ ] **Hardcoded Profile Stats**: The "RATING" (4) and "RANK" (ELITE) displayed in the stats row are currently hardcoded UI placeholders. They should be linked to actual educator performance metrics or rank data.
- [ ] **Impact Card Accuracy**: The "Students Helped" and "Total Reach" metrics in the Impact Card might be using generic formulas; they should be verified to accurately reflect an educator's specific impact (e.g., number of students enrolled in their lessons).
- [ ] **Artifacts Section for Staff**: Non-learner roles like educators don't see the "Earned Artifacts" section. There is no equivalent staff-specific collection or achievement display.
- [ ] **Role Transition Logic**: The "Become a Contributor" button logic technically excludes validators but is redundant since they already have higher privileges; however, there's no UI for an educator to "Request Admin" or "Transition Role" if needed.

## 👤 Admin Profile Screen (Staff Profile)
- [ ] **Admin-Specific Metrics**: The stats row lacks metrics relevant to administrators, such as "Total Moderated Items" or "System Actions." It currently only shows hardcoded rating/rank placeholders.
- [ ] **Impact Card Focus**: The Impact Card shows global stats; it could be tailored for admins to show system health, user growth trends, or moderation throughput.
- [ ] **Artifacts Section for Staff**: Non-learner roles like admins don't see the "Earned Artifacts" section. There is no equivalent staff-specific collection or achievement display.
- [ ] **Simulation Mode Toggle**: No UI for an admin to "View as Learner" or "Test Role" directly from their profile to verify UX changes without permanent role switches.
- [ ] **Quick Config Access**: The profile lacks a "System Settings" shortcut for global platform toggles (e.g., maintenance mode, registration lock) that may be needed urgently.

## 🎓 Educator Lessons Screen
- [ ] **Hardcoded Category Tabs**: The category filters (Vocabulary, Rituals, etc.) are hardcoded in the UI and may not reflect the actual categories present in the lesson database.
- [ ] **Missing Bulk Management**: No way to perform bulk actions like "Bulk Publish", "Bulk Move to Drafts", or "Bulk Delete" for multiple lessons.
- [x] **Student Completion Detail**: Lesson cards now display accurate real-time student counts and completion rates. Educators can also view a detailed list of specific students who have started or completed each lesson, including their accuracy and scores.
- [ ] **Version Control UI**: The UI displays a version number, but there are no educator-facing tools for managing versions, viewing history, or rolling back changes.
- [ ] **Search Persistence**: The search query and active tab filter are lost when navigating away from the screen and returning.
- [x] **Advanced Filtering**: Educators can now filter lessons by difficulty level (Novice, Intermediate, Expert) and status/category through the enhanced tab system.
- [ ] **Lesson Version Comparison**: No visual way to see what has changed in a lesson since its last published version before committing new edits.
- [x] **Curriculum Map View**: A visual tree representation of how lessons and units connect, helping educators identify gaps in the learning flow.
- [ ] **Drag-and-Drop Reordering**: In the unit management screen, educators should be able to drag lesson cards to visually change their sequence within a unit.
- [ ] **Lesson Cloning**: Add a "Duplicate Lesson" feature to allow educators to quickly create new lessons using an existing structure as a template.

---

## 👑 Admin Overview Screen
- [ ] **System Health Placeholders**: The System Health grid uses hardcoded "default" values if the Firestore document is missing, which might mislead an admin into thinking the system is fine when it's actually just showing a template.
- [ ] **Inefficient Data Aggregation**: The "User Growth" and "Contributions" charts are calculated by fetching all users and all words from Firestore and processing them in the UI. This should be replaced with aggregated metrics from a `stats` collection for performance.
- [ ] **Static System Metrics**: Uptime, API Status, and Storage are currently static strings or mocked values in the database; they are not integrated with real-world infrastructure monitoring.
- [x] **Database Seeder Safety**: Added a confirmation dialog to the "SEED DATABASE" button to prevent accidental data overwrites in a live environment.
- [x] **Live WOTD Selection**: Added admin tools to manually force a specific "Word of the Day" or trigger an automatic rotation override.
- [ ] **Platform Activity Refresh Logic**: The manual refresh button invalidates providers but doesn't trigger a server-side re-calculation of stats, which remains client-side and potentially out of sync.

## 👥 Admin User Management Screen
- [ ] **Bulk User Actions**: No UI support for performing actions (suspension, role changes) on multiple users simultaneously.
- [ ] **Invitation Management**: The "Invite" feature lacks a history view to track, re-send, or cancel pending invitations.
- [ ] **Administrative Audit Logs**: No visible history of administrative actions taken on a user (e.g., who changed their role or suspended them and why).
- [ ] **Advanced Filtering & Sorting**: Lacks granular filters for "Last Active" date ranges, "XP" thresholds, or registration date ranges.
- [ ] **Verification Status Visibility**: User list doesn't clearly distinguish between accounts with verified vs. unverified email addresses.
- [ ] **Admin Impersonation (View As)**: No functionality for admins to "View As" a specific user for troubleshooting or support purposes.
- [ ] **User Data Export**: Missing functionality to export the user list or specific filtered segments to CSV or JSON formats.

## 👑 Admin Content Moderation Screen
- [ ] **Bulk Action Variety**: Bulk actions are limited to "Approve" and "Delete". There is no bulk "Flag" or "Move to Draft" option for large sets of content.
- [ ] **Advanced Filtering**: No way to filter content by specific "Contributor Reputation", "Date Range", or "Flag Reason" across the three tabs.
- [ ] **Audio Recording Metadata Edit**: Admins can preview recordings but cannot edit their metadata (Title, Transcript, Dialect) directly if they spot a minor error.
- [ ] **Lesson Task Preview**: The content moderation list for lessons doesn't allow admins to quickly preview the individual tasks within a lesson without opening the full editor.
- [ ] **Export Logic Limitation**: The current CSV/JSON export only copies data to the clipboard for the *current tab*; it doesn't allow a full database export or file-system saving.
- [ ] **Platform Reset Safety**: The "Reset Platform" action lacks a multi-step confirmation or "Re-type Admin Password" gate, making it potentially dangerous for a one-tap mistake.
- [ ] **Dialect Config Sync**: Dialect settings (Enable/Disable) updated in the modal might not immediately reflect in the "Add Entry" forms across the app without a full restart/refresh.
