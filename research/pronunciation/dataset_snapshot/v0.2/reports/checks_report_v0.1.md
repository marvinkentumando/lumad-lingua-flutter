# Dataset integrity check — lumad_lingua_pronunciation_v0.1

Generated: 2026-09-30  Mode: `prefreeze`  Root: `/home/user/lumad_lingua_pronunciation`

| Status | Count |
|---|---|
| EXPECTED-NOT-YET-COLLECTED | 7 |
| INFO | 3 |
| PASS | 15 |

| Status | Check | Detail |
|---|---|---|
| INFO | dataset_version | lumad_lingua_pronunciation_v0.1 |
| PASS | schema:vocabulary.csv | required columns present |
| PASS | schema:manifest.csv | required columns present |
| PASS | schema:participants.csv | required columns present |
| PASS | vocabulary:W001–W048 coverage | 48 unique target ids |
| PASS | vocabulary:reference id pattern | REF_Wnnn matches word_id |
| EXPECTED-NOT-YET-COLLECTED | vocabulary:source object mapping | 48/48 unresolved: W001, W002, W003, W004, W005, W006 … |
| EXPECTED-NOT-YET-COLLECTED | vocabulary:reference validation status | 0/48 validated; statuses: {'pending_source_mapping': 48} |
| EXPECTED-NOT-YET-COLLECTED | vocabulary:mansaka_text | 48/48 rows have no Mansaka text (must come from validated source data, never invented) |
| PASS | participants:ids | 1 rows, unique, well-formed |
| PASS | participants:R001 | reference speaker present |
| EXPECTED-NOT-YET-COLLECTED | participants:learners | no learner enrolled yet (design expects ≥10) |
| PASS | validators:V01 | present |
| PASS | participants:no PII columns | ok |
| PASS | manifest:duplicate recording_id | 0 rows unique |
| EXPECTED-NOT-YET-COLLECTED | manifest:reference count | 0 reference rows (raw/reference/ empty) |
| PASS | manifest:files exist | 0 paths resolve |
| PASS | raw:orphan files | every raw file has a manifest row |
| INFO | audio_quality:coverage | no raw files to probe |
| INFO | exclusions | no exclusions logged |
| EXPECTED-NOT-YET-COLLECTED | learner recordings | none yet (expected ≥480 with 10 learners) |
| EXPECTED-NOT-YET-COLLECTED | ratings:coverage | no included learner recordings yet |
| PASS | dataset_version consistency | all rows agree with VERSION (lumad_lingua_pronunciation_v0.1) |
| PASS | checksums:lists present | SHA256SUMS_config_v0.1.txt, SHA256SUMS_metadata_v0.1.txt, SHA256SUMS_raw_v0.1.txt, SHA256SUMS_validation_v0.1.txt |
| PASS | checksums:verify lists | 15 entries verified |

EXPECTED-NOT-YET-COLLECTED = legitimately absent in the pre-freeze state; becomes ERROR in `--mode freeze`.
Frozen-ready: NO
