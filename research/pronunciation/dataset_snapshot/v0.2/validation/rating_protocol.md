# Rating protocol — RP1.1 (finalised 2026-10-02 before any rating took place; supersedes RP1.0)

1. **Independence.** Learner recordings are rated before, and independently of, any algorithm output. The validator (V01
   unless the methodology is formally changed) never sees DTW, HMM, Cosine or any other score, ranking, prediction or
   production threshold. Enforcement: the rating package contains only ids, text and audio paths (column names are checked
   against a forbidden-term list and `package.json` records `algorithm_fields_present = false`); `validation/ratings.csv`
   is frozen and checksummed (`rating_tool.py freeze`) before any `experiments/` run exists; every experiment must cite the
   freeze record's `ratings_sha256`.
2. **Package.** `python3 scripts/rating_tool.py package --pass 1 --validator V01 --seed <int>` writes
   `validation/rating_packages/<package_id>/rating_order.csv`: every active learner take (highest take per item that is
   readable and not excluded) not yet rated by that validator, in an order randomised with `random.Random(seed)` across
   learners and items so that neither learner identity nor item order reveals a performance pattern. `package.json` stores
   the seed, selection rule, counts and the sha256 of the order file. Packages are immutable.
3. **Per recording, in package sequence:** the validator reads the Mansaka target (`word_id`, `mansaka_text`), plays the
   listed `reference_recording_id` — always the item's deterministic primary playback reference (`lowest_reference_id`,
   the same one learners heard; policy in `config/corpus.yaml`) — then plays the learner recording immediately after.
   Replays are allowed. For the 13 multi-reference items the validator does not choose among references; all references
   stay available for later algorithm evaluation, and no aggregation across them is defined here.
4. **Scale.** Integer 1–5 per `validation/rating_scale.md` (5 closely matches the validated reference … 1 substantially
   differs). No decimals, no ranges, no words. Ratings are never converted to Excellent / Good / Needs Improvement in the
   dataset; production tiers are calibrated only after algorithm selection, in a later stage.
5. **Unratable.** If a recording cannot be rated (noise, wrong item, empty, corrupt, several attempts in one file), set
   `validation_status = unratable`, leave `human_rating` blank and give `unratable_reason`. On ingestion an exclusion row
   (`UNRATABLE`, stage `validation`, decided_by = validator code) is created and the recording is excluded from the experiment.
6. **Blindness attestation.** `blind_confirmed = true` on every decided row attests that no algorithm output was visible.
7. **Ingestion.** `python3 scripts/rating_tool.py ingest validation/rating_packages/<package_id>` validates every filled
   row (integer 1–5 or unratable + reason; blind flag; ISO date; recording/word/speaker ids match the manifest; reference
   equals the item's primary playback reference; one rating per recording/validator/pass; nothing frozen) and appends to
   `validation/ratings.csv` with ids `RTnnnnnn`. Any error rejects the whole file; nothing is written. Rated recordings
   become `included_in_experiment = true`. Rows left blank stay pending and can be submitted later.
8. **Freeze.** `python3 scripts/rating_tool.py freeze --pass 1` refuses unless every active learner take has a pass-1
   decision, every unratable recording has an exclusion row, the take structure is consistent and the learner count meets
   the design minimum (10; `--allow-fewer-learners` records a deliberate smaller collection). It writes
   `validation/ratings_freeze_<ver>_pass1.json` (sha256 of ratings, targets, manifest, exclusions, PP/FE config files,
   package ids, counts) and sets `ratings.csv` read-only. Any later change invalidates the freeze and needs a new version.
9. **Optional intra-rater reliability (pass 2).** After the pass-1 freeze, `rating_tool.py package --pass 2 --seed <int>`
   draws `max(1, round(0.10 × n))` of the pass-1 *rated* recordings with `random.Random(seed).sample` (seed and sampled ids
   in `package.json`), shuffled, with the pass-1 rating withheld (the package carries no rating columns from pass 1 and
   `ratings.csv` is not shown to the validator). Pass-2 decisions are ingested into the separate file
   `validation/ratings_pass2.csv` (`rating_pass = 2`), validated against the sample, and frozen with `freeze --pass 2`.
   Pass-2 rows never replace pass-1 rows; agreement is computed later in the experiment stage, not here.
10. Validator identity: code only (`metadata/validators.csv`). V01 is the qualified native-speaker validator.

## ratings.csv / ratings_pass2.csv columns

rating_id (RTnnnnnn), recording_id, word_id, speaker_id, reference_recording_id, validator_code, rating_pass,
human_rating, validation_status (rated | unratable | pending), unratable_reason, blind_confirmed, rating_date
(YYYY-MM-DD), rating_protocol_version, dataset_version, notes.
Rules: human_rating ∈ {1,2,3,4,5} when rated, blank when unratable/pending; unratable requires a reason; one row per
(recording_id, validator_code, rating_pass); ids must match the manifest; reference_recording_id must belong to the rated
item and equal its primary playback reference; blind_confirmed must be true on every decided row.
