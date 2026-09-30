# CHANGELOG — lumad_lingua_pronunciation

## v0.1 — 2026-09-30 — PRE-FREEZE (NOT the frozen experimental dataset)

Status: infrastructure only. No reference audio has been assembled yet. No learner
recordings exist. No human ratings exist. Nothing in this version may be used for
DTW / HMM / Cosine experiments.

Created:
- Directory structure, VERSION, README, this changelog.
- Schemas (header rows) for manifest, exclusions, ratings, audio_quality, participants, validators.
- metadata/vocabulary.csv with 48 pre-allocated target ids W001–W048 and reference ids
  REF_W001–REF_W048. All 48 rows are UNRESOLVED: the authoritative source objects in
  Supabase bucket `audio`, path `dataset`, could not be listed from the build environment
  (outbound host denied by network policy), and Firestore holds no audio link for any word.
- participants.csv with the reference speaker row R001 (code only).
- validators.csv with validator code V01 (code only).
- Candidate configs config/preprocessing/PP001.yaml and config/features/FE001.yaml.
  Both are CANDIDATES pending review of the real reference-audio probe.
- validation/rating_scale.md, rating_protocol.md, learner_collection_protocol.md.
- scripts/: fetch_reference_audio.py, export_firestore_metadata.py, probe_audio.py,
  checksums.py, build_manifest.py, check_dataset.py, new_participant.py.
- checksums/ for metadata and config (raw checksum list is empty because raw/ is empty).
- reports/reference_audio_audit_v0.1.md and reports/checks_report_v0.1.md.

Rules from this version onward:
- raw/ is write-once. Preprocessing writes only under processed/ and features/.
- A frozen version is never edited in place; corrections produce a new version and an entry here.
- v0.1 → v1.0 requires the freeze checklist in README.md to pass.

### v0.1 addendum — 2026-09-30 — source archive inventoried

- Source supplied as a manually uploaded `dataset.zip` (SHA-256 df4e62ca…218d89, 128 entries),
  declared to be a copy of Supabase `audio/dataset`. Extracted byte-for-byte to
  `staging/supabase_audio_dataset/` (CRC/size verified). Provenance in `staging/source_archive_provenance.json`.
- 128 WAV files (44.1 kHz, stereo, PCM16), 113 distinct base names, 12 variant groups, 0 corrupt,
  0 byte duplicates. Inventory in `metadata/source_objects.csv` and `metadata/source_audio_inventory.csv`.
- Mapping to the 48 validated references NOT established (0/48). Researcher-confirmation table
  written to `reports/reference_selection_v0.1.csv`. `raw/reference/` still empty.
- New script `scripts/inventory_source_archive.py`. Audit rewritten with real measurements.
- PP001 / FE001 remain candidates; see audit section 5 for recommended checks (mono strategy).

## v0.2 — 2026-09-30 — PRE-FREEZE — validated reference corpus corrected to 128 recordings

CORRECTION of the v0.1 model. All 128 recordings in the Supabase `audio/dataset` export are established,
researcher-validated reference recordings. The v0.1 assumption that exactly 48 references existed, that each
vocabulary item had exactly one reference, and that V01 had to "select 48" is obsolete.

Changes:
- New corpus contract `config/corpus.yaml` (expected_reference_recordings: 128, multiple references per item allowed).
- New canonical registry `metadata/reference_recordings.csv`: one row per physical recording, stable id `REF_001`–`REF_128`
  (assigned once by byte-wise sort of the original object name), full provenance (project, bucket, path, staged path,
  sha256), probe results, `validation_status = validated` for all, and a SEPARATE `mapping_status` (mapped | unresolved).
- `raw/reference/` populated with all 128 recordings byte-for-byte as `REF_nnn.WAV`; sha256 verified after copy.
- `metadata/vocabulary.csv` rebuilt as an evidence-based item table (`Wnnn`), rows only for items with at least one
  mapped recording; `reference_recording_ids` lists every validated reference for the item.
- `metadata/reference_mapping_input.csv`: the single human-input file for unresolved recordings.
- Manifest gains `mapping_status` and `variant_group_id`; all 128 reference rows `included_in_experiment = true`.
- `scripts/build_reference_registry.py` added; `fetch_reference_audio.py promote`, `build_manifest.py`,
  `check_dataset.py`, `inventory_source_archive.py`, `common.py` updated. `build_validation_checklist.py`
  moved to `scripts/superseded/`.
- Superseded 48-selection artifacts moved to `reports/superseded/` (kept for history, not authoritative).
- Protocol documents updated: learner items = vocabulary item list; a learner recording may be compared against every
  reference recording of its item (per-reference scores retained); no aggregation strategy chosen.
- PP001 / FE001 unchanged and still candidates; `config/preprocessing/OPEN_QUESTIONS.md` records what the next stage must test.

Status after v0.2: physical reference corpus COMPLETE (128/128); linguistic mapping INCOMPLETE (see checks report);
preprocessing protocol NOT frozen; experiment dataset NOT frozen.

### v0.2 addendum — 2026-09-30 — preprocessing protocol investigation PPINV001

- New shared implementation `pipeline/` (audio_io, preprocess, features; pipeline_version 0.1.0) used by scripts, tests and the future notebook.
- `experiments/PPINV001/` stereo/level/trim/resample/feature-sensitivity measurements for all 128 references (summary.json + CSVs).
- PP001 revised: channel_handling=average, 16 kHz soxr HQ, DC removal, PCM16, relative-to-peak trim mechanism FROZEN; normalisation and trim values PROVISIONAL (learner data). Overall status stays candidate.
- FE001 frozen as the common feature design contract (per-parameter rationale in the YAML); cross-checked against librosa 0.11.0.
- Noncanonical candidate outputs: processed/PP001-candidate (128 ok, deterministic) and features/PP001-candidate_FE001 (128 ok, frames 37–244, all finite).
- manifests/repro_manifest_v0.2.json; scripts run_preprocessing.py, extract_features.py, analyze_preprocessing.py, build_repro_manifest.py, test_pipeline.py (12 tests).
- Raw checksum list unchanged (sha256 4ba701e3…); config checksums regenerated.
