# Pronunciation research (version-controlled part)

This directory holds the reproducible, non-sensitive part of the LUMAD LINGUA pronunciation research pipeline:
scripts, configuration, protocol documents and small metadata snapshots. It is deliberately separate from the
production Flutter code under `lib/` and adds no Flutter dependencies.

**The audio corpus is NOT in this repository.** The research dataset root (raw reference recordings, learner
recordings, processed audio, MFCC arrays, experiment outputs, staging exports) lives outside the repo, by default as
a sibling directory `../lumad_lingua_pronunciation/` (see `docs/DATASET_README.md`). `.gitignore` blocks audio,
`.npy`/`.npz` and any `raw/` or `staging/` folder under `research/`.

| Path | Content |
|---|---|
| `pipeline/` | Shared, documented implementation of preprocessing (PP) and MFCC features (FE): `audio_io.py`, `preprocess.py`, `features.py`. The dataset scripts, `scripts/test_pipeline.py` and the future Colab notebook import this package instead of re-implementing it. |
| `scripts/` | Canonical copy of the dataset tooling (Python 3.11, `requirements.txt`). Set `LLP_DATASET_ROOT` to point at the external dataset root, or run from a copy inside that root. Includes `analyze_preprocessing.py` (PPINV001), `run_preprocessing.py`, `extract_features.py`, `build_repro_manifest.py`, `test_pipeline.py`, and the mapping tools `resolve_vocabulary_mapping.py` (evidence inventory + review queue), `apply_mapping_review.py` (ingests the completed review), `dictionary_evidence.py` (Svelmoe 1990 lookups), `test_mapping.py`. |
| `config/corpus.yaml` | Corpus contract: 128 validated reference recordings, id schemes, status vocabularies |
| `config/preprocessing/PP001.yaml` | Preprocessing config with per-parameter status: channel averaging, 16 kHz soxr HQ, DC removal, PCM16 and the relative-peak trim mechanism are FROZEN; normalisation and trim values are PROVISIONAL (learner data). Overall status: candidate. |
| `config/features/FE001.yaml` | MFCC feature contract, FROZEN as the common design for DTW/HMM/Cosine (C1..C13, 25/10 ms, Hamming, 512 FFT, 26 HTK mel, 0–8 kHz). |
| `docs/` | Rating scale (1–5), rating protocol, learner collection protocol, exclusion reason codes, raw-audio rules, dataset README/CHANGELOG |
| `dataset_snapshot/v0.2/` | Text-only snapshot of the external dataset at `lumad_lingua_pronunciation_v0.2`: registry of the 128 recordings with SHA-256, vocabulary, manifest, checksum lists, reports, the PPINV001 measurements, the transformation and feature logs of the noncanonical `PP001-candidate` run, and `repro_manifest_v0.2.json`. No audio or feature matrices. Superseded 48-selection artifacts are under `reports/superseded/` for history only. |

Current state (v0.2, PRE-FREEZE): 128/128 validated reference recordings registered and hashed; 37/128 mapped to
vocabulary items by exact evidence from the Svelmoe & Svelmoe (1990) Mansaka Dictionary (headwords, alternate forms, example
sentences, finder), Firestore terms and published lesson items; 91 recordings await item confirmation in
`metadata/mapping_review_queue.csv` (76 grouped cases; see `docs/mapping_review_instructions.md`). The dictionary
transcriptions themselves stay outside the repository (private staging data; provenance hashes in
`dataset_snapshot/v0.2/reports/dictionary_provenance.json`). Preprocessing investigation PPINV001 is complete
(`dataset_snapshot/v0.2/reports/preprocessing_protocol_v0.2.md`); FE001 is frozen; PP001 keeps two provisional
parameter groups that need learner recordings. No DTW/HMM/Cosine experiment has been run. Production pronunciation
code in `lib/` is unchanged and is not the research implementation.

Run the pipeline tests: `LLP_DATASET_ROOT=/path/to/lumad_lingua_pronunciation python3 scripts/test_pipeline.py`.
