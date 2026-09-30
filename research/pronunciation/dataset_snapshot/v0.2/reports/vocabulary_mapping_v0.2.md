# Vocabulary mapping resolution — lumad_lingua_pronunciation_v0.2

Generated 2026-09-30 from `metadata/mapping_evidence.csv`, `metadata/mapping_review_queue.csv` and the registry. No audio was touched; no algorithm was run.

## 1. Sources searched

| Source | Records | Use |
|---|---|---|
| Firestore `words` export (staging) | 2000 documents, 1,734 distinct terms (229 terms have duplicate documents) | exact term match; usage-example sentences (4084 lines); definitions (substring, candidate only) |
| Firestore `lessons` export | 4 lessons, 29 tasks; 24 published vocabulary/matching/MCQ/reordering items with meanings | exact item match with meaning |
| Firestore `voice_submissions` export | 30 submissions, 8 with transcripts | transcript match (candidate only: community content) |
| Flutter repository sources/assets | 247 Dart/JSON/CSV/ARB files | supporting hits only (quiz mock: Ina=Mother, Ama=Father; duel fallback greetings); `bulk_audio_import_modal.dart` documents the project convention *audio filename stem == dictionary term*, which underpins EXACT_TERM_UNIQUE |
| Flutter `words.audioUrl` / `audioPath` | 0 non-empty on all 2,000 words | no audio identity evidence exists in Firestore |
| Supabase object paths | 128 objects `dataset/<name>.WAV` | provenance only; no record references them |
| Existing research metadata | registry, vocabulary v0.2 (W001–W011) | preserved |

## 2. Results

| Quantity | Value |
|---|---|
| Validated recordings | 128 |
| Previously mapped | 11 |
| Newly mapped (authoritative evidence) | 5 |
| Mapped after this stage | 16 |
| Unresolved recordings | 112 |
| Vocabulary items | 16 (W001–W016) |
| Review cases | 97 (covering 112 recordings) |

Evidence categories by recording: EXACT_EXAMPLE_SENTENCE_UNIQUE 3, EXACT_LESSON_ITEM_UNIQUE 2, EXACT_TERM_UNIQUE 11, MULTIPLE_TAKE_CANDIDATE 27, NORMALIZED_TEXT_CANDIDATE 1, NO_PROJECT_MATCH 63, PARTIAL_TOKEN_CANDIDATE 14, SPELLING_VARIANT_CANDIDATE 6, VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE 1.

Newly established items: W012 `Gaagod yang baboy.` (A pig is moaning.; EXACT_EXAMPLE_SENTENCE_UNIQUE; REF_008); W013 `Kaana yang manok.` (Eat the chicken.; EXACT_EXAMPLE_SENTENCE_UNIQUE; REF_010); W014 `Madakmul yang abol.` (The blanket is thick.; EXACT_EXAMPLE_SENTENCE_UNIQUE; REF_014); W015 `Madyaw na gabi` (Good evening; EXACT_LESSON_ITEM_UNIQUE; REF_065); W016 `Saramat` (Thank you; EXACT_LESSON_ITEM_UNIQUE; REF_099).

Policy: a recording is auto-mapped only when its unsuffixed filename stem equals exactly one dictionary term, one dictionary usage-example sentence, or one published-lesson item with an agreed meaning. Recordings with an explicit take suffix `(n)` are never auto-mapped; their groups are MULTIPLE_TAKE_CANDIDATE cases even when the base text has authoritative evidence (`madyaw na masurom` ×4 and `madyaw na gabila` ×2 are prefilled with lesson evidence and need a one-line confirmation). Stable ids: W001–W011 unchanged; W012–W016 allocated in deterministic order and recorded in `metadata/vocabulary_id_history.csv` (append-only, backfilled for W001–W011).

## 3. Multiple references

Authoritative multi-reference items: 0 (all 12 multi-take groups await confirmation). Groups and evidence:

- RC069 `Pagarungan`: REF_020;REF_089 — no project record; identity from filename only
- RC073 `Paroda`: REF_022;REF_092 — no project record; identity from filename only
- RC098 `Yaabay ko kamangun`: REF_027;REF_028 — no project record; identity from filename only
- RC110 `Yanag-aruk yang mangaysu`: REF_031;REF_032 — no project record; identity from filename only
- RC018 `duwambuok`: REF_043;REF_044 — no project record; identity from filename only
- RC048 `madyaw na gabila`: REF_066;REF_067 — candidate Madyaw na gabila / Good afternoon (lessons:6pXuOdANtl5dST82kBLe;HbXBeytkOIijuP0L81VC)
- RC049 `madyaw na masurom`: REF_069;REF_070;REF_071;REF_072 — candidate Madyaw na masurom / Good morning (lessons:6pXuOdANtl5dST82kBLe;HbXBeytkOIijuP0L81VC)
- RC056 `mangud`: REF_076;REF_077 — no project record; identity from filename only
- RC065 `nanang uram mayo`: REF_084;REF_085 — no project record; identity from filename only
- RC082 `sining bapa mo`: REF_100;REF_101 — no project record; identity from filename only
- RC088 `turo`: REF_107;REF_108 — no project record; identity from filename only
- RC093 `upat`: REF_113;REF_114;REF_115 — no project record; identity from filename only

## 4. Variant investigation

### pasaylowak doon / pasayluwak doon
- `pasaylowak doon` → RC074 (SPELLING_VARIANT_CANDIDATE; recordings REF_093; candidate '' / ''; tokens —)
- `pasayluwak doon` → RC075 (SPELLING_VARIANT_CANDIDATE; recordings REF_094; candidate '' / ''; tokens —)
- Project evidence: no dictionary term or example contains either form; published lesson 'Common Expressions 1' has `Pasaylowa ako` = Sorry (same root, different form). Same/different item NOT established; the `w`/`u` spelling difference is a letter difference, not normalisation. Human confirmation required (two cases cross-linked as related).
### madyaw / madayaw
- `madyaw` → RC045 (SPELLING_VARIANT_CANDIDATE; recordings REF_015; candidate '' / ''; tokens —)
- `madayaw` → RC044 (SPELLING_VARIANT_CANDIDATE; recordings REF_063; candidate '' / ''; tokens —)
- Project evidence: neither form is a dictionary term; `Madyaw` appears in a DRAFT lesson word-hunt (ignored) and in duel fallback options. `madayaw` vs `madyaw` differ by a letter (a). Not established; human confirmation required.
### madyaw na gabi / madyaw na gabila
- `madyaw na gabi` → mapped W015 (EXACT_LESSON_ITEM_UNIQUE, translation 'Good evening', recordings REF_065)
- `madyaw na gabila` → RC048 (MULTIPLE_TAKE_CANDIDATE; recordings REF_066;REF_067; candidate 'Madyaw na gabila' / 'Good afternoon'; tokens —)
- Project evidence establishes DIFFERENT items: published lesson 'Greetings 2' defines `Madyaw na gabi` = Good evening and `Madyaw na gabila` = Good afternoon (MCQ, matching and reordering tasks agree; a second published lesson repeats `Madyaw na gabi` = Good evening). `madyaw na gabi` is therefore mapped (W015); `madyaw na gabila` waits only for the two-take confirmation.
### lumon na bobay / umpo na bobay
- `lumon na bobay` → RC037 (SPELLING_VARIANT_CANDIDATE; recordings REF_058; candidate '' / ''; tokens bobay:bobay)
- `umpo na bobay` → RC090 (SPELLING_VARIANT_CANDIDATE; recordings REF_110; candidate '' / ''; tokens bobay:bobay)
- Project evidence: `bobay` is a dictionary noun (W007); `lumon` and `umpo` are not dictionary terms. The shared token set flags them as related, but nothing indicates the same item. Human confirmation required.

Other near-variants found and kept separate: `madyaw na allaw` (voice-submission transcript 'Madyaw na Allaw!' = Good Day!, approved, Village Chief) vs the lesson greetings; `yasagob kaw` / `yasagub` (different token sets, not flagged as variants); `umpo na bobay` / `umpu na usug` and `lumon na bobay` / `lumon na usug` (share `na`, not flagged).

## 5. Human-review queue

File: `metadata/mapping_review_queue.csv` — 97 rows, one per linguistic case (filename group), covering 112 recordings. Instructions: `validation/mapping_review_instructions.md`. After completion: `python3 scripts/apply_mapping_review.py` (validates, applies, rebuilds registry/manifest/checksums, reruns checks).

## 6. Learner-collection readiness

Authoritative items: 16. Mapped recordings: 16/128. Multi-reference items: 0 established. Unresolved recordings: 112 in 97 cases. The learner target list is NOT complete; collection must wait for the review file.
