# Preprocessing protocol investigation — PPINV001 (corpus lumad_lingua_pronunciation_v0.2)

Generated 2026-09-30T04:02:39+00:00. Pipeline 0.1.0, Python 3.11.15, numpy 2.4.6, scipy 1.17.1, python-soxr 1.1.0 (libsoxr 0.1.3-14-ga66f3ee). Registry sha256 637b00043bed02e2…, raw checksum list sha256 4ba701e39310cf8b…. All measurements are on the 128 validated references read from `raw/reference/` (never modified). No pronunciation algorithm was run.

## 1. Stereo channel analysis (all 128)

| Measure | min | median | max |
|---|---|---|---|
| L/R Pearson correlation | 0.979 | 0.99995 | 0.999999 |
| RMS(L) − RMS(R) [dB] | -0.043 | 0.000 | 0.019 |
| peak(L) − peak(R) [dB] | -0.235 | 0.000 | 0.274 |
| cancellation loss of (L+R)/2 vs coherent expectation [dB] | -0.046 | -0.000 | -0.000 |
| DC offset L / R [FS] | -0.00104 / -0.00104 | — | 0.00011 / 0.00012 |

Rules applied: polarity inversion = corr < −0.5 (found: 0); time offset = best cross-correlation lag ≠ 0 within ±40 samples and gain > 0.05 (found: 0; every file's best lag is 0); cancellation = loss < −3 dB or corr < 0.5 (found: 0). Louder channel: L in 67 files, R in 61. Lowest correlation: none below 0.9 (minimum 0.979, REF_005).

Feature-level effect (FE001 at 16 kHz, no trim/normalisation): mean frame distance L vs R median 0.157 (max 0.435), L vs average 0.176, R vs average 0.182, against a within-file frame spread of 8.174 (median). Channel choice moves features by roughly 2% of their natural variation.

**Conclusion.** The two channels are the same signal with sub-0.05 dB level differences and no lag or polarity anomaly; averaging cannot cancel anything (worst loss 0.054 dB) and is symmetric. `channel_handling = average` is FROZEN. Left-only would have been equally valid on this corpus, but averaging halves uncorrelated channel noise and needs no per-file choice. A per-file guard (corr ≥ 0.9, loss > −3 dB) is defined for future inputs.

## 2. Level / normalisation analysis

| Measure (average channel) | min | median | max |
|---|---|---|---|
| RMS [dBFS] | -24.382 | -14.442 | -9.972 |
| peak [dBFS] | -10.149 | -0.572 | -0.001 |
| crest factor [dB] | 9.971 | 13.618 | 19.027 |
| gain for peak −1 dBFS [dB] | -0.999 | -0.428 | 9.149 |
| gain for RMS −20 dBFS [dB] | -10.028 | -5.558 | 4.382 |
| peak after RMS −20 dBFS [dBFS] | -10.029 | -6.382 | -0.973 |

63 files peak above −0.5 dBFS (already peak-normalised masters); 5 files peak below −6 dBFS (REF_049, REF_078, REF_081, REF_099, REF_104). Recording-to-recording RMS spread is 14.4 dB. Neither candidate clips any reference (RMS −20 dBFS leaves ≥ 0.97 dB headroom because crest factors stay below 19.1 dB).

Gain sensitivity of FE001: scaling a file by 0.25 changes C1..C13 by ≤ 1e-14 on frames whose mel energies stay above the 1e-10 log floor, but 79/128 files show a change > 0.01 somewhere because near-silent frames (≤ 2.0% of a file's frames) hit the floor at one gain and not the other; after the relative −40 dB endpoint trim this drops to 35/128 files (remaining cases are quiet frames inside the utterance).

**Conclusion.** Level normalisation does not change the speech information FE001 encodes; it only decides which near-silent frames fall below the log floor and how absolute thresholds behave, and it must make learner recordings (different devices, unknown crest factors) comparable to these masters. That cannot be judged from references alone, so `normalization` stays PROVISIONAL (candidate values retained). Reference-only facts recorded above will be reused when learner audio exists.

## 3. Silence / trimming analysis (average channel, 16 kHz, 10 ms frames)

| Setting | leading removed ms (median / max) | trailing removed ms (median / max) | removed fraction (median / max) | min FE001 frames after |
|---|---|---|---|---|
| absolute −30 dBFS | 60 / 280 | 117 / 656 | 0.153 / 0.558 | 30 |
| absolute −40 dBFS (v0.1 candidate) | 0 / 280 | 54 / 396 | 0.082 / 0.500 | 34 |
| absolute −50 dBFS | 0 / 270 | 0 / 240 | 0.000 / 0.437 | 45 |
| relative −40 dB re peak (new candidate) | 0 / 270 | 0 / 333 | 0.060 / 0.483 | 37 |
| relative −40 dB, no padding | 0 / 320 | 0 / 383 | 0.111 / 0.606 | 27 |

Raw low-energy margins at −40 dBFS: leading 20–330 ms (median 90), trailing 0–440 ms (median 100). Files losing > 20% under the relative candidate: 22 (these contain long low-level tails after the word); no file drops below 30 frames under any setting.

**Conclusion.** The references are already edited masters, so trimming is mostly a no-op at the head and removes only quiet tails; it never starves FE001 of frames. The trim *mechanism* is FROZEN (frame-RMS endpoint trim at 10 ms, threshold relative to the file peak so it is gain-invariant and independent of the normalisation decision, applied after resampling). The threshold, minimum-silence and padding *values* stay PROVISIONAL because learner recordings will carry real leading/trailing silence and room noise that these masters do not have.

## 4. Resampling

Implementation: python-soxr 1.1.0 / libsoxr 0.1.3-14-ga66f3ee, quality HQ, float32 in, float64 out. Targets evaluated: 16 000 Hz and 22 050 Hz.

| Check | 16 kHz | 22.05 kHz |
|---|---|---|
| byte-identical repeated runs | True | True |
| all outputs finite | True | True |
| sample count = round(n·target/44100) ±1 | all | all |
| duration error [ms] (min / max) | -0.0302 / 0.0312 | 0.0000 / 0.0000 |
| peak change [dB] (min / max) | -0.260 / 0.262 | -0.208 / 0.103 |

Spectral energy of the originals above 4 kHz: median 0.089% (max 12.95%); above 8 kHz: median 0.0074% (max 1.24%); above 11.025 kHz: max 0.68%. Shortest file at 16 kHz: 8545 samples.

**Conclusion.** 16 kHz discards at most 1.24% (median 0.007%) of the energy, matches the standard MFCC band (fmax 8 kHz), and is the realistic on-device rate. `target_sample_rate_hz = 16000` and the resampler (soxr HQ, version-pinned) are FROZEN; output hashes in the transformation log are the reproducibility reference for Colab.

## 5. Candidate processed corpus and FE001 features

`processed/PP001-candidate/` (status **noncanonical**, config hash 10033fde7a59): 128 ok / 0 failed; mono 16 kHz PCM16; 0 clipped samples; two runs produced byte-identical files and logs.
`features/PP001-candidate_FE001/` (FE001 hash e823247b4dae): 128 ok / 0 failed; frames 37–244; 13 coefficients; all finite; .npy float32; deterministic across runs. The 37-frame minimum belongs to the trimmed shortest items; every file yields a usable MFCC matrix.

## 6. Parameter status summary

See `config/preprocessing/PP001.yaml` → `parameter_status` (FROZEN: decoding_pcm, channel_handling, target_sample_rate_hz, resampler, sample_format, dc_offset_removal, silence_trim_method, noise_reduction; PROVISIONAL – learner data required: decoding_lossy, normalization, silence_trim_threshold_db, silence_trim_min_silence_ms, silence_trim_pad_ms) and `config/features/FE001.yaml` (all parameters FROZEN as the common design contract).

## 7. What still needs learner recordings

1. Lossy (m4a/AAC) decoding contract and decoder version.
2. Normalisation type and target (peak vs RMS), judged on device-level differences and floor behaviour of real learner audio.
3. Trim threshold, minimum-silence and padding values on recordings with real silence and room noise.
4. Whether the same trim/normalisation settings are applied identically to references and learners (cross-domain consistency).

Nothing in this list blocks preparing the experiment structure; it blocks only the canonical `processed/PP001` generation and the freeze of PP001.
