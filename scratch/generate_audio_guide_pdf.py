from fpdf import FPDF
from datetime import date
import os

OUT_PATH = os.path.join(os.path.dirname(__file__), '..', 'LUMAD_LINGUA_Audio_Comparison_Defense_Guide_SystemVerified.pdf')

class GuidePDF(FPDF):
    def header(self):
        self.set_font('Helvetica', 'B', 9)
        self.set_text_color(90, 90, 90)
        self.cell(0, 8, 'LUMAD LINGUA AUDIO COMPARISON | DEFENSE GUIDE (System-Verified Update)', align='L')
        self.ln(4)
        self.set_draw_color(180, 140, 40)
        self.line(10, self.get_y()+4, 200, self.get_y()+4)
        self.ln(8)

    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f'Page {self.page_no()}  |  Generated {date.today().isoformat()} from current system implementation', align='C')

    def chapter_title(self, num, title):
        self.set_font('Helvetica', 'B', 13)
        self.set_text_color(34, 74, 52)
        self.ln(2)
        self.cell(0, 9, f'{num}. {title}', ln=1)
        self.ln(1)

    def sub_title(self, title):
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(50, 50, 50)
        self.ln(1)
        self.cell(0, 7, title, ln=1)

    def body(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(20, 20, 20)
        self.multi_cell(0, 5.2, text)
        self.ln(1)

    def bullet(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(20, 20, 20)
        x = self.get_x()
        self.set_x(x + 4)
        self.multi_cell(0, 5.2, f'- {text}')
        self.set_x(x)
        self.ln(0.5)

    def note(self, text):
        self.set_fill_color(245, 242, 232)
        self.set_draw_color(180, 140, 40)
        self.set_font('Helvetica', 'I', 9.5)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5.0, text, border=1, fill=True)
        self.ln(2)

    def table(self, headers, rows, col_widths):
        self.set_font('Helvetica', 'B', 9)
        self.set_fill_color(34, 74, 52)
        self.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 7, h, border=1, fill=True)
        self.ln()
        self.set_font('Helvetica', '', 8.5)
        self.set_text_color(20, 20, 20)
        fill = False
        for row in rows:
            # estimate row height
            max_lines = 1
            for i, cell in enumerate(row):
                # rough wrap estimate
                chars = max(1, int(col_widths[i] / 2.0))
                lines = (len(cell) + chars - 1) // chars
                if lines > max_lines: max_lines = lines
            h = max(6, max_lines * 4.2)
            if self.get_y() + h > 275:
                self.add_page()
                self.set_font('Helvetica', 'B', 9)
                self.set_fill_color(34, 74, 52)
                self.set_text_color(255, 255, 255)
                for i, hd in enumerate(headers):
                    self.cell(col_widths[i], 7, hd, border=1, fill=True)
                self.ln()
                self.set_font('Helvetica', '', 8.5)
                self.set_text_color(20, 20, 20)
            if fill:
                self.set_fill_color(248, 248, 248)
            else:
                self.set_fill_color(255, 255, 255)
            y0 = self.get_y()
            x0 = self.get_x()
            for i, cell in enumerate(row):
                self.set_xy(x0 + sum(col_widths[:i]), y0)
                self.multi_cell(col_widths[i], 4.2, cell, border=1, fill=True)
            self.set_xy(x0, y0 + h)
            fill = not fill
        self.ln(2)

pdf = GuidePDF()
pdf.set_auto_page_break(auto=True, margin=18)
pdf.add_page()

# Title
pdf.set_font('Helvetica', 'B', 18)
pdf.set_text_color(34, 74, 52)
pdf.multi_cell(0, 9, 'LUMAD LINGUA Audio Comparison\nResearch Defense Technical Guide', align='C')
pdf.ln(2)
pdf.set_font('Helvetica', '', 11)
pdf.set_text_color(60, 60, 60)
pdf.multi_cell(0, 6, 'Pronunciation Assessment | System-Verified Update\nA detailed, code-verified explanation of the comparison workflow, accuracy safeguards, recent system updates, and the role of learner recordings in future improvement.', align='C')
pdf.ln(4)
pdf.note('Verification note: This version was checked against the current implementation (audio_comparison_screen.dart; pronunciation_service.dart; mfcc_service.dart; wav_decoder.dart; supabase_dataset_service.dart; related models/config). It corrects and expands the earlier guide where the live system has changed.')

# 1
pdf.chapter_title(1, 'Summary of the Feature Workflow (Current)')
bullets = [
    'Target Selection: The learner chooses a Mansaka word or phrase to practice from verified, learner-facing primary dataset references.',
    'Reference Discovery & Loading: The app discovers dataset entries from Supabase Storage audio roots (primary dataset and, for comparison, dataset_2/additional takes). For learner playback, Take 1 is the default reference (primary take).',
    'Audio Capture: The learner records pronunciation as 16 kHz mono WAV/PCM (with encoder fallback handling). Maximum recording duration is 15 seconds (auto-stop). The UI provides live amplitude feedback and a recording tip.',
    'Decoding & Signal Quality Checks: Recorded audio is decoded to 16 kHz mono PCM. The system analyzes raw PCM for invalid/empty signal, silence/quiet audio, no-speech conditions (VAD including spectral-flatness/speech-likeness heuristics), clipping/distortion, high background noise / low SNR, and excessive internal pauses/hesitation. Recordings failing critical checks are rejected before scoring (with user-facing guidance).',
    'Learner Preview: After a valid recording, the learner can play back Raw Voice (default) or Preprocessed Voice and view a visual waveform.',
    'Preprocessing for Comparison: The learner PCM is prepared for comparison (DC offset removal, speech-region trimming, and loudness normalization). The comparison path does not apply a one-sided time-domain noise gate; both sides receive the same DC/trim/loudness treatment appropriate to their role (stored references are handled as preprocessed references with idempotent trimming/loudness alignment).',
    'MFCC Feature Extraction: Processed audio is converted to 39-dimensional MFCC feature vectors per frame: 13 static + 13 delta + 13 delta-delta coefficients, with Cepstral Mean Normalization (CMN, mean-only) by default.',
    'Multi-Reference DTW Comparison: The learner features are compared against every verified reference take available for the same phrase (across compatible runs/roots, up to a capped set). Distances are computed in distance space (best-matching references emphasized), then mapped once to a 0-100 score using a calibrated/provisional baseline.',
    'Mismatch / Non-Target Rejection: If the learner-to-reference distance is far beyond the native-vs-native range for that phrase, the system treats the attempt as a likely wrong phrase/non-target utterance and returns a mismatch result (score forced to 0 with guidance).',
    'Result Presentation: The app displays a percentage score and feedback. Scores >= 60% award +15 XP and update pronunciation quest progress; an interactive "Pronunciation Assessment" sheet is shown with actions (Record Again / Done). Success/error audio/haptics are used.',
]
for b in bullets: pdf.bullet(b)

# 2
pdf.chapter_title(2, 'Dataset Discovery & Reference Verification (Current)')
pdf.bullet('Storage roots: audio/dataset (primary, learner-facing references) and audio/dataset_2 (additional/supplementary references used to improve comparison accuracy). The service scans with pagination.')
pdf.bullet('Folder/phrase grouping: Entries are grouped by phrase folder. Filenames are validated against the folder name.')
pdf.bullet('Filename conventions supported: (a) RUN-tagged preprocessed WAVs: <target_phrase>_<take>__RUN-YYYY-NNNN.wav; (b) simple take WAVs: <target_phrase>_<take>.wav (used for additional-source references with a stable synthetic run id per root, e.g., DATASET_2). Raw files are ignored.')
pdf.bullet('Metadata/config hash verification (RUN-tagged): The service looks for sidecar metadata JSON files and, when found/readable, verifies run_id and config_hash against the approved Phase 1 hash: 3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21. Compatibility is determined accordingly.')
pdf.bullet('Compatibility handling (implementation behavior): RUN-tagged entries without a discoverable metadata file are treated as compatible by the current discovery logic; additional-source (non-dataset root) simple-take references are treated as compatible for multi-reference comparison. This is an implementation detail that should be understood when describing strictness of verification.')
pdf.bullet('Learner-facing vs comparison pool: Primary dataset entries (non-supplementary) are shown to learners for practice/copy (Take 1 default). Supplementary dataset_2 takes are excluded from the learner-facing list but participate in pronunciation comparison for the same phrase.')
pdf.bullet('Collision-free local caching (non-web): Reference cache filenames are built from a deterministic Base64URL encoding of phrase::runId::takeN (via buildReferenceCacheFileName) to prevent local file collisions.')
pdf.note('Defense note: The system uses naming, sidecar metadata/hash checks (where available), and compatibility flags to reduce mismatched references. However, compatibility handling includes practical fallbacks in discovery; reference integrity still depends on correct dataset organization and verified source uploads.')

# 3
pdf.chapter_title(3, 'Signal Quality Validation (Current Behavior)')
pdf.body('The app decodes recordings to 16 kHz mono PCM and performs signal analysis/validation before accepting a recording for comparison. Critical failures are rejected with guidance; quiet audio may produce a warning while still allowing the flow depending on the condition.')
rows = [
    ['Empty / invalid signal', 'Zero samples or non-finite values', 'Reject recording'],
    ['Too short for reliable comparison (enforced in capture/submit flow)', '< 0.35 seconds (minimum comparison samples) or < 100 bytes/file-level emptiness checks', 'Reject recording'],
    ['Maximum duration', '15 seconds', 'Recording auto-stops'],
    ['Silence', 'Peak below ~0.010 (-40 dBFS) and RMS below ~0.002 (-54 dBFS)', 'Reject recording'],
    ['Quiet audio', 'Not silent but peak below ~0.050 (-26 dBFS)', 'Warning shown (recording may still be reviewed/submitted based on other checks)'],
    ['No speech / non-target-like signal (VAD)', 'Insufficient speech-like evidence using activity, peak-to-noise, stationarity/modulation, and spectral-flatness (speech-likeness) heuristics', 'Reject recording ("No speech detected...")'],
    ['Clipping / distortion', '>= 1% of samples at/near ceiling (abs >= 0.995)', 'Reject recording'],
    ['High background noise / low SNR', 'Noise-floor-based SNR check (e.g., low SNR with elevated noise floor); whole-clip percentile-based noise estimate', 'Reject recording'],
    ['Excessive internal hesitation/pause', 'Silent gap > 1.5 s between active speech frames (20 ms frames)', 'Reject recording'],
]
pdf.table(['Validation check', 'Current condition / behavior', 'System response'], rows, [48, 92, 50])
pdf.note('Important clarification (vs. older guide drafts): The current analyzeSignal implementation does not expose separate, dedicated "multiple speakers" or "hardware interruption/digital zero drop" flags by those exact names. The VAD/noise heuristics (including ZCR/stationarity/spectral flatness) help reject some problematic inputs, but multi-speaker detection and hardware-drop detection should not be claimed as explicit, standalone validated detectors unless implemented and verified as such.')

# 4
pdf.chapter_title(4, 'Waveform Preprocessing for Comparison (Current)')
pdf.body('The system standardizes audio before feature extraction to improve comparability. The learner and reference preparation paths are aligned where appropriate:')
pdf.bullet('DC offset removal: Subtracts the waveform mean to center the signal around zero.')
pdf.bullet('Speech-region trimming: Energy-based trimming of leading/trailing non-speech using frame RMS thresholds (relative to peak and noise floor) with symmetric padding (~60 ms). The method is idempotent, so re-running it on an already-trimmed reference has minimal effect.')
pdf.bullet('RMS loudness normalization: Targets -20 dBFS (0.10 linear RMS) with a maximum gain of 30 dB (31.62x) and a peak ceiling of -1 dBFS (0.89125 linear). Silence/pure noise-floor signals are not amplified into "speech".')
pdf.bullet('No one-sided time-domain noise gate in the comparison preparation path: The implementation intentionally avoids applying a learner-only noise gate because it can distort amplitude envelopes and prevent a perfect repeat of the reference from matching. Stationary noise is handled through recording quality checks and the robustness of the feature/alignment/scoring pipeline.')
pdf.bullet('Reference handling: Stored Supabase reference takes are prepared as preprocessed references (DC removal, idempotent trimming, loudness normalization) before MFCC extraction for comparison.')
pdf.bullet('Learner preview option: The UI can generate/play a preprocessed preview (Raw Voice default; Preprocessed Voice toggle) so users can hear the processed signal, but the comparison logic uses the prepared PCM features for scoring.')
pdf.note('Correction vs. older draft: The earlier guide described "adaptive noise reduction/noise gating" and trimming with "-20 dB relative to peak, 100 ms padding, 150 ms zero-crossing extensions" as the active recommended_v1 preprocessing path. The current comparison preprocessing code uses DC removal + energy-based idempotent trimming + loudness normalization, and does not apply a learner-only noise gate in prepareLearnerPcm/prepareReferencePcm.')

# 5
pdf.chapter_title(5, 'MFCC Feature Extraction (Current)')
pdf.body('The system transforms processed 16 kHz mono PCM audio into compact spectral feature vectors.')
rows5 = [
    ['Sample rate', '16,000 Hz (mono)'],
    ['Pre-emphasis', 'y[t] = x[t] - 0.97 * x[t-1]'],
    ['Framing', '25 ms frames (400 samples), 10 ms hop (160 samples)'],
    ['Windowing', 'Hamming window'],
    ['Spectrum', 'Power spectrum computed per frame (DFT-based implementation in current service)'],
    ['Mel filterbank', '23 triangular filters, 20 Hz to 8,000 Hz (Nyquist)'],
    ['Cepstral features', '13 static MFCC coefficients (DCT over log filterbank energies)'],
    ['Dynamic features', 'Delta + Delta-Delta, each over width 2 (5-frame context)'],
    ['Per-utterance normalization', 'Cepstral Mean Normalization (CMN, mean-only) by default'],
    ['Total dimension', '13 + 13 + 13 = 39 features per frame'],
]
pdf.table(['Parameter', 'Current implementation'], rows5, [60, 130])
pdf.note('Correction vs. older draft: The previous guide stated CMVN (mean and variance normalization). The current MFCC service defaults to CMN (mean-only). The code intentionally preserves the spectral envelope (important for distinguishing words/phonetic content) while reducing channel/gain bias. CMVN/variance scaling can be available conceptually in code, but the default extraction path uses CMN.')

# 6
pdf.chapter_title(6, 'DTW Alignment & Distance Computation (Current)')
pdf.bullet('Purpose: DTW aligns learner and reference MFCC sequences despite differences in speaking rate/duration.')
pdf.bullet('Local cost: Euclidean distance between 39-D frame vectors (default).')
pdf.bullet('Alignment constraints (current): Banded, slope-constrained DTW (Sakoe-Chiba-style band, default band ratio 0.25) with a weighted step pattern. Plain {1,0}/{0,1} insert/delete-only steps are not used; the constrained steps limit pathological warping/compression (max length ratio 3:1 in either direction).')
pdf.bullet('Distance normalization (current): The accumulated path cost is normalized by the total step weight of the optimal path (mean local cost along the alignment), not by (N + M). This avoids pace-related bias from naive normalization.')
pdf.bullet('Why it matters: The constrained, path-weight-normalized alignment reduces inflated scores for wrong pacing/warping and makes phrase comparisons more stable.')

# 7
pdf.chapter_title(7, 'Multi-Reference Scoring, Baseline Calibration & Feedback (Current)')
pdf.sub_title('7.1 Multi-reference comparison (major update)')
pdf.bullet('The comparison uses all verified reference takes available for the selected phrase (from the combined compatible pool), not just a single fixed Take 1/Take 2 average in the UI flow.')
pdf.bullet('Reference takes are collected across compatible runs/roots for the same phrase folder, ordered round-robin across runs, and capped (current cap: 6 takes) for bounded computation.')
pdf.bullet('Each reference take is prepared and featurized; the system also adds lightweight pitch/timbre variants per reference (resampled variants, e.g., 0.94x and 1.06x) to improve robustness to natural speaker-pitch differences. Baseline calibration uses original inter-take distances (not augmented self-variants).')
pdf.sub_title('7.2 Distance aggregation and score mapping')
pdf.bullet('For DTW (default path), the service computes learner-to-reference distances and aggregates them in distance space (emphasizing best matches; current logic uses the mean of the two best distances when available), then maps once to a 0-100 score. This avoids distortions from averaging percentages after a non-linear mapping.')
pdf.bullet('Calibrated/provisional baseline: When >= 2 reference takes exist, a baseline (mean/sigma) is measured from native-vs-native distances ("as close as another native recording of this phrase"). With a single reference, a provisional CMN-scale baseline is used until more takes are available.')
pdf.bullet('Logistic score mapping (DTW): The score is derived from the normalized distance relative to the baseline using a logistic function (pivot near baseline mean + sigma; slope influenced by strictness). A match close to native-vs-native variation can score relatively high; far distances score low.')
pdf.bullet('Strictness/algorithm configuration: The app reads the active pronunciation algorithm from config (default: dtw). The codebase also contains HMM/cosine candidate paths, but DTW is the primary/default comparison path used by the screen.')
pdf.sub_title('7.3 Mismatch / non-target utterance rejection')
pdf.bullet('If the DTW distance exceeds a mismatch threshold derived from the baseline (adaptive per phrase; conservative floor for provisional/single-reference cases), the attempt is treated as likely the wrong phrase or non-target speech. The result is forced to 0 with mismatch feedback.')
pdf.sub_title('7.4 Learner-facing feedback and XP (current)')
pdf.bullet('The UI presents a percentage and feedback. Current UI thresholds: >= 80% "Excellent" (green), >= 60% and < 80% "Good" (brown), < 60% "Needs Improvement" (orange/red). Mismatch results show "NOT THE TARGET PHRASE".')
pdf.bullet('Passing attempts (>= 60%, non-mismatch) award +15 XP, trigger success feedback/haptics/sound, and update pronunciation quest progress. A "Pronunciation Assessment" modal/sheet is shown with the result.')
pdf.note('Correction vs. older draft: The old guide\'s simple dual-take average formula [Score(Take1)+Score(Take2)]/2 and the exponential form Score = exp(-sensitivity*AvgDistance/15)*100 (sensitivity 3.0) as the primary DTW scoring description do not match the current DTW implementation, which uses calibrated/provisional baselines, best-distance aggregation in distance space, and a logistic mapping. The old formula should not be presented as the current deployed scoring equation.')

# 8 - Accuracy question
pdf.chapter_title(8, 'How Can You Ensure That the Results of the Comparison Are Accurate and Correct?')
pdf.body('The system can improve the reliability of pronunciation comparison, but no automated acoustic score can be guaranteed perfectly accurate or "correct" for every learner, phrase, microphone, or speaking style. Accuracy is best understood as a combination of technical safeguards, calibrated evaluation, and human judgment.')
pdf.sub_title('What the system does to support accurate results')
pdf.bullet('Reference controls: Uses verified/compatible phrase references discovered from the dataset storage (with naming/metadata/hash checks where available) and separates learner-facing primary references from supplementary comparison references.')
pdf.bullet('Input quality gating: Rejects or warns on problematic recordings (silence/quiet, no-speech, clipping, high noise/low SNR, excessive pauses, too-short audio) before scoring to reduce misleading results from bad input.')
pdf.bullet('Consistent preprocessing: Decodes to a standard format (16 kHz mono), removes DC offset, trims to the speech region (idempotent), and normalizes loudness to a shared target so avoidable recording differences have less impact.')
pdf.bullet('Robust acoustic features: Extracts 39-D MFCC + delta + delta-delta features to represent spectral/temporal speech characteristics, with CMN (mean-only) to reduce channel/gain bias while preserving useful speech information.')
pdf.bullet('Timing/rate robustness: Uses banded, slope-constrained DTW with path-weight normalization to compare utterances spoken at different speeds without relying on exact timing.')
pdf.bullet('Multi-reference and calibration: Compares against multiple verified takes (when available), aggregates distances in distance space, and uses native-vs-native baselines (when measurable) to make scores more phrase-relative. Pitch/timbre variants are added to references to improve robustness to natural voice differences.')
pdf.bullet('Non-target protection: Applies mismatch/utterance-distance rejection to reduce false-positive scores when the learner says the wrong phrase or produces non-target speech.')
pdf.bullet('Deterministic core scoring: For the same inputs, configuration, and code path, the MFCC/DTW-based comparison is deterministic (it does not self-train or change weights during normal use).')
pdf.sub_title('Limitations (important for defense)')
pdf.bullet('Acoustic similarity is not the same as linguistic correctness: A high score indicates similarity to the reference acoustic pattern, not guaranteed correctness of meaning, grammar, dialectal appropriateness, or all phonetic details.')
pdf.bullet('Reference dependence: Results depend on the quality, representativeness, and correctness of the native/reference recordings. A limited or atypical reference set can bias scores.')
pdf.bullet('Speaker and recording variability: Microphone quality, distance, room acoustics, background noise, age/voice timbre, accent, and speaking style can affect MFCC/DTW distances even after preprocessing.')
pdf.bullet('Dialect/acceptable variation: Mansaka pronunciation may have legitimate variation. A rigid threshold or limited reference pool may penalize acceptable variants unless references and calibration reflect that variation.')
pdf.bullet('Thresholds are not universal truth: Feedback tiers (e.g., 60%/80%) and mismatch thresholds are engineered decision rules. They require empirical validation (human-rated comparisons) to confirm fairness and usefulness.')
pdf.bullet('Heuristic quality checks can fail: VAD/noise/pause/clipping checks reduce bad inputs but are not perfect; they may reject some valid recordings or accept some problematic ones.')
pdf.bullet('Model scope: The current feature is a deterministic acoustic comparison pipeline (primarily MFCC+DTW), not a fully supervised ASR/pronunciation-scoring model trained on a large Mansaka learner corpus. It cannot capture every pronunciation error type the way a richly annotated model might.')
pdf.bullet('No guarantee per attempt: The system should report confidence through safeguards and guidance, not claim that every displayed percentage is objectively correct.')
pdf.sub_title('How to strengthen/validate correctness (recommended)')
pdf.bullet('Create a labeled evaluation set of Mansaka learner recordings with human expert ratings (correct/acceptable/incorrect or rubric scores).')
pdf.bullet('Compare system scores/decisions against human judgments (agreement, correlation, confusion around pass/fail thresholds, mismatch detection accuracy).')
pdf.bullet('Test across speakers, devices, environments, and phrase types; tune thresholds/calibration only on a development set and validate on a held-out set.')
pdf.bullet('Expand and verify reference recordings (multiple speakers/takes) to represent natural variation.')
pdf.bullet('Collect learner data only with consent and privacy controls; use it for offline benchmarking/calibration or future model research, not automatic online retraining.')

# 9
pdf.chapter_title(9, 'Does Repeated Learner Use Train the Algorithm?')
pdf.bullet('No, not automatically. The current on-device comparison is deterministic/rule-based for the scoring path (MFCC extraction + DTW/baseline mapping). It does not update neural-network weights or rewrite parameters from normal learner attempts.')
pdf.bullet('Learner recordings may support future improvement only if they are intentionally collected with consent, stored with metadata, reviewed/labeled by humans, and used in a separate offline evaluation/calibration/training process.')
pdf.bullet('Any threshold tuning, calibration updates, or future model training must be validated against human judgments and a held-out evaluation set before deployment.')

# 10
pdf.chapter_title(10, 'Key Defense Takeaways (Updated)')
pdf.bullet('Mansaka is a low-resource context: MFCC + constrained DTW provides a transparent, on-device acoustic comparison approach without requiring a cloud inference service.')
pdf.bullet('Current implementation is more robust than a simple dual-take average: it uses multi-reference comparison (including supplementary references), distance-space aggregation, calibrated/provisional baselines, and mismatch rejection.')
pdf.bullet('Normalization choice is intentional: default CMN (mean-only) preserves spectral envelope information; this differs from older CMVN descriptions.')
pdf.bullet('Preprocessing is aligned for fair comparison: DC removal, idempotent speech-region trimming, and loudness normalization are used; the system avoids a learner-only noise gate in the comparison preparation path.')
pdf.bullet('Scores are decision-support, not absolute truth: results should be interpreted alongside quality checks, reference quality, calibration evidence, and human evaluation.')

pdf.body('One-sentence defense answer: "LUMAD LINGUA compares learner recordings to verified Mansaka reference takes using signal-quality checks, standardized preprocessing, 39-dimensional MFCC+delta features with CMN, constrained DTW alignment, and calibrated multi-reference distance-based scoring with mismatch rejection; these safeguards improve reliability, but the result is an acoustic similarity estimate - not a guaranteed-correct linguistic judgment - so accuracy is ensured through validated references, calibrated thresholds, and human-reviewed evaluation."')

out = os.path.abspath(OUT_PATH)
pdf.output(out)
print(out)
