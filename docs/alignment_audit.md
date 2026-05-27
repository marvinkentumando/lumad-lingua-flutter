# Alignment Audit: Documentation vs. Implementation

This document outlines the discrepancies between the Capstone Project Paper (`documentation.md`) and the current technical implementation of **LUMAD LINGUA**.

## 1. Architectural Discrepancies
*   **Database Engine**: 
    *   **Paper**: The *Scope and Limitations* section (Chapter 1) specifies "PostgreSQL with PostGIS". 
    *   **Implementation**: The system is built entirely on **Firebase (Cloud Firestore)**. The *System Architecture* (Chapter 2) correctly identifies Firebase, but Chapter 1 remains misaligned.
*   **Mapping Framework**:
    *   **Paper**: Mentions both `google_maps_flutter` and `Leaflet.js`.
    *   **Implementation**: Currently uses **`flutter_map`** (a Leaflet-inspired library for Flutter) to support custom tile providers like ArcGIS and OpenStreetMap.
*   **Spatial Queries**:
    *   **Paper**: Mentions **PostGIS** and **GeoFlutterFire2** for proximity queries.
    *   **Implementation**: Proximity queries and heatmap logic are currently handled via client-side filtering of Firestore streams. `GeoFlutterFire2` is included in `pubspec.yaml` but not yet integrated into the `ArchiveMapScreen` logic.

## 2. Feature Misalignments
*   **Heatmap Visualization**:
    *   **Paper**: Specifies "interactive map interface with a Leaflet.js-based heatmap layer."
    *   **Implementation**: The map currently uses **Individual Markers**. A true Gaussian heatmap layer (visualizing density rather than points) has not been rendered.
*   **Leitner vs. SM-2 Algorithm**:
    *   **Paper**: Explicitly names the **Leitner-based spaced repetition algorithm**.
    *   **Implementation**: The code (`srs_models.dart` and `TODO.md`) references the **SM-2 algorithm**. While both are Spaced Repetition systems, they use different scheduling logic.
*   **Language Scope**:
    *   **Paper**: Focuses primarily on **Mansaka** and **Mandaya**.
    *   **Implementation**: The code supports a broader range of 11+ dialects (e.g., Tagakaulo, B'laan, Bagobo) to make the platform scalable, exceeding the original scope.

## 3. Workflow Inconsistencies
*   **Role-Based Access Control (RBAC)**:
    *   **Paper**: Mentions "role-based accessibility" including community elders and NCIP-recognized leaders.
    *   **Implementation**: Roles are simplified into `learner`, `contributor`, `validator`, and `admin`. The specific distinction for "Tribal Leaders" is handled under the generic `validator` role but is not explicitly labeled in the UI.
*   **Pronunciation Assessment**:
    *   **Paper**: Mentions "algorithm for pronunciation assessment based on waveform comparison."
    *   **Implementation**: The `PronunciationService` uses **Dynamic Time Warping (DTW)** which aligns with the paper, but the current UI implementation provides a match percentage rather than the detailed "intonational gain" analysis suggested by the references.

## 4. Pending Requirements (Defined in Paper, Missing in Code)
*   **Pre-test/Post-test Assessments**: The paper objectives mention measuring learning effectiveness. This logic (comparing initial knowledge vs. final score) is not yet implemented in the `LessonSessionScreen`.
*   **Community Validation Fallback**: The paper mentions "manual input" for geo-tagging when GPS is unavailable. The current `ArchiveMapScreen` assumes coordinates are already present in the Firestore document.
*   **Offline Banner**: The paper emphasizes "offline-first synchronization." While Hive and Firestore offline persistence are implemented, the specific "Ethereal Offline Banner" mentioned in the TODO/Roadmap (and implied by the "Digital Vitality" section of the paper) is missing.

---

