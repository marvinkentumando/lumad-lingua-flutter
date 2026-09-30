# LUMAD LINGUA — Pronunciation Research Dataset

Version: see `VERSION` (currently `lumad_lingua_pronunciation_v0.1`, PRE-FREEZE).

This directory is the research dataset for the pronunciation-assessment experiment
(MFCC features; DTW, HMM and Cosine Similarity compared against independent human ratings).
It is deliberately kept **outside** the Flutter application repository. Audio must never be
copied into the app repository or its `assets/` folder.

## Layout

| Path | Purpose | Mutability |
|---|---|---|
| `raw/reference/` | All validated reference recordings `REF_001.<ext>` … `REF_128.<ext>` (count from `config/corpus.yaml`), byte-for-byte copies of the Supabase objects | write-once |
| `raw/learner/Sxxx/` | Learner recordings `Sxxx_Wyyy.<ext>` (retakes `Sxxx_Wyyy_T02.<ext>`) | write-once |
| `staging/` | Working copies (Supabase listing, Firestore export, downloaded objects under original names) used to build the mapping. Not part of the dataset proper | regenerable |
| `metadata/` | `reference_recordings.csv` (canonical registry, one row per validated recording), `vocabulary.csv` (items `Wnnn`, may own several references), `reference_mapping_input.csv` (human input for unresolved recordings), `participants.csv`, `validators.csv`, `audio_quality.csv`, `source_objects.csv`, `source_audio_inventory.csv` | edited by scripts / researcher |
| `manifests/` | `manifest.csv` (one row per raw recording), `exclusions.csv` | edited by scripts / researcher |
| `validation/` | Rating scale, rating protocol, learner collection protocol, `ratings.csv` | ratings written by V01 only |
| `config/corpus.yaml` | Corpus contract: expected reference count, id schemes, status vocabularies | versioned |
| `config/preprocessing/` | `PPnnn.yaml` audio-level preprocessing configs (candidates until frozen) + `OPEN_QUESTIONS.md` | versioned, append-only |
| `config/features/` | `FEnnn.yaml` MFCC configs | versioned, append-only |
| `processed/<PP>/` | Derived audio + `transformation_log.csv` | regenerable |
| `features/<PP>_<FE>/` | Derived MFCC arrays + `feature_log.csv` | regenerable |
| `experiments/<EXP>/` | Experiment outputs (Stage 3 and later) | immutable once written |
| `checksums/` | `SHA256SUMS_*` lists | regenerated at each freeze |
| `pipeline/` | Shared preprocessing/MFCC implementation (`audio_io`, `preprocess`, `features`); the future notebook imports this | versioned |
| `scripts/` | Reproducible tooling (Python 3.11, see `scripts/requirements.txt`) | versioned |
| `reports/` | Audit and check reports | append-only |

## Identifiers

- Reference recording: `REF_001`–`REF_128`, one per physical validated recording, assigned once and never reused.
- Vocabulary item: `Wnnn`, assigned only when a recording→item mapping is supported by evidence; one item may own several reference recordings. Filename groups (`VGnnn`) are working labels, not linguistic identity.
- Two independent statuses per recording: `validation_status` (all 128 are `validated`) and `mapping_status` (`mapped` | `unresolved`). An unresolved recording is a validated reference whose item identity is pending, never "unvalidated".
- Reference speaker: `R001`. Learners: `S001`, `S002`, … (3 digits, supports >10).
- Learner recording: `S001_W001`; retake for technical failure only: `S001_W001_T02`.
- Validator: `V01`. Preprocessing config: `PP001`. Feature config: `FE001`. Experiment: `EXP001_<slug>`.

## Pipeline (scripts)

```
python3 scripts/fetch_reference_audio.py list         # lists Supabase audio/dataset → staging + metadata/source_objects.csv
python3 scripts/fetch_reference_audio.py stage        # downloads every listed object byte-for-byte to staging/supabase_audio_dataset/
python3 scripts/inventory_source_archive.py <zip>     # OR: inventory a manually exported archive (byte-for-byte extract, probe, sha256, grouping)
python3 scripts/export_firestore_metadata.py          # read-only export of words/voice_submissions/lessons → staging/firestore_export
python3 scripts/build_reference_registry.py           # REF_nnn registry (all validated) + evidence-based vocabulary.csv + reference_mapping_input.csv
# researcher/V01 fill metadata/reference_mapping_input.csv for unresolved recordings, then re-run build_reference_registry.py
python3 scripts/fetch_reference_audio.py promote      # copies every registered recording to raw/reference/REF_nnn.<ext>, refuses to overwrite
python3 scripts/probe_audio.py                        # read-only probe → metadata/audio_quality.csv
python3 scripts/build_manifest.py                     # reference rows → manifests/manifest.csv
python3 scripts/checksums.py generate                 # checksums/SHA256SUMS_*_<version>.txt
python3 scripts/checksums.py verify
python3 scripts/check_dataset.py                      # reports/checks_report_<version>.md
python3 scripts/analyze_preprocessing.py              # PPINV001 measurements -> experiments/PPINV001/
python3 scripts/run_preprocessing.py --pp PP001 --candidate   # processed/PP001-candidate/ (+ transformation_log.csv); drop --candidate once PP001 is frozen
python3 scripts/extract_features.py --pp-tag PP001-candidate --fe FE001   # features/<pp>_<fe>/ (.npy + feature_log.csv)
python3 scripts/build_repro_manifest.py               # manifests/repro_manifest_<ver>.json
python3 scripts/test_pipeline.py                      # automated pipeline checks (needs numpy, scipy, soxr; librosa optional)
```

Readiness layers are tracked separately: (1) physical reference corpus, (2) linguistic mapping completeness, (3) preprocessing protocol (PP/FE) status, (4) experiment readiness. See `reports/checks_report_<ver>.md` and `CHANGELOG.md`.

Credentials: `fetch_reference_audio.py` reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from the environment or from `--env-file` (default `../lumad-lingua-flutter/.env`). It never prints them. `export_firestore_metadata.py` uses the public Firebase web client key parsed from `firebase_options.dart` (or `FIREBASE_WEB_API_KEY`). Both scripts are read-only against the backend: no upload, delete, rename, move or overwrite is ever issued.

## Freeze checklist (v0.1 → v1.0)

1. All `expected_reference_recordings` (128) present in `raw/reference/`, readable, `validation_status = validated`, sha256 verified, and every recording `mapping_status = mapped` to a `Wnnn` in `vocabulary.csv` (several recordings per item allowed).
2. Every enrolled learner intended for the experiment has one recording per vocabulary item accounted for (included, excluded with reason, or documented as not collected).
3. Every included learner recording has exactly one pass-1 rating in `validation/ratings.csv`.
4. `scripts/check_dataset.py --mode freeze` reports zero ERROR lines.
5. No duplicate ids; unreadable files excluded, never deleted; `exclusions.csv` complete.
6. `VERSION`, `CHANGELOG.md` and every `dataset_version` column agree.
7. `rating_scale.md` and `rating_protocol.md` unchanged since rating began.
8. PP and FE configs finalised and checksummed.
9. `scripts/checksums.py generate` run; list fingerprints recorded in `CHANGELOG.md`; `raw/` and `metadata/` set read-only; archive copy made.
10. Identity mapping and consent records confirmed absent from this tree.

## Privacy

No participant names, no validator name, no reference-speaker name, no demographics unless the
approved methodology requires a specific variable. The name→code mapping and consent forms live in a
separate restricted administrative folder that is never copied here, to Colab, or to any repository.
