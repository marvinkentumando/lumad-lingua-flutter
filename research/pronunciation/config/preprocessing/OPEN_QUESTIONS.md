# Preprocessing protocol — open questions for the next stage (PP001 / FE001 remain CANDIDATES)

Measured source properties (all 128 validated references, see reports/reference_audio_audit_v0.1.md §3):
RIFF WAVE PCM16, 44,100 Hz, 2 channels of true stereo (L ≠ R in every file, max sample difference 19,264),
durations 0.534–2.786 s, peaks −9.6 to −0.0 dBFS (49 files within 0.1 dB of full scale, none clipped),

Status after PPINV001 (2026-09-30, reports/preprocessing_protocol_v0.2.md):
RESOLVED — 1 stereo→mono: average (FROZEN; L/R corr ≥ 0.979, no lag/polarity/cancellation). 4 resampling: 16 kHz, soxr HQ 1.1.0/libsoxr 0.1.3 (FROZEN). 6 FE001 frame settings: shortest item gives 51 frames untrimmed / 37 trimmed, all 128 finite (FROZEN contract). Trim mechanism: relative-to-peak frame-RMS endpoint trim (FROZEN); DC removal (FROZEN); noise reduction off (FROZEN).
REMAINING — 2 normalisation type/target; 3 trim threshold/min-silence/padding values; 5 lossy learner decoder; 7 multi-reference aggregation (Stage 3). Items 2, 3 and 5 require representative learner recordings and cannot be settled on the edited reference masters.
