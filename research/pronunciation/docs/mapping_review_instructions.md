# Vocabulary mapping review — instructions (v0.2)

File to complete: `metadata/mapping_review_queue.csv` (97 cases, 112 recordings). One row = one linguistic case
(a filename group, possibly several takes). Everything except the decision columns is prefilled from project evidence.
Do not edit any other CSV. Do not rename, move or re-record audio. Listen from `raw/reference/REF_nnn.WAV`.

## Columns you fill
| Column | Allowed values |
|---|---|
| `decision` | CONFIRM_TEXT_NEW_ITEM · CONFIRM_CANDIDATE · SAME_AS · SPLIT · EXCLUDE · DEFER |
| `decision_target` | for CONFIRM_CANDIDATE when the candidate is ambiguous: a Firestore doc id or `Wnnn`; for SAME_AS: `RCnnn` (another case) or `Wnnn` |
| `authoritative_mansaka_text` | required for CONFIRM_TEXT_NEW_ITEM (the correct Mansaka spelling; the filename text is only a suggestion in `display_text_from_filename`) |
| `authoritative_translation_en` | optional English meaning |
| `takes_same_item` | Y or N; required when `n_recordings` > 1 (Y = all listed recordings are takes of the same item; N → use decision SPLIT) |
| `confirmed_by` | V01 or RESEARCHER |
| `confirmation_date` | YYYY-MM-DD |
| `notes` | required for EXCLUDE (why the recording is not a learner target) |

## Decisions
- **CONFIRM_TEXT_NEW_ITEM** — the recording(s) are one item; give its authoritative spelling. Typical for the 63 NO_PROJECT_MATCH and 14 PARTIAL_TOKEN_CANDIDATE cases.
- **CONFIRM_CANDIDATE** — the prefilled `candidate_*` record is the item (e.g. `madyaw na masurom` = Good morning from lesson 'Greetings 2').
- **SAME_AS** — this case is the same item as another case or an existing W id (use for spelling variants that are truly one item, e.g. RC074/RC075 if `pasaylowak`/`pasayluwak` are the same).
- **SPLIT** — the takes in a multi-take case are NOT the same item; the tool then creates one row per recording for a second pass.
- **EXCLUDE** — validated audio that should not be a learner target (reason in notes). The recording stays in the corpus.
- **DEFER** — leave for later; the case stays in the queue.

Cases: MULTIPLE_TAKE_CANDIDATE 12, SPELLING_VARIANT_CANDIDATE 6 (see `related_case_ids`), NORMALIZED_TEXT_CANDIDATE 1, VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE 1, MULTIPLE_CANDIDATES 0.
Return the completed `mapping_review_queue.csv`; nothing else is needed.
