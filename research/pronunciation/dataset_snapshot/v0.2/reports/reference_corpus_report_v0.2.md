# Validated reference corpus report — lumad_lingua_pronunciation_v0.2 (PRE-FREEZE)

Generated 2026-09-30. Supersedes the mapping section of reference_audio_audit_v0.1.md (the technical measurements there remain valid).

## 1. Corpus (physical layer) — COMPLETE

| Item | Value |
|---|---|
| Validated reference recordings (config/corpus.yaml) | expected 128 / registered 128 / in raw/reference 128 |
| Recording id scheme | REF_001–REF_128, assigned once by byte-wise sort of original object name; raw file = `raw/reference/REF_nnn.WAV` |
| validation_status | {'validated': 128} (validator code V01; provenance: Supabase export declared validated by the researcher, 2026-09-30) |
| Byte-identical duplicates | 0 (128 distinct SHA-256) |
| Readable | 128/128; all RIFF WAVE PCM16, 44,100 Hz, 2 ch; durations 0.534–2.786 s |
| Checksums | `checksums/SHA256SUMS_raw_v0.2.txt` (128 entries) + metadata/config/validation lists; verified |

## 2. Provenance

| Field | Value | Independently verified? |
|---|---|---|
| Supabase project | ovdwgowtnlujnbcyldkk | declared by the researcher; live bucket unreachable from the build environment (network policy) |
| Bucket / path | audio / dataset/<object_name> | declared; recorded per recording in `source_storage_path` |
| Delivery | dataset.zip, 20255997 bytes, sha256 df4e62cadd972f04a614b3ccc1f634f18b0a6269803b22c913d4f32fea218d89, 128 entries | archive hash computed locally; CRC32/size of every entry verified on extraction |
| Public object URLs | not recorded (`source_public_url_verified = false`); would be `https://<project>.supabase.co/storage/v1/object/public/audio/dataset/<object_name>` by the app's convention, but no URL was fetched, so none is asserted | no |
| Staged copies | `staging/supabase_audio_dataset/<original name>` (original filenames preserved) | sha256 equals registry and raw copy |

## 3. Vocabulary mapping (linguistic layer) — INCOMPLETE

| Item | Value |
|---|---|
| Recordings mapped to a vocabulary item | 11 / 128 (evidence: exact, unique Firestore dictionary-term match; all single-word nouns) |
| Recordings unresolved (validated audio, item identity pending) | 117 / 128 |
| Vocabulary items established (Wnnn) | 11 (W001–W011); authoritative total item count NOT determinable yet |
| Filename groups (VG, working labels only) | 113 groups; 12 groups with >1 recording (27 recordings) |
| Items with >1 validated reference | 0 so far (the model allows it; the 12 multi-take filename groups are all unresolved and will produce multi-reference items once confirmed) |

Mapped items: W001=antik (REF_001), W002=arabat (REF_002), W003=arayon (REF_036), W004=bapa (REF_038), W005=barangaw (REF_003), W006=batad (REF_039), W007=bobay (REF_004), W008=bugsak (REF_005), W009=kadyawan (REF_011), W010=karapi (REF_052), W011=kimod (REF_054).

Multi-take filename groups awaiting confirmation: duwambuok → REF_043, REF_044; madyaw na gabila → REF_066, REF_067; madyaw na masurom → REF_069, REF_070, REF_071, REF_072; mangud → REF_076, REF_077; nanang uram mayo → REF_084, REF_085; pagarungan → REF_020, REF_089; paroda → REF_022, REF_092; sining bapa mo → REF_100, REF_101; turo → REF_107, REF_108; upat → REF_113, REF_114, REF_115; yaabay ko kamangun → REF_027, REF_028; yanag-aruk yang mangaysu → REF_031, REF_032.

Spelling/identity cases deliberately NOT merged (separate filename groups; identity to be decided by V01): `pasaylowak doon` (REF_093) vs `pasayluwak doon` (REF_094); `madyaw` (REF_015) vs `madayaw` (REF_063); `madyaw na gabi` (REF_065) vs `madyaw na gabila` (REF_067); `lumon na bobay` (REF_058) vs `umpo na bobay` (REF_110).

## 4. Smallest human input required

File: `metadata/reference_mapping_input.csv` (117 rows, one per unresolved recording). For each row fill EITHER `firestore_word_doc_id` (preferred, when the item exists in the dictionary) OR `word_id` of an already-established item OR `same_item_as_recording_id` (another recording of the same item) plus `mansaka_text`, then `confirmed_by` (V01 or RESEARCHER) and `confirmation_date`. Re-run `scripts/build_reference_registry.py`, `build_manifest.py`, `checksums.py generate`, `check_dataset.py`. No audio decisions are needed for this step.

## 5. Readiness

| Layer | Status |
|---|---|
| Reference validation | COMPLETE (128/128 validated) |
| Authoritative vocabulary mapping | INCOMPLETE (11/128 recordings, 11 items) |
| Preprocessing protocol (PP001/FE001) | CANDIDATE, not frozen; open questions in config/preprocessing/OPEN_QUESTIONS.md; can be investigated now on the 128 references |
| Learner collection | NOT READY: item list (vocabulary) must be complete first |
| DTW/HMM/Cosine experiment | NOT READY: needs mapping, frozen PP/FE, learner recordings and ratings |
