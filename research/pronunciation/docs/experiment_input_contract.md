# Experiment input contract (future DTW / HMM / Cosine notebook) — defined 2026-10-02, no algorithm implemented

The notebook loads the dataset only through `pipeline/dataset_interface.py`:

```python
from pipeline.dataset_interface import load_experiment_inputs, summary
d = load_experiment_inputs(DATASET_ROOT)      # raises DatasetNotFrozen unless every condition below holds
```

`load_experiment_inputs` refuses (and the notebook must not continue) unless:

1. `metadata/learner_targets.csv` exists (112 items; identity = `word_id` + `mansaka_text` + validated reference audio).
2. `validation/ratings_freeze_<ver>_pass1.json` exists and its recorded sha256 values still match `validation/ratings.csv`,
   `metadata/learner_targets.csv`, `manifests/manifest.csv`, `manifests/exclusions.csv` and the PP/FE config files.
3. `config/preprocessing/PP001.yaml` has `status: frozen` (its provisional normalisation/trim/lossy-decoding values must be
   fixed on real learner audio first; a changed value means a new PP id). `require_frozen_pp=False` exists for development only.

Returned keys: `version`, `corpus`, `targets`, `references` (128 rows with sha256 and raw paths), `reference_relationships`
(`word_id` → all validated `reference_recording_ids`, `primary_playback_reference_id`, raw paths — every reference of a
multi-reference item is available; how scores across them are aggregated is an experiment decision recorded in the experiment,
never in the dataset), `learner_manifest`, `learner_included`, `learner_excluded`, `learner_pending`, `exclusions`,
`ratings_pass1`, `ratings_pass1_by_recording`, `ratings_pass2`, `ratings_freeze`, `pp_config`, `fe_config`,
`pp_config_hash`, `fe_config_hash`, `readiness_problems`.

Obligations of the notebook: record `ratings_freeze.ratings_sha256`, `pp_config_hash`, `fe_config_hash`, `pipeline.PIPELINE_VERSION`
and the dataset version in its output; use only `learner_included` recordings; compare algorithm scores against
`ratings_pass1` (`human_rating` 1–5); report pass-2 agreement separately; never write into `raw/`, `metadata/`, `manifests/`
or `validation/`; never convert ratings into Excellent / Good / Needs Improvement inside the dataset.

Freeze criteria enforced by `rating_tool.py freeze` and `check_dataset.py --mode freeze`: target list present and consistent
with vocabulary; learner ids valid and enrolled; raw learner files preserved (sha256 lists, read-only); technical QC complete
(every unreadable/superseded take excluded with a reason); mapping complete (128/128); pass-1 decision for every active learner
recording; unratable recordings excluded; ratings checksum frozen; PP/FE versions recorded in `manifests/repro_manifest_<ver>.json`.
