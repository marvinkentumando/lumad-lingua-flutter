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

### v0.2 addendum — 2026-09-30 — vocabulary mapping evidence resolution

- New `metadata/mapping_evidence.csv` (128 rows, evidence category per recording), `metadata/mapping_review_queue.csv`
  (97 linguistic cases / 112 recordings), `metadata/vocabulary_id_history.csv` (append-only id ledger),
  `metadata/mapping_audit_log.csv` (written by apply_mapping_review.py), `validation/mapping_review_instructions.md`.
- Mapped 16/128 recordings to 16 items (W001–W011 unchanged; W012–W016 new: 3 dictionary usage-example phrases, 2 published-lesson items).
- Registry gains `evidence_category` and `item_key`; vocabulary gains `item_key`, `source_field`, `evidence_category`.
- Scripts: resolve_vocabulary_mapping.py, apply_mapping_review.py, mapping_common.py, test_mapping.py; build_reference_registry.py and
  check_dataset.py extended (evidence validity, no candidate/take promotion, queue ↔ unresolved consistency, ledger stability).
- Multi-take groups remain candidates (0 multi-reference items declared); spelling variants kept separate. See reports/vocabulary_mapping_v0.2.md.

### v0.2 addendum — 2026-09-30 — complete dictionary integrated into vocabulary mapping

- Svelmoe & Svelmoe (1990) Mansaka Dictionary supplied as two OCR transcriptions; preserved byte-for-byte in `staging/dictionary/`
  (sha256 in provenance.json) and flattened to entries/examples/finder CSVs. New `scripts/dictionary_evidence.py`.
- Mapping re-run over all 128 recordings: 37 mapped (was 16), 36 items (W001–W016 unchanged, W017–W036 new), 1 multi-reference item
  (W025 `madayaw, madyaw`). Review queue reduced from 97 cases/112 recordings to 76 cases/91 recordings; old queue archived under reports/superseded/.
- Registry gains `form_text`; vocabulary gains alternate_forms and dictionary_* columns; gloss conflicts recorded (lesson vs dictionary).
- Report: reports/vocabulary_mapping_v0.2_dictionary.md.

### v0.2 addendum — 2026-10-02 — human review applied: mapping complete

- Completed review queue returned by the researcher (76/76 cases decided, 2026-10-02); kept byte-for-byte under
  `validation/review_submissions/` together with the normalised copy that was ingested (BOM removed, date → ISO,
  one reviewer gloss moved from an evidence column to `authoritative_translation_en`).
- `apply_mapping_review.py`: 91 recordings mapped, 76 new items W037–W112; 128/128 recordings now mapped, 112 items,
  13 items with several validated references (all `takes_same_item=Y`), 0 open cases. Audit rows in `metadata/mapping_audit_log.csv`.
- Script fixes found by this run: a bare headword in `decision_target` now resolves through the dictionary (key `svelmoe:hw:*`)
  instead of being treated as a Firestore doc id; the canonical queue is always rewritten at `metadata/mapping_review_queue.csv`
  even when decisions are read from another file; human-confirmed items keyed to a dictionary headword/finder form get the
  dictionary columns filled from the key.
- Open points (translations missing on 52 items; two doubtful root glosses; gloss conflicts) listed in
  reports/vocabulary_mapping_v0.2_review_applied.md. Raw audio and validation status unchanged.

### v0.2 addendum — 2026-10-02 — learner collection and human ground-truth infrastructure prepared (no learner data yet)

- `metadata/learner_targets.csv` (112 items, TL-0.2) generated from vocabulary.csv + reference_recordings.csv by
  `scripts/build_learner_targets.py`: word_id, Mansaka text, item type, references (128/128 represented, 13 multi-reference),
  deterministic primary playback reference (`lowest_reference_id`, config/corpus.yaml), provenance, collection eligibility
  (112/112) and translation metadata (41 available, 19 flagged, 52 missing; 71 need linguistic review; none corrected or invented).
  `metadata/translation_review_flags.csv` holds the 5 open flags from the applied review (2 doubtful root glosses, 3 lesson/dictionary conflicts).
- Protocols finalised before any data exists: LC1.1 (validation/learner_collection_protocol.md), RP1.1 (validation/rating_protocol.md);
  corpus.yaml gains `learner_collection` and `human_rating` contracts (ids Sxxx / Sxxx_Wnnn[_Tnn], accepted formats, minimum 10 learners,
  rating reference policy, pass-2 fraction 0.10).
- New scripts: `import_learner_audio.py` (write-once import with id/format/enrolment/target validation, duplicate and overwrite refusal,
  retake rules, sha256, probe, `metadata/learner_import_log.csv`, manifest/status/checksums/check refresh), `learner_collection_status.py`
  (per-learner completeness -> metadata/learner_collection_status.csv + reports/learner_collection_status_<ver>.md), `rating_tool.py`
  (blind randomised rating packages with recorded seed, validated ingestion into validation/ratings.csv / ratings_pass2.csv, freeze
  record validation/ratings_freeze_<ver>_pass<k>.json), `learner_common.py`; `pipeline/dataset_interface.py` = loader contract for the
  future notebook (refuses unfrozen or modified data). build_manifest.py fills learner reference ids; check_dataset.py checks targets,
  take consistency, rating rules, freeze integrity. `scripts/test_learner_rating.py` (13 tests on temporary fixtures).
- No learner recording, participant or rating exists. No DTW/HMM/Cosine code. Raw audio and validation status unchanged.
