# Rating protocol — RP1.0

1. Learner recordings are rated independently of, and before, any algorithm output.
   The validator (V01 unless the methodology is formally changed) must not see DTW, HMM,
   Cosine or any other algorithm score, ranking or visualisation while rating.
   Enforcement: `validation/ratings.csv` is checksummed and the dataset frozen before any
   `experiments/` folder is created; every experiment records the ratings checksum it used.
2. For each learner recording the validator first plays a validated reference recording of the same
   `word_id`, then the learner recording, immediately after. The exact `reference_recording_id` played is recorded
   on the rating row. Where an item owns several validated references, which one(s) the validator hears is an open
   methodology decision to be fixed before rating starts and applied uniformly.
   Replays are allowed. The validator sees the target text and ids only.
3. One main rating pass (`rating_pass = 1`) covering every included learner recording is required.
4. The rating is an integer 1–5 per `validation/rating_scale.md`.
5. If a recording cannot be rated (noise, wrong item, empty, corrupt), set
   `validation_status = unratable`, leave `human_rating` blank, and fill `unratable_reason`.
   The researcher then logs an exclusion in `manifests/exclusions.csv`.
6. `blind_confirmed = true` attests that no algorithm output was visible during the pass.
7. No Excellent / Good / Needs Improvement conversion occurs at this stage.
8. Optional intra-rater reliability (planned): after pass 1 is complete and frozen, approximately
   10% of included learner recordings are selected at random (seed recorded in the report) for a
   second blind pass by V01 with `rating_pass = 2`, without showing the pass-1 rating. Pass-2 rows
   never replace pass-1 rows; agreement is reported, not merged.
9. Playback order for pass 1 may be randomised per session; if so, the order file is kept under
   `validation/` and referenced in the report.

## ratings.csv columns

rating_id (RTnnnnnn), recording_id, word_id, speaker_id, reference_recording_id, validator_code,
rating_pass, human_rating, validation_status (rated | unratable | pending), unratable_reason,
blind_confirmed, rating_date (YYYY-MM-DD), rating_protocol_version, dataset_version, notes.
Uniqueness: one row per (recording_id, validator_code, rating_pass).
