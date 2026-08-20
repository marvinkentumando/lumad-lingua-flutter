# Project Pivot Change Plan: Lumad Lingua

## 1. Executive Summary
The project is pivoting from a **Geo-Tagged Documentation Platform** to a **Sentiment-Driven Cultural Vitality Monitor**. This shift focuses on the "Digital Vitality" of the Mansaka language as expressed on social media (Facebook) rather than manual field documentation and geographic mapping.

## 2. Scope Modifications
### A. Features to be Removed
- [x] **GIS & Mapping:** Removal of `admin_map_architect_screen.dart`, `archive_map_screen.dart`, and all `google_maps_flutter` / `Leaflet` integrations.
- [x] **Manual Documentation Pipeline:** Deletion of the `Contributor` and `Validator` roles and their specific UI workflows.
- [x] **Validation Logic:** Removal of the "Pending/Approved/Rejected" state machine for vocabulary entries.
- [x] **Secondary Language (Mandaya):** Removal of Mandaya data to focus exclusively on Mansaka.

### B. Preserved & Standalone Features
- [x] **Digital Dictionary:** Verified as a standalone module (Mandaya entries removed).
- [x] **Audio Comparison:** Decoupled from geographic/GPS requirements.
- [x] **Gamified Learning:** Spaced repetition and quiz modules updated to use Mansaka-only dictionary data.

### C. New Feature: Sentiment Analysis
- [x] **Data Source:** Collection logic for Facebook posts utilizing Mansaka vocabulary.
- [x] **Core Function:** Sentiment analysis (Positive, Neutral, Negative) logic implemented in `SentimentService`.
- [x] **Impact:** Replacement of the GIS "Heatmap" with a "Sentiment Trend" dashboard.

## 3. Structural & Architectural Changes
### A. User Roles & Authentication
- [x] **Consolidation:** Merged `Contributor` and `Validator` into a single **"Staff/Researcher"** role.
- [x] **Access Control:** The Researcher role now has direct write access to the database without an approval gate.

### B. Database Schema (Firestore)
- [x] **Deprecate:** `Geo_Tags` and `Validations` collection usage removed from code.
- [x] **Modify:** `Vocabulary_Entries` logic updated to ignore `ValidationStatus`.
- [x] **New Collection:** `Social_Sentiment_Data` collection logic integrated into the app.

## 4. Technical Implementation & Cleanup Plan
### A. Code Cleanup (Completed)
- [x] **Router Cleanup:** Removed imports and routes for Map, Contributor, and Validator screens in `router_provider.dart`.
- [x] **Navigation Cleanup:** Deleted Map and redundant roles from `role_nav_config.dart`.
- [x] **UI Layout:** Cleaned `main_layout.dart` of validation counters and role-specific redirects.
- [x] **Dashboard:** Removed `_buildMapCard` and its supporting UI functions from `dashboard_screen.dart`.
- [x] **Role Enum:** Updated `UserRole` in `role_provider.dart` to a unified `staff` model.

### B. Screen Deletion (To Be Done)
- [ ] **Delete Physical Files:** 
    - [ ] `lib/screens/admin_map_architect_screen.dart`
    - [ ] `lib/screens/archive_map_screen.dart`
    - [ ] `lib/screens/contributor_screen.dart`
    - [ ] `lib/screens/validator_screen.dart`
- [ ] **UI Refactoring:** Update `audio_comparison_screen.dart` to load all vocabulary regardless of status.

### C. Documentation & Presentation (To Be Done)
- [ ] **README:** Update with the new sentiment-driven project description.
- [ ] **Architecture:** Update diagrams to reflect removal of Maps and addition of Sentiment Analysis.
- [ ] **Panel Prep:** Prepare "Before and After" slides for the panel justification.

## 5. Implementation Status Summary
- [x] **Role Consolidation**
- [x] **GIS/Map Cleanup**
- [x] **UI Navigation Update**
- [x] **Top Bar Cleanup**
- [x] **Dashboard Refactor**
- [x] **Dictionary Focus (Mansaka Only)**
- [x] **Sentiment Service Implementation**
- [x] **Sentiment Dashboard Creation**
- [x] **Impact Metrics Refactor**

## 6. Justification for the Panel
- [x] **Technical Efficiency:** Removing the GIS eliminates the "Linguistic Desert" bottleneck.
- [x] **Modern Relevance:** Sentiment analysis provides a more accurate picture of "Digital Vitality."
- [x] **Simplified Workflow:** Merging roles reduces administrative overhead.
