"""Deterministic preprocessing steps (PP configs). Pure functions on float64 arrays; the order of operations is fixed
by `apply_pp`: decode -> channel conversion -> resample -> DC removal -> normalization -> silence trim.
(Resampling precedes DC removal/normalisation/trim so that trim frame timing is defined at the target rate.)
"""
import hashlib, json
import numpy as np
import soxr

EPS = 1e-12
SOXR_QUALITY = {"HQ": soxr.HQ, "VHQ": soxr.VHQ, "MQ": soxr.MQ, "LQ": soxr.LQ}

def db(v): return 20.0 * np.log10(max(float(v), EPS))
def rms(x): return float(np.sqrt(np.mean(np.square(x)))) if x.size else 0.0
def peak(x): return float(np.max(np.abs(x))) if x.size else 0.0

def to_mono(x, strategy):
    """x: (n, ch). strategy: left | right | average | mono_average (alias) | left_only (alias) | right_only (alias)."""
    s = {"mono_average": "average", "left_only": "left", "right_only": "right"}.get(strategy, strategy)
    if x.ndim == 1 or x.shape[1] == 1: return x.reshape(-1)
    if s == "left": return x[:, 0].copy()
    if s == "right": return x[:, 1].copy()
    if s == "average": return np.mean(x, axis=1)
    raise ValueError(f"unknown channel strategy {strategy}")

def remove_dc(x): return x - np.mean(x) if x.size else x

def gain_for(x, cfg):
    """Linear gain implied by a normalization config {type: none|peak|rms, target_dbfs}."""
    t = (cfg or {}).get("type", "none")
    if t == "none": return 1.0
    target = 10 ** (float(cfg["target_dbfs"]) / 20.0)
    ref = peak(x) if t == "peak" else rms(x) if t == "rms" else None
    if ref is None: raise ValueError(f"unknown normalization type {t}")
    return target / ref if ref > EPS else 1.0

def normalize(x, cfg): return x * gain_for(x, cfg)

def resample(x, sr_in, sr_out, quality="HQ"):
    """Deterministic resampling with libsoxr. Returns float64. Identity when rates match."""
    if int(sr_in) == int(sr_out): return x.astype(np.float64)
    y = soxr.resample(x.astype(np.float32), int(sr_in), int(sr_out), quality=SOXR_QUALITY[quality])
    return y.astype(np.float64)

def frame_rms_db(x, sr, frame_ms=10.0):
    n = max(1, int(round(sr * frame_ms / 1000.0))); nf = len(x) // n
    if nf == 0: return np.array([db(rms(x))]), n
    fr = x[: nf * n].reshape(nf, n)
    return 20.0 * np.log10(np.sqrt(np.mean(fr * fr, axis=1)) + EPS), n

def trim_silence(x, sr, cfg):
    """Energy-based leading/trailing trim. cfg: {enabled, threshold_db, threshold_ref: dbfs|peak, min_silence_ms, pad_ms, frame_ms}.
    A frame is 'active' when its RMS exceeds threshold_db (absolute dBFS, or relative to the file's peak sample level).
    Leading/trailing runs of inactive frames are removed only if they last at least min_silence_ms; pad_ms of context is kept.
    Returns (y, info)."""
    info = {"enabled": bool(cfg.get("enabled", False)), "n_in": int(len(x))}
    if not info["enabled"] or len(x) == 0: info.update(start=0, end=int(len(x)), n_out=int(len(x)), removed_lead_ms=0.0, removed_trail_ms=0.0); return x, info
    frame_ms = float(cfg.get("frame_ms", 10.0)); lvl, n = frame_rms_db(x, sr, frame_ms)
    thr = float(cfg["threshold_db"]) + (db(peak(x)) if cfg.get("threshold_ref", "dbfs") == "peak" else 0.0)
    active = np.where(lvl > thr)[0]
    if active.size == 0: info.update(start=0, end=int(len(x)), n_out=int(len(x)), removed_lead_ms=0.0, removed_trail_ms=0.0, note="no active frame; untouched"); return x, info
    min_frames = int(np.ceil(float(cfg.get("min_silence_ms", 0)) / frame_ms)); pad = int(round(sr * float(cfg.get("pad_ms", 0)) / 1000.0))
    first, last = int(active[0]), int(active[-1])
    start = max(0, first * n - pad) if first >= min_frames else 0
    trail_frames = (len(lvl) - 1 - last)
    end = min(len(x), (last + 1) * n + pad) if trail_frames >= min_frames else len(x)
    y = x[start:end]
    info.update(start=int(start), end=int(end), n_out=int(len(y)), removed_lead_ms=1000.0 * start / sr, removed_trail_ms=1000.0 * (len(x) - end) / sr, threshold_db_abs=float(thr))
    return y, info

def apply_pp(x, sr_in, pp):
    """Apply a PP config dict to (n, ch) float samples. Returns (y_mono, sr_out, log dict)."""
    log = {"channel_handling": pp.get("channel_handling")}
    y = to_mono(x, pp["channel_handling"])
    sr_out = int(pp.get("target_sample_rate_hz", sr_in)); q = (pp.get("resample") or {}).get("quality", "HQ")
    y = resample(y, sr_in, sr_out, q); log["resample"] = {"from": int(sr_in), "to": sr_out, "quality": q, "library": "soxr", "library_version": soxr.__version__, "libsoxr": soxr.__libsoxr_version__}
    if pp.get("dc_offset_removal", False): dc = float(np.mean(y)); y = remove_dc(y); log["dc_removed"] = dc
    g = gain_for(y, pp.get("normalization")); y = y * g; log["normalization_gain"] = float(g); log["normalization"] = pp.get("normalization")
    y, tinfo = trim_silence(y, sr_out, pp.get("silence_trim") or {}); log["silence_trim"] = tinfo
    if (pp.get("noise_reduction") or {}).get("enabled"): raise NotImplementedError("noise_reduction enabled but no method implemented")
    log["peak_out"] = peak(y); log["rms_out"] = rms(y); log["n_out"] = int(len(y)); log["duration_out_sec"] = len(y) / sr_out
    return y, sr_out, log

def config_hash(cfg):
    """Stable hash of a config dict (sorted keys, canonical JSON)."""
    return hashlib.sha256(json.dumps(cfg, sort_keys=True, separators=(",", ":"), default=str).encode()).hexdigest()
