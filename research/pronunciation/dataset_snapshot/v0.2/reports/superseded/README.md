# Superseded artifacts (kept for history; NOT authoritative)

These files were produced under the obsolete assumption that exactly 48 of the 128 archive recordings were the
validated references and that V01 had to select them. That assumption was corrected on 2026-09-30:
**all 128 recordings are researcher-validated reference recordings**; validation status is separate from vocabulary
mapping status, and a vocabulary item may own several reference recordings.

| File | Why kept |
|---|---|
| reference_selection_v0.1.csv | 128-row candidate table with blank "select 48" columns |
| reference_validation_checklist_v0.1.md | human checklist instructing a 48-item selection |
| reference_validation_confirmations_v0.1.csv | machine-readable companion of the checklist |
| vocabulary_v0.1_48_placeholder_rows.csv | W001–W048 placeholder rows with REF_W ids (replaced by evidence-based vocabulary.csv) |

Do not use any of these for corpus inclusion. The authoritative registry is `metadata/reference_recordings.csv`.
The remaining human input needed is `metadata/reference_mapping_input.csv` (item identity for unresolved recordings).
