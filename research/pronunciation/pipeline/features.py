"""MFCC feature extraction (FE configs) — explicit, documented numpy/scipy implementation.

Definition (all values from the FE config; defaults shown for FE001):
  1. pre-emphasis            y[n] = x[n] - a * x[n-1], a = pre_emphasis (0.97); y[0] = x[0]
  2. framing                 frame_length = round(sr * frame_length_ms/1000) (400 @ 16 kHz, 25 ms),
                             hop = round(sr * frame_step_ms/1000) (160, 10 ms); no padding, no centring:
                             n_frames = 1 + floor((N - frame_length) / hop) for N >= frame_length, else 0
  3. window                  periodic Hamming, scipy.signal.get_window("hamming", frame_length, fftbins=True)
  4. spectrum                power P[k] = |rfft(frame, n_fft)|^2, k = 0..n_fft/2 (no 1/N scaling)
  5. mel filterbank          n_mels triangular filters, HTK mel scale m = 2595*log10(1 + f/700), unit-peak
                             triangles on the linear frequency grid between fmin_hz and fmax_hz (fmax <= sr/2)
  6. log                     log(max(E, 1e-10)) natural log, per mel band
  7. DCT                     scipy.fft.dct(type=2, norm="ortho") along the mel axis
  8. coefficient selection   if include_c0: c[0 : n_mfcc] else c[1 : n_mfcc+1]  (FE001 -> C1..C13)
  9. lifter                  if lifter > 0: c *= 1 + (L/2) sin(pi*i/L); FE001: 0 (off)
 10. log_energy              if enabled, append log(sum(frame^2)) as an extra column; FE001: off
 11. deltas / delta-delta    if enabled, appended (regression window 2); FE001: off
 12. CMVN                    if enabled, per-utterance mean (and variance) normalisation; FE001: off
Gain invariance: a constant gain g scales P by g^2, adds 2*log(g) to every log-mel band, and therefore changes only
the DCT coefficient 0. With include_c0 = false and log_energy = false the output is invariant to level (verified by
the pipeline tests), except through the 1e-10 floor in near-silent frames.
"""
import numpy as np
from scipy.fft import dct, rfft
from scipy.signal import get_window

def hz_to_mel(f): return 2595.0 * np.log10(1.0 + np.asarray(f, dtype=np.float64) / 700.0)
def mel_to_hz(m): return 700.0 * (10.0 ** (np.asarray(m, dtype=np.float64) / 2595.0) - 1.0)

def mel_filterbank(sr, n_fft, n_mels, fmin, fmax):
    fmax = min(float(fmax), sr / 2.0)
    mel_pts = np.linspace(hz_to_mel(fmin), hz_to_mel(fmax), n_mels + 2); hz_pts = mel_to_hz(mel_pts)
    bins = np.arange(n_fft // 2 + 1) * sr / n_fft
    fb = np.zeros((n_mels, len(bins)))
    for i in range(n_mels):
        lo, c, hi = hz_pts[i], hz_pts[i + 1], hz_pts[i + 2]
        up = (bins - lo) / max(c - lo, 1e-12); down = (hi - bins) / max(hi - c, 1e-12)
        fb[i] = np.maximum(0.0, np.minimum(up, down))
    return fb, hz_pts

def frame_signal(x, frame_length, hop):
    n = len(x)
    if n < frame_length: return np.zeros((0, frame_length))
    n_frames = 1 + (n - frame_length) // hop
    idx = np.arange(frame_length)[None, :] + hop * np.arange(n_frames)[:, None]
    return x[idx]

def mfcc(x, sr, fe):
    """Return (M, meta): M shape (n_frames, n_coeffs) float64. x is mono float64 at sample rate sr (must equal fe input rate)."""
    if int(sr) != int(fe["input_sample_rate_hz"]): raise ValueError(f"sample rate {sr} != FE input rate {fe['input_sample_rate_hz']}")
    a = float(fe.get("pre_emphasis", 0.0)); y = np.concatenate([x[:1], x[1:] - a * x[:-1]]) if a and len(x) > 1 else x.astype(np.float64)
    fl = int(round(sr * fe["frame_length_ms"] / 1000.0)); hop = int(round(sr * fe["frame_step_ms"] / 1000.0)); n_fft = int(fe["n_fft"])
    frames = frame_signal(y, fl, hop); meta = {"frame_length": fl, "hop": hop, "n_fft": n_fft, "n_frames": int(frames.shape[0])}
    if frames.shape[0] == 0: return np.zeros((0, int(fe["n_mfcc"]))), meta
    win = get_window(fe.get("window", "hamming"), fl, fftbins=True)
    P = np.abs(rfft(frames * win, n=n_fft, axis=1)) ** 2
    fb, _ = mel_filterbank(sr, n_fft, int(fe["n_mels"]), float(fe.get("fmin_hz", 0)), float(fe.get("fmax_hz", sr / 2)))
    E = P @ fb.T; logE = np.log(np.maximum(E, 1e-10))
    c = dct(logE, type=2, norm="ortho", axis=1)
    n_mfcc = int(fe["n_mfcc"]); c = c[:, :n_mfcc] if fe.get("include_c0", False) else c[:, 1:n_mfcc + 1]
    L = int(fe.get("lifter", 0) or 0)
    if L > 0: c = c * (1.0 + (L / 2.0) * np.sin(np.pi * np.arange(c.shape[1]) / L))
    if fe.get("log_energy", False): c = np.hstack([c, np.log(np.maximum(np.sum(frames ** 2, axis=1), 1e-10))[:, None]])
    d = fe.get("deltas") or {}
    if d.get("delta"):
        dl = _delta(c); c = np.hstack([c, dl]) if not d.get("delta_delta") else np.hstack([c, dl, _delta(dl)])
    cm = fe.get("cmvn") or {}
    if cm.get("enabled"):
        c = c - np.mean(c, axis=0, keepdims=True)
        if cm.get("variance", False): c = c / (np.std(c, axis=0, keepdims=True) + 1e-10)
    meta["n_coeffs"] = int(c.shape[1]); meta["finite"] = bool(np.all(np.isfinite(c)))
    return c, meta

def _delta(c, N=2):
    denom = 2 * sum(i * i for i in range(1, N + 1)); pad = np.pad(c, ((N, N), (0, 0)), mode="edge")
    return sum(i * (pad[N + i: N + i + len(c)] - pad[N - i: N - i + len(c)]) for i in range(1, N + 1)) / denom

def floor_hit_fraction(x, sr, fe):
    """Fraction of frames in which at least one mel band energy falls below the 1e-10 log floor (level-dependent frames)."""
    a = float(fe.get("pre_emphasis", 0.0)); y = np.concatenate([x[:1], x[1:] - a * x[:-1]]) if a and len(x) > 1 else x
    fl = int(round(sr * fe["frame_length_ms"] / 1000.0)); hop = int(round(sr * fe["frame_step_ms"] / 1000.0)); frames = frame_signal(y, fl, hop)
    if frames.shape[0] == 0: return float("nan")
    win = get_window(fe.get("window", "hamming"), fl, fftbins=True); P = np.abs(rfft(frames * win, n=int(fe["n_fft"]), axis=1)) ** 2
    fb, _ = mel_filterbank(sr, int(fe["n_fft"]), int(fe["n_mels"]), float(fe.get("fmin_hz", 0)), float(fe.get("fmax_hz", sr / 2)))
    return float(np.mean(np.any(P @ fb.T < 1e-10, axis=1)))
