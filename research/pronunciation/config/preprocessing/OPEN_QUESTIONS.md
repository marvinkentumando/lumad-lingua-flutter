# Preprocessing protocol — open questions for the next stage (PP001 / FE001 remain CANDIDATES)

Measured source properties (all 128 validated references, see reports/reference_audio_audit_v0.1.md §3):
RIFF WAVE PCM16, 44,100 Hz, 2 channels of true stereo (L ≠ R in every file, max sample difference 19,264),
durations 0.534–2.786 s, peaks −9.6 to −0.0 dBFS (49 files within 0.1 dB of full scale, none clipped),
DC offset ≤ 0.001 FS, leading quiet 23–327 ms, trailing quiet 4–304 ms (already trimmed/edited masters).

Decisions deliberately NOT taken yet (must be tested objectively, with results recorded next to the chosen PP config):
1. Stereo → mono: left-only vs right-only vs average. Measure per-file L/R correlation and spectral difference; check
   whether averaging introduces cancellation; compare MFCC distance between the three variants.
2. Level normalisation: peak (−1 dBFS) vs RMS/LUFS vs none; effect on cross-device comparability with learner m4a input.
3. Silence trimming: threshold/min-silence/padding versus references that are already tightly trimmed (4 ms tails);
   whether trimming must be identical for references and learners; effect on frame counts for sub-0.6 s items.
4. Resampling: 16 kHz vs 22.05 kHz vs native 44.1 kHz for MFCC; resampler and version to pin.
5. Decoder pinning for learner m4a/AAC input (deterministic decoding) versus lossless WAV references.
6. FE001 frame settings on the shortest items (35–60 frames at 25/10 ms); whether deltas/CMVN are needed.
7. Multi-reference items: per-reference scoring is retained; the aggregation strategy (best, mean, per-take reporting)
   is a Stage 3 experiment-design question, not a preprocessing one.
