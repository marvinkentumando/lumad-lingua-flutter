# Vocabulary mapping re-analysis with the Svelmoe & Svelmoe (1990) dictionary — lumad_lingua_pronunciation_v0.2

Generated 2026-09-30. Supersedes the mapping figures in reports/vocabulary_mapping_v0.2.md. No audio touched; no algorithm run; all 128 validated recordings preserved.

## 1. Dictionary files inspected

| File | SHA-256 | Structure |
|---|---|---|
| `staging/dictionary/Mansaka_Dictionary_Svelmoe_1990.xlsx` | `407367995c3b41f4…` | transcription A (sheets Entries/Examples/English-Mansaka Finder/About) |
| `staging/dictionary/Mansaka_Dictionary_Svelmoe_1990_2.xlsx` | `34bd1920c7fb598c…` | transcription B (sheets Entries with stable IDs/Examples/Raw OCR Entries/Abbreviations/About) |

Both are OCR transcriptions of the same printed dictionary (Summer Institute of Linguistics, book pages 1–496; 6,011 entries, 6,539 sense rows, 13,186 example pairs per the 'About' sheet). They were flattened, without alteration of the originals, into `staging/dictionary/svelmoe1990_entries.csv` (13142 sense rows across both), `svelmoe1990_examples.csv` (26516 example rows) and `svelmoe1990_finder.csv` (3979 reverse-index rows). OCR caveats from the files: accented vowels lost, occasional letter misreads, some merged/split entries; both transcriptions were used so that a match in either counts and disagreements are visible.

Cross-check: the 2,000-word Firestore `words` collection is a subset of this dictionary (same definitions and example sentences), so the earlier Firestore matches are now corroborated by the source.

## 2. Results over all 128 recordings

| Quantity | Before dictionary | After |
|---|---|---|
| Recordings mapped (authoritative) | 16 | **37** |
| Vocabulary items | 16 | **36** (W001–W016 unchanged; W017–W036 new) |
| Items with more than one validated reference | 0 | 1 (`madayaw, madyaw` W025: REF_015 + REF_063, the dictionary lists both spellings under one headword) |
| Review cases | 97 (112 recordings) | **76 (91 recordings)** |
| Cases removed from the queue by the dictionary | — | 21 |

Authoritative evidence by recording: DICTIONARY_EXAMPLE_EXACT 4, DICTIONARY_FINDER_EXACT 1, DICTIONARY_HEADWORD_ALTFORM 2, DICTIONARY_HEADWORD_EXACT 28, EXACT_LESSON_ITEM_UNIQUE 2.

Cases resolved by the dictionary: RC002 `ama`; RC013 `Dagom`; RC023 `ina`; RC024 `Ingkod`; RC025 `isa`; RC035 `Larad`; RC036 `lima`; RC042 `Madaig`; RC044 `madayaw`; RC045 `Madyaw`; RC054 `makagwas`; RC057 `maparaat`; RC071 `pakal`; RC076 `pito`; RC078 `sandok`; RC080 `Sapi`; RC084 `siyam`; RC087 `tabidak`; RC094 `Usug`; RC096 `Wara ko akaani yang pinggan`; RC097 `waro`.

Policy: dictionary-supported = the unsuffixed filename text equals a headword, a listed alternate form, an example sentence or a finder form (normalisation only for lookup; text copied verbatim). Recordings with an explicit take suffix `(n)` are still never auto-mapped (their group is a MULTIPLE_TAKE_CANDIDATE case with the item prefilled). The u→o orthographic rule, r↔l and affix-stripped roots generate prefilled candidates only.

## 3. Remaining review queue

| Category | Cases | Recordings |
|---|---|---|
| DICTIONARY_ORTHOGRAPHIC_VARIANT | 2 | 2 |
| DICTIONARY_ROOT_CANDIDATE | 14 | 14 |
| MULTIPLE_TAKE_CANDIDATE | 12 | 27 |
| NO_PROJECT_MATCH | 17 | 17 |
| PARTIAL_TOKEN_CANDIDATE | 26 | 26 |
| SPELLING_VARIANT_CANDIDATE | 4 | 4 |
| VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE | 1 | 1 |

Rule tags: {'token glosses': 36, 'u->o': 6, 'affix-stripped root': 14}.

Why 76 and not 97: 21 filename groups became dictionary-supported (headword, alternate form, example sentence, finder). The remaining cases are inflected forms whose roots exist but whose exact form is not a headword (14), phrases absent from the dictionary (26 with per-word glosses), the 12 multi-take groups (only the take relationship is open; the item is prefilled for 7 of them), 4 spelling-variant pairs, 2 u→o orthographic variants, 1 voice-submission transcript and 17 forms with no evidence anywhere.

## 4. Multiple-take groups (12, 27 recordings)

- RC069 `Pagarungan` (REF_020;REF_089): item prefilled → `pagarongan` / n. Glass; mirror. [u->o]
- RC073 `Paroda` (REF_022;REF_092): item prefilled → `Paroda` / vegetable [MULTIPLE_TAKE_CANDIDATE]
- RC098 `Yaabay ko kamangun` (REF_027;REF_028): no dictionary/project record; text from filename only
- RC110 `Yanag-aruk yang mangaysu` (REF_031;REF_032): no dictionary/project record; text from filename only
- RC018 `duwambuok` (REF_043;REF_044): no dictionary/project record; text from filename only
- RC048 `madyaw na gabila` (REF_066;REF_067): item prefilled → `Madyaw na gabila` / Good afternoon [token glosses]
- RC049 `madyaw na masurom` (REF_069;REF_070;REF_071;REF_072): item prefilled → `Madyaw na masurom` / Good morning [MULTIPLE_TAKE_CANDIDATE]
- RC056 `mangud` (REF_076;REF_077): item prefilled → `mangod` / n. Younger sibling. [u->o]
- RC065 `nanang uram mayo` (REF_084;REF_085): no dictionary/project record; text from filename only
- RC082 `sining bapa mo` (REF_100;REF_101): no dictionary/project record; text from filename only
- RC088 `turo` (REF_107;REF_108): item prefilled → `toro` / hom.1 num. Three. | hom.1 mum, Three. | hom.2 n. Bull (cow o [u->o]
- RC093 `upat` (REF_113;REF_114;REF_115): item prefilled → `opat` / num. Four. | mum. [u->o]

The `(n)` suffix is filename metadata (duplicate-name numbering); it does not by itself prove the recordings are the same item, so each group carries one `takes_same_item` decision.

## 5. Conflicting or uncertain dictionary evidence

- `madyaw na gabila` (RC048): published lesson 'Greetings 2' = Good afternoon; dictionary `gabila` = dusk; evening (finder: dusk, evening, twilight), `ambong` = afternoon. Gloss conflict recorded; item identity unaffected.
- `Madyaw na gabi` (W015, lesson = Good evening): dictionary `gabi` = night (transcription B) / dusk; evening. Gloss conflict recorded on the vocabulary row.
- `madyaw na masurom` (RC049, lesson = Good morning): dictionary spells the noun `masurum` (finder: morning) and also lists `karamdag` = morning.
- Homonyms: `ina` (n. mother / v. to insult), `dagom` (n. shirt / v. to dress), `isa` (num. one / v. to agree), `toro` (num. three / n. bull), `kita`, `sayaw`, `sagda`. The spoken form is one item; all senses are kept in `dictionary_definition`; no gloss was chosen.
- OCR noise inside definitions (e.g. `usug` "4“. Male human.", `siyam` "mun.") is kept verbatim; where two transcriptions differ both are listed.
- `ama` (father) is in the finder but its headword entry was not located in either transcription (probably merged with the `ama-` prefix entry by OCR); mapped as DICTIONARY_FINDER_EXACT.

## 6. Variant investigation (updated)

- `madayaw` / `madyaw`: RESOLVED — one dictionary headword `madayaw, madyaw (from ma- + dayaw) adj. Good; beautiful; reliable; pleasant; honorable`. Both recordings map to W025; each keeps its recorded spelling in `form_text` (the two forms are pronounced differently, which the experiment must respect when prompting learners).
- `pasaylowak doon` / `pasayluwak doon`: root `pasaylo` (pardon, forgive) and particle `doon` (emphasis) are headwords; the `o`/`u` difference falls under the orthographic rule, so they are very likely one form, but the inflected phrase is not in the dictionary → remain a linked SPELLING_VARIANT pair (RC074/RC075).
- `madyaw na gabi` / `madyaw na gabila`: DIFFERENT items, confirmed by both the lesson and the dictionary (`gabi` night/evening vs `gabila` dusk/evening; `ambong` afternoon).
- `lumon na bobay` / `umpo na bobay`: `ompo` = grandchild; grandparent, `bobay` = female; `lumon` not found (finder gives `lomon` = kinship term). Different items by evidence; both still need their text confirmed.
- Numbers: `isa`, `lima`, `pito`, `waro`, `siyam` are exact headwords; `upat`→`opat`, `turo`→`toro`, `sampuro`→`samporo` are u→o variants; `unom` (six) is absent from both transcriptions (OCR gap: no 'six' in the finder either); `duwambuok` is compositional (`dowa` two + `buok`).

## 7. Recordings still without a confident mapping

91 recordings in 76 cases (see queue). No evidence anywhere for 17 forms: `Magasogbo`, `amanting`, `baboo`, `dakurat`, `duor`, `isu`, `kamanggud`, `katumbar`, `kinuraw muuri`, `lutya`, `maanog`, `madyaw na masurom kariko`, `marutuy`, `nangamang pak ng kayamas`, `pagsugbo`, `unom`, `yulugpat`.

## 8. Files

- Queue: `metadata/mapping_review_queue.csv` (76 rows). Instructions: `validation/mapping_review_instructions.md`.
- Evidence inventory: `metadata/mapping_evidence.csv` (128 rows, dictionary fields added). Registry: `metadata/reference_recordings.csv` (new `form_text`). Vocabulary: `metadata/vocabulary.csv` (36 items, dictionary columns). Ledger: `metadata/vocabulary_id_history.csv`.
- Previous queue kept as `reports/superseded/mapping_review_queue_v0.2_pre-dictionary_97cases.csv`.
