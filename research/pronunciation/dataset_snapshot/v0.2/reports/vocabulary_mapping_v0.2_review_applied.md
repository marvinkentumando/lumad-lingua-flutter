# Vocabulary mapping — human review applied — lumad_lingua_pronunciation_v0.2

Generated 2026-10-02. Follows reports/vocabulary_mapping_v0.2_dictionary.md. No audio touched; no algorithm run; all 128 validated recordings preserved; validation_status unchanged (128 × `validated`).

## 1. Input

| Item | Value |
|---|---|
| Submitted file | `validation/review_submissions/mapping_review_queue_completed_2026-10-02_as_submitted.csv` (byte copy of the upload, UTF-8 with BOM, Excel export) |
| Applied file | `validation/review_submissions/mapping_review_queue_completed_2026-10-02_normalized.csv` |
| Cases in file | 76 (exactly the 76 issued on 2026-09-30; none missing, none added) |
| Decisions | 76 / 76, all by `RESEARCHER`, dated `02/10/2026` |
| Evidence columns edited by the reviewer | 1 (RC073 `candidate_translation_en`: finder gloss `vegetable` overwritten with `Sweet Potato`) |

Normalisation applied before ingestion (nothing else changed):
- BOM removed; `confirmation_date` `02/10/2026` read as day/month/year and stored as ISO `2026-10-02` (the file was returned on that date).
- RC073: the reviewer's gloss was moved to `authoritative_translation_en` and the finder gloss restored in the evidence column, so the dictionary column keeps the source reading (`vegetable`) and `translation_en` carries the reviewer's (`Sweet Potato`); noted in the audit row.

## 2. Decisions

| Case type (as issued) | Cases | Decision |
|---|---|---|
| PARTIAL_TOKEN_CANDIDATE | 26 | CONFIRM_TEXT_NEW_ITEM (filename text confirmed) |
| NO_PROJECT_MATCH | 17 | CONFIRM_TEXT_NEW_ITEM (filename text confirmed) |
| DICTIONARY_ROOT_CANDIDATE | 14 | CONFIRM_TEXT_NEW_ITEM (inflected form; root gloss accepted as translation) |
| MULTIPLE_TAKE_CANDIDATE | 12 | 7 × CONFIRM_CANDIDATE, 5 × CONFIRM_TEXT_NEW_ITEM; `takes_same_item=Y` on all 12 |
| SPELLING_VARIANT_CANDIDATE | 4 | CONFIRM_TEXT_NEW_ITEM (kept as separate items; no SAME_AS) |
| DICTIONARY_ORTHOGRAPHIC_VARIANT | 2 | CONFIRM_CANDIDATE (`sampuro`→`samporo`, `ulloy`→`olloy`) |
| VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE | 1 | CONFIRM_TEXT_NEW_ITEM (`Madyaw na Allaw!` / `Good Day!`) |

No SPLIT, EXCLUDE, SAME_AS or DEFER decisions. Every CONFIRM_CANDIDATE target resolved to a dictionary headword (`svelmoe:hw:*`), the finder form (`svelmoe:finder:paroda`) or the published lesson item (`lesson_item:*`); none fell back to free text.

## 3. Result

| Quantity | Before | After |
|---|---|---|
| Recordings mapped | 37 / 128 | **128 / 128** |
| Vocabulary items | 36 | **112** (W001–W036 unchanged; W037–W112 new, allocated in case-id order from the ledger) |
| Items with more than one validated reference | 1 | **13** |
| Open review cases | 76 | **0** |
| Audit rows written (`metadata/mapping_audit_log.csv`) | 0 | 76 |

Evidence on the 128 registry rows: HUMAN_CONFIRMED 91 (mapping_evidence `researcher_confirmed`), DICTIONARY_HEADWORD_EXACT 17, EXACT_TERM_UNIQUE 11, EXACT_EXAMPLE_SENTENCE_UNIQUE 3, DICTIONARY_HEADWORD_ALTFORM 2, EXACT_LESSON_ITEM_UNIQUE 2, DICTIONARY_EXAMPLE_EXACT 1, DICTIONARY_FINDER_EXACT 1. Items: 67 words, 45 phrases.

Multi-reference items (all confirmed `takes_same_item=Y`): W025 `madayaw, madyaw` (2), W044 `duwambuok` (2), W059 `Madyaw na gabila` (2), W060 `Madyaw na masurom` (4), W066 `mangod` (2), W074 `nanang uram mayo` (2), W078 `pagarongan` (2), W081 `Paroda` (2), W086 `sining bapa mo` (2), W090 `toro` (2), W095 `opat` (3), W097 `Yaabay ko kamangun` (2), W109 `Yanag-aruk yang mangaysu` (2).

Human-confirmed items keyed to a dictionary headword (7: pagarongan, mangod, samporo, toro, olloy, opat, Paroda) carry the dictionary columns (entry ids, POS, definition, page) looked up from the key; `form_text` on each recording keeps the recorded spelling (`Pagarungan`, `mangud`, `sampuro`, `turo`, `ulloy`, `upat`).

Integrity: `check_dataset.py --verify-hashes` 47 PASS, 0 ERROR (Frozen-ready stays NO only because no learner data exists). Raw audio hash list unchanged. `test_mapping.py` and `test_pipeline.py` pass.

## 4. Points the researcher should be aware of (recorded, not altered)

1. **Translations are only as good as the submitted glosses.** 52 of 112 items have no English translation (the reviewer confirmed the Mansaka text only). The 14 inflected forms carry the *root's* dictionary definition verbatim as `translation_en` (e.g. `yagakanta` → "n Song. | v To sing."). Two of those roots look doubtful and deserve a second look before the item list is used for learner prompts: `yagasurat` → root `sorat` "Breech position of a fetus" (a `surat`/`sulat` "write" reading was not in the OCR), and `nangakaw` → root `akaw` "Stilt" (a `takaw` "steal" reading would also fit). Corrections go through a new review row or an edit to `authoritative_translation_en` in a resubmitted queue, never by editing vocabulary.csv by hand.
2. **Gloss conflicts carried, not resolved**: W059 `Madyaw na gabila` = "Good afternoon" (lesson) while the dictionary glosses `gabila` as dusk/evening; W060 `Madyaw na masurom` = "Good morning" while the dictionary spells the noun `masurum`; W015 `Madyaw na gabi` = "Good evening" vs dictionary "night". The reviewer's notes state the preferred glosses; `gloss_conflict` stays on the vocabulary rows.
3. **Spelling-variant pairs kept separate by decision**: `pasaylowak doon` (W082) and `pasayluwak doon` (W083); `lumon na bobay` (W053) and `umpo na bobay` (W092). They are distinct items with one reference each; an experiment that treats them as one target needs a SAME_AS decision first.
4. `Madyaw na Allaw!` (W058) was confirmed with the voice-submission capitalisation and exclamation mark; `form_text` keeps the filename form `madyaw na allaw`.
5. `Paroda` (W081): dictionary evidence is the English-finder listing under "vegetable" (p. 548); the "Sweet Potato" gloss is the reviewer's.
6. The 17 forms with no evidence anywhere (`amanting`, `baboo`, `dakurat`, `duor`, `isu`, `kamanggud`, `katumbar`, `kinuraw muuri`, `lutya`, `maanog`, `Magasogbo`, `madyaw na masurom kariko`, `marutuy`, `nangamang pak ng kayamas`, `pagsugbo`, `unom`, `yulugpat`) are now items on the reviewer's word alone (`human:RCnnn:*` keys, no translation).

## 5. Files

- `metadata/reference_recordings.csv` — 128 rows, all `mapped`
- `metadata/vocabulary.csv` — 112 items; `metadata/vocabulary_id_history.csv` — 112 ledger rows
- `metadata/reference_mapping_input.csv` — 91 confirmed rows (+ 37 evidence-mapped rows untouched)
- `metadata/mapping_audit_log.csv` — 76 decision rows (applied_on 2026-10-02)
- `metadata/mapping_review_queue.csv` — header only (nothing open)
- `validation/review_submissions/` — the submitted and the normalised queue
- `reports/superseded/mapping_review_queue_v0.2_dictionary_76cases_issued.csv` — the queue as issued
- `manifests/manifest.csv`, `checksums/` regenerated; `reports/checks_report_v0.2.md` refreshed
