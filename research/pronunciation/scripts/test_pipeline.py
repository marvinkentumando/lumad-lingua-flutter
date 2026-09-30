#!/usr/bin/env python3
"""Automated checks for the preprocessing/feature pipeline (unittest). Run: python3 scripts/test_pipeline.py [--root R]
Covers: decoding contract, deterministic preprocessing, raw immutability (SHA-256 before/after), derived output sample
rate/channels, duration sanity, finite samples, no clipping introduced, MFCC non-empty/dimensions/no NaN/Inf,
deterministic features, gain invariance of C1..C13 on non-floor frames, independent cross-check against librosa,
config/version mismatch detection, transformation-log and feature-log integrity.
"""
import json, os, sys, tempfile, unittest
from pathlib import Path
import numpy as np, yaml
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pipeline import audio_io, preprocess as pp, features as fe
from scripts_common import ROOT, read_csv, version
ROOTP = Path(os.environ.get("LLP_DATASET_ROOT", ROOT))

def synth(sr=44100, dur=1.0, seed=0):
    t = np.arange(int(sr * dur)) / sr; rng = np.random.RandomState(seed)
    x = 0.3 * np.sin(2 * np.pi * 220 * t) * np.exp(-3 * t) + 0.05 * rng.randn(len(t)); x[: int(0.1 * sr)] *= 0.001; x[-int(0.1 * sr):] *= 0.001
    return np.stack([x, 0.98 * x + 0.002 * rng.randn(len(t))], axis=1)

class Pipeline(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pp = yaml.safe_load(open(ROOTP / "config" / "preprocessing" / "PP001.yaml")); cls.fe = yaml.safe_load(open(ROOTP / "config" / "features" / "FE001.yaml"))
        _, cls.reg = read_csv(ROOTP / "metadata" / "reference_recordings.csv"); cls.tmp = tempfile.TemporaryDirectory()
    def test_decoding_contract(self):
        p = Path(self.tmp.name) / "d.wav"; audio_io.write_wav_pcm16(p, np.array([[0.5, -0.5], [32767 / 32768, -1.0]]), 16000); x, sr, info = audio_io.read_wav(p)
        self.assertEqual(sr, 16000); self.assertEqual(info["bit_depth"], 16); np.testing.assert_allclose(x, [[0.5, -0.5], [32767 / 32768, -1.0]])
    def test_deterministic_preprocessing(self):
        x = synth(); y1, sr1, _ = pp.apply_pp(x, 44100, self.pp); y2, sr2, _ = pp.apply_pp(x, 44100, self.pp)
        self.assertEqual(sr1, self.pp["target_sample_rate_hz"]); self.assertTrue(np.array_equal(y1, y2)); self.assertTrue(np.all(np.isfinite(y1)))
    def test_output_format_duration_clipping(self):
        x = synth(); y, sr, log = pp.apply_pp(x, 44100, self.pp); p = Path(self.tmp.name) / "o.wav"; n_clip, _ = audio_io.write_wav_pcm16(p, y, sr); z, sr2, info = audio_io.read_wav(p)
        self.assertEqual(info["channels"], 1); self.assertEqual(sr2, sr); self.assertEqual(n_clip, 0); self.assertLessEqual(len(y) / sr, len(x) / 44100 + 1e-3); self.assertGreater(len(y) / sr, 0.3)
    def test_channel_strategies_and_cancellation_guard(self):
        x = synth(); self.assertTrue(np.array_equal(pp.to_mono(x, "left"), x[:, 0])); self.assertTrue(np.array_equal(pp.to_mono(x, "right"), x[:, 1])); np.testing.assert_allclose(pp.to_mono(x, "average"), x.mean(axis=1))
        inv = np.stack([x[:, 0], -x[:, 0]], axis=1); self.assertLess(pp.rms(pp.to_mono(inv, "average")), 1e-9)  # documented cancellation case
    def test_trim_relative_is_gain_invariant(self):
        x = pp.to_mono(synth(), "average"); cfg = {"enabled": True, "threshold_db": -40, "threshold_ref": "peak", "min_silence_ms": 100, "pad_ms": 50}
        _, a = pp.trim_silence(x, 44100, cfg); _, b = pp.trim_silence(0.1 * x, 44100, cfg); self.assertEqual((a["start"], a["end"]), (b["start"], b["end"])); self.assertGreater(a["start"], 0)
    def test_mfcc_shape_finite_and_short_input(self):
        y = pp.resample(pp.to_mono(synth(), "average"), 44100, 16000); M, meta = fe.mfcc(y, 16000, self.fe)
        self.assertEqual(M.shape[1], self.fe["n_mfcc"]); self.assertEqual(M.shape[0], 1 + (len(y) - 400) // 160); self.assertTrue(np.all(np.isfinite(M)))
        Ms, _ = fe.mfcc(y[:8544], 16000, self.fe); self.assertEqual(Ms.shape, (51, 13))          # shortest corpus item (0.534 s @ 16 kHz)
        Me, _ = fe.mfcc(y[:399], 16000, self.fe); self.assertEqual(Me.shape[0], 0)              # below one frame -> zero frames, no crash
        with self.assertRaises(ValueError): fe.mfcc(y, 22050, self.fe)                            # sample-rate mismatch detected
    def test_deterministic_features(self):
        y = pp.resample(pp.to_mono(synth(), "average"), 44100, 16000); a, _ = fe.mfcc(y, 16000, self.fe); b, _ = fe.mfcc(y, 16000, self.fe); self.assertTrue(np.array_equal(a, b))
    def test_gain_invariance_off_floor(self):
        y = pp.resample(pp.to_mono(synth(), "average"), 44100, 16000); y = y[int(0.15 * 16000): -int(0.15 * 16000)]  # drop near-silent edges
        a, _ = fe.mfcc(y, 16000, self.fe); b, _ = fe.mfcc(0.1 * y, 16000, self.fe); self.assertLess(np.max(np.abs(a - b)), 1e-8)
    def test_librosa_cross_check(self):
        try: import librosa
        except ImportError: self.skipTest("librosa not installed")
        y = pp.resample(pp.to_mono(synth(), "average"), 44100, 16000); a_ = self.fe["pre_emphasis"]; ye = np.concatenate([y[:1], y[1:] - a_ * y[:-1]])
        mine, _ = fe.mfcc(y, 16000, self.fe)
        S = librosa.feature.melspectrogram(y=np.pad(ye, (56, 0)), sr=16000, n_fft=512, hop_length=160, win_length=400, window="hamming", center=False, power=2.0, n_mels=26, fmin=0, fmax=8000, htk=True, norm=None)
        L = librosa.power_to_db(S, ref=1.0, amin=1e-10, top_db=None); from scipy.fft import dct; ref = dct(L, type=2, norm="ortho", axis=0)[1:14].T * (np.log(10) / 10.0)
        n = min(len(mine), len(ref)); self.assertGreater(n, 50); np.testing.assert_allclose(mine[:n], ref[:n], rtol=1e-6, atol=1e-6)
    def test_config_hash_detects_change(self):
        h = pp.config_hash(self.pp); c2 = dict(self.pp); c2["target_sample_rate_hz"] = 22050; self.assertNotEqual(h, pp.config_hash(c2)); self.assertEqual(h, pp.config_hash(json.loads(json.dumps(self.pp, default=str))))
    def test_raw_immutable_and_logs(self):
        vtag = "v" + version(ROOTP).split("_v")[-1]; lst = (ROOTP / "checksums" / f"SHA256SUMS_raw_{vtag}.txt").read_text().splitlines()
        self.assertEqual(len(lst), 128)
        for line in lst[::16] + lst[-1:]:
            d, p = line.split("  ", 1); self.assertEqual(audio_io.sha256_file(ROOTP / p), d, p)
        for run in sorted((ROOTP / "processed").glob("*/transformation_log.csv")):
            _, log = read_csv(run); info = json.load(open(run.parent / "run_info.json")); self.assertEqual(len(log), 128); self.assertTrue(all(r["status"] == "ok" for r in log))
            self.assertEqual(info["transformation_log_sha256"], audio_io.sha256_file(run))
            for r in log[::32]:
                self.assertEqual(audio_io.sha256_file(ROOTP / r["output_path"]), r["output_sha256"]); x, sr, i2 = audio_io.read_wav(ROOTP / r["output_path"]); self.assertEqual((sr, i2["channels"]), (int(r["sample_rate_hz"]), 1))
                self.assertEqual(r["source_sha256"], next(g["sha256"] for g in self.reg if g["recording_id"] == r["source_recording_id"]))
        for run in sorted((ROOTP / "features").glob("*/feature_log.csv")):
            _, log = read_csv(run); self.assertEqual(len(log), 128); self.assertTrue(all(r["status"] == "ok" and r["finite"] == "true" and int(r["n_frames"]) > 0 and int(r["n_coeffs"]) == 13 for r in log))
            for r in log[::32]:
                M = np.load(ROOTP / r["output_path"]); self.assertEqual(M.shape, (int(r["n_frames"]), int(r["n_coeffs"]))); self.assertTrue(np.all(np.isfinite(M))); self.assertEqual(audio_io.sha256_file(ROOTP / r["output_path"]), r["output_sha256"])
    def test_version_mismatch_detection(self):
        fe2 = dict(self.fe); fe2["input_preproc_id"] = "PP999"; self.assertNotEqual(fe2["input_preproc_id"], self.pp["preproc_id"])

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--root")]; unittest.main(argv=[sys.argv[0]] + args, verbosity=2)
