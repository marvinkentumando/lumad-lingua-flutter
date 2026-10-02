# Learner collection protocol — LC1.1 (finalised 2026-10-02; supersedes LC1.0)

Scope: collection and import of learner pronunciation recordings for the 112 authoritative items in
`metadata/learner_targets.csv` (generated from `metadata/vocabulary.csv` and `metadata/reference_recordings.csv` by
`scripts/build_learner_targets.py`; every item owns at least one researcher-validated reference recording). The target
list is never edited by hand and never derived from filenames.

## Participants

- Learners are `S001, S002, …` (3-digit codes in enrolment order; `scripts/new_participant.py Sxxx`, or `--enrol` at import).
  The design expects at least 10 learners; every learner attempts every eligible item (112).
- Nothing in the dataset encodes a name, school, sex, age, municipality, ethnicity or any other personal attribute:
  not in ids, filenames, folder names, session ids, notes or logs. The name→code list and consent forms live in the
  restricted administrative folder outside this tree (`consent_form_ref` in participants.csv is a code, not a document).

## Per target, in the session's item order

1. Show the authoritative Mansaka target: `word_id` and `mansaka_text` from `metadata/learner_targets.csv`. A translation may
   be shown for convenience only; use the `translation_status` column to label it *available*, *missing* or *flagged for
   linguistic review*. Never show a gloss as validated when it is flagged or missing; never invent one.
2. Play the item's **primary playback reference** `primary_playback_reference_id` (policy `lowest_reference_id`: the lowest
   `REF_nnn` among the item's validated references, fixed in the target list, identical for every learner, chosen without
   any learner or algorithm information). For the 13 multi-reference items all other references stay in the dataset and
   remain available for algorithm scoring; none is discarded or ranked.
3. The learner listens (replays allowed) and then records **one primary attempt**.
4. Save the raw recording as `Sxxx_Wnnn.<ext>` and move to the next item. Do not listen back to choose a "better" take,
   do not re-record because the pronunciation "sounded wrong", do not coach between attempts.

## Takes

- Exactly one primary attempt per (learner, item): id `Sxxx_Wnnn`, `take_number = 1`, no suffix (`_T01` is invalid).
- A retake `Sxxx_Wnnn_T02` (then `_T03`, …) is allowed **only** for a documented technical failure of the previous take:
  microphone/recorder failure, accidental interruption, truncated or empty recording, file corruption, severe environmental
  interference, or the wrong target shown. The failed take is kept in `raw/learner/`, logged in `manifests/exclusions.csv`
  (reason code, `stage = collection`, `recollection_recording_id = Sxxx_Wnnn_T02`), and the retake is imported separately.
  A retake without a prior take is rejected; a prior take without an exclusion row is reported by the integrity check and
  blocks the ratings freeze. Earlier takes are never overwritten or deleted. Repeated attempts to obtain the learner's best
  pronunciation are not permitted (that would bias the ground truth).

## Raw audio

- Accepted formats: lossless preferred (`wav`, `flac`); device formats accepted and preserved exactly as produced
  (`m4a`, `aac`, `mp4`, `3gp`, `ogg`, `opus`, `mp3`, `amr`). Learners and collectors never convert, trim, normalise,
  denoise or rename a recording; the research tooling does all preprocessing later from the untouched original.
- `raw/learner/Sxxx/` holds byte-for-byte copies, set read-only at import; sha256 verified after copy.
- Recorded per file at import (`metadata/audio_quality.csv`, `metadata/learner_import_log.csv`, `manifests/manifest.csv`):
  original filename, container, codec, sample rate, channels, bit depth, duration, size, sha256, import date,
  readable flag, collection session id, recording date.

## Delivery and import

Deliver one folder per learner (or one folder for a session) containing only the named files, e.g.
```
inbox/S001/S001_W001.wav … S001_W112.wav            (+ S001_W007_T02.wav if W007 failed technically)
inbox/S002/…
```
plus a short session note (session id `CSnn`, date, device class, environment class, and for each retake the failure reason).
Import: `python3 scripts/import_learner_audio.py --source inbox/S001 --speaker S001 --session CS01 --date YYYY-MM-DD [--enrol]`.
The importer validates ids (speaker enrolled, `word_id` in the target list, format accepted), refuses duplicates and
overwrites, imports unreadable files flagged `readable=false`, logs everything, rebuilds the manifest, recomputes
checksums, writes `metadata/learner_collection_status.csv` / `reports/learner_collection_status_<ver>.md` (missing items,
duplicates, retakes, unreadable, excluded per learner) and reruns `check_dataset.py`. Missing items are reported, never
fabricated; a learner may end with fewer than 112 usable recordings when technical exclusions are documented.

## Order of stages (never merged)

collection/import → technical QC (`check_dataset.py`, exclusions) → blind human rating (RP1.1) → ratings freeze →
algorithm experiments (DTW / HMM / Cosine, later notebook) → production calibration. No algorithm is run, and no
Excellent/Good/Needs Improvement tier is defined, before the ratings freeze record exists.
