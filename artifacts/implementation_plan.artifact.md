# Implementation Plan - Audio Dataset Expansion & Preprocessing (`audio-updated-algo`)

Support additional female speaker reference datasets (`dataset_3` and `dataset_4`) and ensure correct preprocessing handling for supplementary raw dataset (`dataset_2`).

## Proposed Changes

### Supabase Dataset Service & Models
#### [MODIFY] [supabase_dataset_entry.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/models/supabase_dataset_entry.dart)
- Update documentation and helpers for supplementary dataset sources (`dataset_2`, `dataset_3`, `dataset_4`).

#### [MODIFY] [supabase_dataset_service.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/services/supabase_dataset_service.dart)
- Expand discovered Supabase storage roots from `['dataset', 'dataset_2']` to `['dataset', 'dataset_2', 'dataset_3', 'dataset_4']`.
- Handle single-take / multi-take parsing for `dataset_3` and `dataset_4` (female speaker datasets, 1 take per phrase/word, preprocessed).
- Mark `dataset_2` as requiring preprocessing configuration (since `dataset_2` is not preprocessed yet).

### Audio Comparison Screen
#### [MODIFY] [audio_comparison_screen.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/screens/audio_comparison_screen.dart)
- Ensure audio loading and decoding for `dataset_2` applies the standard reference preprocessing configuration (`WavDecoder.prepareReferencePcm`), while `dataset`, `dataset_3`, and `dataset_4` are handled correctly as preprocessed supplementary/main references.
- Maintain primary dataset take 1 as the default learner-facing reference on the UI.

## Verification Plan

### Automated Tests
- Run existing unit and widget tests (`flutter test`) to ensure no regression in pronunciation comparison and dataset loading.

### Manual Verification
- Verify dataset discovery logs in SupabaseDatasetService for `dataset`, `dataset_2`, `dataset_3`, and `dataset_4`.
- Verify UI audio comparison screen loads primary dataset as default reference while incorporating `dataset_2`, `dataset_3`, and `dataset_4` into the multi-reference comparison pool.
