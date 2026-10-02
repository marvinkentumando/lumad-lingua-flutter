# Vocabulary mapping review — instructions (v0.2, dictionary-based re-analysis 2026-09-30)

> **Status 2026-10-02:** the 76-case queue was returned fully decided and applied (see reports/vocabulary_mapping_v0.2_review_applied.md). `metadata/mapping_review_queue.csv` is now empty. These instructions stay in force for any future row (a SPLIT, a correction, or recordings added in a later version).

File to complete: `metadata/mapping_review_queue.csv` — **76 cases covering 91 recordings** (down from 97 cases / 112
recordings before the Svelmoe & Svelmoe 1990 dictionary was available). One row = one linguistic case (a filename group,
possibly several takes). Everything except the decision columns is prefilled from the dictionary and project evidence.
Do not edit any other CSV. Do not rename, move or re-record audio. Listen from `raw/reference/REF_nnn.WAV`.

## What was resolved automatically (not in this file)
37 recordings are mapped on dictionary-supported evidence: exact headword (28), listed alternate
form (2: `madayaw, madyaw` is one headword), exact example sentence (4), finder entry
(1), plus the earlier Firestore-term (0), usage-example (0) and lesson (2) matches.

## Case types in this file
| evidence_category | cases | what the dictionary says | typical decision |
|---|---|---|---|
| MULTIPLE_TAKE_CANDIDATE | 12 | item prefilled where the dictionary/lesson resolves the text (e.g. `upat`→`opat` four, `turo`→`toro` three, `mangud`→`mangod`, `Pagarungan`→`pagarongan`, `madyaw na masurom`, `madyaw na gabila`, `Paroda`); only the take relationship needs you | `takes_same_item=Y` + CONFIRM_CANDIDATE (or CONFIRM_TEXT_NEW_ITEM when no candidate) |
| DICTIONARY_ORTHOGRAPHIC_VARIANT | 2 | headword differs only by the 1990 spelling rule **u → o** (`sampuro`/`samporo`, `ulloy`/`olloy`); `rule_tag` = `u->o` | CONFIRM_CANDIDATE (the recorded spelling is kept as `form_text`) |
| DICTIONARY_ROOT_CANDIDATE | 14 | the filename is an inflected form; only its root is a headword (`yagakanta`→`kanta` sing, `yakaan`→`kaan` eat, `yadaragan`→`daragan` run …); `dictionary_candidates` lists up to 3 roots | CONFIRM_TEXT_NEW_ITEM with the inflected form as `authoritative_mansaka_text` (correct spelling if needed) |
| PARTIAL_TOKEN_CANDIDATE | 26 | phrase not in the dictionary; `partial_token_matches` gives per-word glosses | CONFIRM_TEXT_NEW_ITEM (+ translation) |
| SPELLING_VARIANT_CANDIDATE | 4 | similar text in another case (`pasaylowak doon`/`pasayluwak doon`, `lumon na bobay`/`umpo na bobay`); `related_case_ids` links them | CONFIRM_TEXT_NEW_ITEM, or SAME_AS `RCnnn` if one item |
| VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE | 1 | `madyaw na allaw` = Good Day (approved community transcript; `allaw` = day in the dictionary) | CONFIRM_TEXT_NEW_ITEM |
| NO_PROJECT_MATCH | 17 | nothing in the dictionary, Firestore, lessons or app | CONFIRM_TEXT_NEW_ITEM (or EXCLUDE with reason) |

Rule-based shortcut: if you agree that the modern spelling `u` corresponds to the dictionary's `o` (`opat`=`upat`, `toro`=`turo`, `samporo`=`sampuro`, `ompo`=`umpo`), mark every row whose `rule_tag` is `u->o` (6 rows) as CONFIRM_CANDIDATE.

## Columns you fill
| Column | Allowed values |
|---|---|
| `decision` | CONFIRM_TEXT_NEW_ITEM · CONFIRM_CANDIDATE · SAME_AS · SPLIT · EXCLUDE · DEFER |
| `decision_target` | CONFIRM_CANDIDATE with several candidates: the headword form (e.g. `opat`) or an item key/`Wnnn`; SAME_AS: `RCnnn` or `Wnnn` |
| `authoritative_mansaka_text` | required for CONFIRM_TEXT_NEW_ITEM |
| `authoritative_translation_en` | optional |
| `takes_same_item` | Y / N, required when `n_recordings` > 1 (N → decision SPLIT) |
| `confirmed_by` / `confirmation_date` | V01 or RESEARCHER / YYYY-MM-DD |
| `notes` | required for EXCLUDE |

`gloss_conflict` is informational: for `madyaw na gabila` the published lesson says Good afternoon while the dictionary glosses `gabila` as dusk/evening; for `madyaw na masurom` the dictionary form is `masurum` (morning). Note the preferred gloss in `notes` if you wish.
Return the completed `mapping_review_queue.csv`; nothing else is needed.
