# Walkthrough - Audio Dataset Expansion & Preprocessing (`audio-updated-algo`)

Successfully implemented support for additional female speaker reference datasets (`dataset_3` and `dataset_4`) and ensured proper preprocessing handling for supplementary raw dataset (`dataset_2`).

## Changes

### Supabase Dataset Service & Models
#### [supabase_dataset_service.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/services/supabase_dataset_service.dart)
- Expanded discovered storage roots to include `dataset_3` and `dataset_4` alongside `dataset` and `dataset_2`.
- Added support for single-take run-tagged filename parsing (e.g., `madakmul_yang_abol__RUN-2026-0003.wav`) where take number defaults to 1.
- Categorized `dataset_3` as "Female Speaker 1" and `dataset_4` as "Female Speaker 2", while maintaining `dataset` as primary verified learner-facing references (take 1 default).
- Ensured `dataset_2` is treated as a supplementary raw dataset requiring preprocessing configuration during comparison.

### Tests
#### [supabase_dataset_service_test.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/test/services/supabase_dataset_service_test.dart)
- Added unit tests verifying correct discovery, take extraction, and subtitle assignment for `dataset_3` and `dataset_4`.

## Verification Results
### Automated Tests
- Ran `flutter test test/services/supabase_dataset_service_test.dart` — **All 13 tests passed successfully**.
