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
| `scripts/` | Canonical copy of the dataset tooling (Python 3.11, `requirements.txt`). Set `LLP_DATASET_ROOT` to point at the external dataset root, or run from a copy inside that root. |
| `config/corpus.yaml` | Corpus contract: 128 validated reference recordings, id schemes, status vocabularies |
| `config/preprocessing/PP001.yaml`, `config/features/FE001.yaml` | CANDIDATE preprocessing / MFCC configs, not frozen; `OPEN_QUESTIONS.md` lists what the next stage must test |
| `docs/` | Rating scale (1–5), rating protocol, learner collection protocol, exclusion reason codes, raw-audio rules, dataset README/CHANGELOG |
| `dataset_snapshot/v0.2/` | Text-only snapshot of the external dataset at `lumad_lingua_pronunciation_v0.2` (registry of the 128 recordings with SHA-256, vocabulary, manifest, checksum lists, reports). Superseded 48-selection artifacts are kept under `reports/superseded/` for history only. |

Current state (v0.2, PRE-FREEZE): 128/128 validated reference recordings registered and hashed; 11/128 mapped to
vocabulary items by exact Firestore dictionary-term evidence; 117 recordings await item confirmation in
`metadata/reference_mapping_input.csv`. No DTW/HMM/Cosine experiment has been run. Production pronunciation code
in `lib/` is unchanged and is not the research implementation.
