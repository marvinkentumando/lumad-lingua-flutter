# Learner collection protocol — LC1.0

Participants: learners S001, S002, … (3-digit codes; more than 10 supported). Each learner is
expected to record every vocabulary item in `metadata/vocabulary.csv` (item list is final only once every
reference recording in `metadata/reference_recordings.csv` is mapped; do not start collection before that). The name→code mapping and consent forms are kept in
the restricted administrative folder, never in this dataset.

## Per target (in the session's item order)

1. Display the target Mansaka word/phrase (from `metadata/vocabulary.csv`, by `word_id`).
2. Play a validated reference recording of the item (`REF_nnn`, from the item's `reference_recording_ids`). If the item owns several references, the session protocol must fix which one is played and record its id per item; this choice is an open methodology decision and must not vary between learners.
3. Allow the learner to listen (replays allowed before recording).
4. Record ONE primary learner pronunciation attempt.
5. Save it as `raw/learner/Sxxx/Sxxx_Wnnn.<ext>` (original format, untouched).
6. Move to the next item.

## Takes

- One primary attempt per (learner, target) is retained (`take_number = 1`, unsuffixed id).
- A retake is permitted only for technical collection failure: recording failed, corrupt audio,
  severe interruption, or the wrong target was accidentally presented. The failed take is kept,
  logged in `manifests/exclusions.csv`, and the retake is saved as `Sxxx_Wnnn_T02.<ext>`
  (`take_number = 2`, `recollection_recording_id` set on the exclusion row).
- Repeated attempts to select the learner's best pronunciation are NOT permitted unless the
  research methodology is explicitly changed and the change is recorded in CHANGELOG.md.

## Session record

Per session, record a `collection_session_id` (e.g. CS01), date (YYYY-MM-DD), `device_class`
and `environment_class` where consistently available. Do not add demographics.
Use `scripts/new_participant.py Sxxx` to create the learner directory and participants row.
After each session: run `scripts/probe_audio.py`, `scripts/build_manifest.py`,
`scripts/checksums.py generate`, `scripts/check_dataset.py`.
