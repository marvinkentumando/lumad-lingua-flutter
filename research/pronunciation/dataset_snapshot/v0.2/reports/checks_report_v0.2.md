# Dataset integrity check — lumad_lingua_pronunciation_v0.2

Generated: 2026-09-30  Mode: `prefreeze`  Root: `/home/user/lumad_lingua_pronunciation`

| Status | Count |
|---|---|
| EXPECTED-NOT-YET-COLLECTED | 4 |
| INFO | 6 |
| PASS | 48 |

| Status | Check | Detail |
|---|---|---|
| INFO | dataset_version | lumad_lingua_pronunciation_v0.2 |
| INFO | corpus contract | expected_reference_recordings=128, multiple_references_per_item=True |
| PASS | schema:reference_recordings.csv | required columns present |
| PASS | schema:vocabulary.csv | required columns present |
| PASS | schema:manifest.csv | required columns present |
| PASS | schema:participants.csv | required columns present |
| PASS | registry:recording_id unique & well-formed | 128 ids REF_nnn |
| PASS | registry:validated reference count | 128 registered, expected 128 |
| PASS | registry:object_name unique | ok |
| PASS | registry:sha256 unique | no byte-identical recordings |
| PASS | registry:validation_status | all 128 recordings validated (provenance: Every recording in the Supabase export of project ovdwgowtnl…) |
| PASS | registry:mapping_status values | all in {mapped, unresolved} |
| PASS | registry:mapping_evidence for mapped rows | ok |
| EXPECTED-NOT-YET-COLLECTED | registry:vocabulary mapping | 112/128 recordings unresolved (validated audio, item identity pending); 16 mapped |
| PASS | registry:mapping input rows for unresolved | 117 rows in reference_mapping_input.csv |
| PASS | registry:canonical raw copy | all 128 present in raw/reference/ |
| PASS | registry:raw filename == recording_id | ok |
| PASS | registry:readable | all readable |
| PASS | registry↔source_objects provenance | 128 source objects, hashes agree |
| PASS | source_objects:count | 128 (expected 128) |
| PASS | registry:raw bytes match sha256 | 128 files re-hashed OK |
| PASS | raw/reference:orphan files | none |
| PASS | evidence:coverage | 128 evidence rows for 128 recordings |
| PASS | evidence:categories valid | ok |
| PASS | evidence:no candidate/take auto-promotion | authoritative rows are exact, unsuffixed matches only |
| PASS | registry:mapped rows carry authoritative/human evidence | 16 mapped rows ok |
| INFO | evidence:category counts | {'EXACT_TERM_UNIQUE': 11, 'NO_PROJECT_MATCH': 63, 'PARTIAL_TOKEN_CANDIDATE': 14, 'EXACT_EXAMPLE_SENTENCE_UNIQUE': 3, 'SPELLING_VARIANT_CANDIDATE': 6, 'MULTIPLE_TAKE_CANDIDATE': 27, 'NORMALIZED_TEXT_CANDIDATE': 1, 'VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE': 1, 'EXACT_LESSON_ITEM_UNIQUE': 2} |
| PASS | review queue ↔ unresolved recordings | 97 cases cover 112 recordings; unresolved 112 |
| PASS | review queue:decisions parse | no invalid decisions |
| PASS | id ledger:unique | 16 ids recorded |
| PASS | id ledger:vocabulary ids recorded | all vocabulary ids in vocabulary_id_history.csv |
| PASS | id ledger:ids never reassigned | item_key per id stable |
| PASS | vocabulary:word_id unique & well-formed | 16 items |
| PASS | vocabulary:firestore_word_doc_id unique | ok |
| PASS | vocabulary:mansaka_text present | all items have text from source data |
| PASS | registry→vocabulary word_id exists | ok |
| PASS | vocabulary↔registry reference lists | reference_recording_ids and counts agree |
| INFO | vocabulary:items with multiple validated references | none yet |
| INFO | filename variant groups | 113 groups (not linguistic identity); groups containing >1 distinct mapped item: 0 |
| PASS | participants:ids | 1 rows |
| PASS | participants:R001 | reference speaker present |
| EXPECTED-NOT-YET-COLLECTED | participants:learners | none enrolled yet (design expects ≥10) |
| PASS | validators:V01 | present |
| PASS | participants:no PII columns | ok |
| PASS | manifest:recording_id unique | 128 rows |
| PASS | manifest:reference rows | 128 = registry = corpus |
| PASS | manifest↔registry consistency | ids, sha256, speaker, status and mapping agree |
| PASS | manifest:no accidental reference exclusion | every reference row included or explicitly excluded |
| PASS | manifest:files exist | 128 paths resolve |
| PASS | raw:orphan files (all tiers) | every raw file has a manifest row |
| PASS | audio_quality:coverage | 128 probed |
| PASS | manifest:no unreadable included | ok |
| INFO | exclusions | none logged |
| EXPECTED-NOT-YET-COLLECTED | learner recordings | none yet; item list not final until mapping is complete (16 items mapped so far) |
| EXPECTED-NOT-YET-COLLECTED | ratings:coverage | no included learner recordings yet |
| PASS | dataset_version consistency | all rows agree with VERSION (lumad_lingua_pronunciation_v0.2) |
| PASS | checksums:lists for current version | SHA256SUMS_config_v0.2.txt, SHA256SUMS_metadata_v0.2.txt, SHA256SUMS_raw_v0.2.txt, SHA256SUMS_validation_v0.2.txt |
| PASS | checksums:verify lists | 152 entries verified |

EXPECTED-NOT-YET-COLLECTED = legitimately absent in the pre-freeze state; becomes ERROR in `--mode freeze`.
Frozen-ready: NO
