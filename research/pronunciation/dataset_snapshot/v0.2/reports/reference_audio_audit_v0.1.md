# Reference audio audit — lumad_lingua_pronunciation_v0.1 (PRE-FREEZE)

Generated: 2026-09-30 (supersedes the earlier v0.1 audit that reported the source as unreachable).
Environment: cloud container, Python 3.11.15, mutagen 1.48.1 plus an independent WAV-header parser and
direct PCM analysis; no ffprobe. Supabase host still denied by the network policy; the source was
instead supplied as a manually exported archive.

## 1. Source and provenance

| Item | Value |
|---|---|
| Declared source | Supabase project ovdwgowtnlujnbcyldkk, bucket `audio`, path `dataset` |
| Delivered as | `dataset.zip` uploaded manually (20,255,997 bytes), SHA-256 `df4e62cadd972f04a614b3ccc1f634f18b0a6269803b22c913d4f32fea218d89` |
| Archive entries | 128 files, 0 directories, all under `dataset/` |
| Extraction | byte-for-byte to `staging/supabase_audio_dataset/<original name>`; CRC32 and size of all 128 verified against the archive (0 mismatches); per-file SHA-256 recorded in `metadata/source_objects.csv` and `metadata/source_audio_inventory.csv` |
| Provenance record | `staging/source_archive_provenance.json` |

Caveat: the archive is a copy made outside this environment. Its equivalence to the live bucket
(object count, names, bytes) could not be verified against Supabase directly.

## 2. Inventory

| Quantity | Count |
|---|---|
| Total entries | 128 |
| Audio files | 128 (all `.WAV`) |
| Non-audio files | 0 |
| Unreadable / corrupt | 0 |
| Exact byte duplicates (SHA-256 groups) | 0 |
| Distinct base names (case-insensitive, `(n)` suffix and stray spaces stripped) | 113 |
| Base names with more than one file (variant groups) | 12 groups, 27 files |
| Single-token names (words) | 75; multi-token names (phrases): 53 |

Variant groups (`variant_group_id` in the inventory): duwambuok ×2, madyaw na gabila ×2,
madyaw na masurom ×4, mangud ×2, nanang uram mayo ×2, pagarungan ×2, paroda ×2, sining bapa mo ×2,
turo ×2, upat ×3, yaabay ko kamangun ×2, yanag-aruk yang mangaysu ×2. Two of these have byte-different
files with identical duration (`sining bapa mo`, `madyaw na masurom(1)/(2)`), so they are separate takes,
not copies.

Near-duplicate spellings (distinct base names, likely same item): `pasaylowak doon` / `pasayluwak doon`;
`madyaw` / `madayaw`; `madyaw na gabi` / `madyaw na gabila`; `lumon na bobay` / `umpo na bobay` (probably
different items sharing tokens). Three filenames carry a trailing space before the extension.

## 3. Technical properties (all 128 files)

| Property | Value |
|---|---|
| Container / codec | RIFF WAVE, PCM (fmt tag 1), 16-bit |
| Sample rate | 44,100 Hz (128/128) |
| Channels | 2 (128/128); true stereo, L ≠ R in every file (max L−R sample difference 19,264) |
| Bitrate | 1,411.2 kbps |
| Duration | min 0.534 s, median 0.975 s, mean 1.075 s, max 2.786 s |
| Under 1.0 s | 66 files (single words; shortest: pito, unom, upat(1) at 0.534 s) |
| Peak level | −9.6 to −0.0 dBFS, mean −1.3 dBFS; 49 files peak at ≥ −0.1 dBFS; no sample reaches ±32767 |
| DC offset | ≤ 0.001 of full scale (negligible) |
| Leading quiet (< −40 dBFS) | 23–327 ms, median 69 ms |
| Trailing quiet | 4–304 ms, median 47 ms; 47 files have < 30 ms |

Interpretation: the files are lossless but already edited: most are tightly trimmed and roughly half
are peak-normalised to just under full scale. They are not raw captures from the app (which records
m4a/AAC). No evidence of lossy compression.

## 4. Mapping to the 48 validated references

| Quantity | Count |
|---|---|
| Candidate files | 128 |
| Exact Firestore `words.term` matches (case-insensitive) | 11 files (Antik, Arabat, Barangaw, Bobay, Bugsak, Kadyawan, arayon, bapa, batad, karapi, kimod) |
| Confidently identified as one of the 48 validated references | **0 / 48** |
| Unresolved | 48 / 48 |

Reason: the archive holds 128 recordings for 113 items with multiple takes, and no project record
states which 48 items and which take per item were validated. A Firestore term match confirms an item
exists in the dictionary, not that its recording was validated. Assigning W001–W048 from this
material alone would be a guess, so `raw/reference/` remains empty and every `vocabulary.csv` row stays
`pending_source_mapping`.

Researcher-confirmation table: `reports/reference_selection_v0.1.csv` (128 rows, one per file,
with base name, variant group, duration, Firestore match ids, and blank `is_validated_reference` /
`assigned_word_id` / `confirmed_by` / `confirmation_date` columns to be filled by the researcher with
V01's confirmation). After it is filled, `scripts/fetch_reference_audio.py promote` can populate
`raw/reference/` from the staged copies (add `source_storage_path` to `vocabulary.csv`).

## 5. PP001 / FE001 reassessment (still CANDIDATES)

- Resampling 44.1 kHz → 16 kHz with anti-aliasing: appropriate and required; the source is lossless so
  no decoder determinism issue.
- Mono handling: `mono_average` on true stereo can cause partial phase cancellation. Recommend an
  explicit comparison of `mono_average` vs `left_only` on a few files before freezing, and record the
  choice; `left_only` is the safer default if channels differ.
- Peak normalisation to −1 dBFS: harmless; roughly half the files are already near 0 dBFS, so this
  mostly attenuates by ~1 dB. Consider whether learner recordings (likely quieter, m4a) need the
  same target, or whether RMS normalisation is preferable for cross-device comparison.
- Silence trim (−40 dB, 100 ms, 50 ms pad): references already carry 4–327 ms of quiet, so the trim
  is close to a no-op on references; it matters mainly for learner recordings. The 50 ms pad cannot
  add audio that was already cut. Keep, but note that trimmed references shorter than 0.6 s yield
  only ~35–60 MFCC frames at 25/10 ms; FE001 frame settings remain reasonable at 16 kHz.
- FE001: unchanged. With 16 kHz input, `fmax_hz = 8000` is the Nyquist limit and `n_fft = 512`
  covers a 25 ms frame (400 samples). No change proposed until real learner audio exists.
- Nothing is frozen. `status: candidate` stays on both files.

## 6. Risks before learner collection

1. The set of 48 and the chosen take per item must be confirmed by V01 in the selection table.
2. Reference recordings are edited (trimmed, normalised) while learner recordings will be raw m4a;
   PP001 must make both comparable and the difference should be reported in the methodology.
3. Stereo-to-mono strategy needs a documented test.
4. Filename spelling inconsistencies (`pasaylowak`/`pasayluwak`, `madyaw`/`madayaw`) must be resolved
   against the dictionary before `mansaka_text` is filled; never from the filenames alone.
5. Live-bucket equivalence of the archive remains unverified.
