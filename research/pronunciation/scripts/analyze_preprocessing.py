#!/usr/bin/env python3
"""Preprocessing investigation PPINV001 over the validated reference corpus (read-only on raw/).

Measures, for every registered recording: stereo channel relations, level statistics and the mathematical effect
of normalization candidates, silence/trim behaviour under candidate settings, resampling determinism, spectral
energy above candidate Nyquist limits, and MFCC sensitivity to channel choice and gain. Writes machine-readable
per-recording CSVs + summary.json to <root>/experiments/PPINV001/. Does not modify audio; runs no algorithm.
"""
import argparse, datetime as dt, json, platform, sys
from pathlib import Path
import numpy as np, scipy, soxr, yaml
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pipeline import PIPELINE_VERSION, audio_io, preprocess as pp, features as fe
from scripts_common import ROOT, read_csv, write_csv, version

INV = "PPINV001"

def stats(v): v = np.asarray(v, dtype=float); return {"min": float(v.min()), "p05": float(np.percentile(v, 5)), "median": float(np.median(v)), "mean": float(v.mean()), "p95": float(np.percentile(v, 95)), "max": float(v.max())}

def xcorr_lag(a, b, maxlag=40):
    a = a - a.mean(); b = b - b.mean(); best = (0, -np.inf)
    for lag in range(-maxlag, maxlag + 1):
        x, y = (a[lag:], b[:len(b) - lag]) if lag > 0 else (a[:len(a) + lag], b[-lag:]) if lag < 0 else (a, b)
        c = float(np.dot(x, y) / (np.linalg.norm(x) * np.linalg.norm(y) + 1e-12))
        if c > best[1]: best = (lag, c)
    return best

def main():
    ap = argparse.ArgumentParser(description=__doc__); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root)
    _, reg = read_csv(root / "metadata" / "reference_recordings.csv"); ver = version(root)
    pp001 = yaml.safe_load(open(root / "config" / "preprocessing" / "PP001.yaml")); fe001 = yaml.safe_load(open(root / "config" / "features" / "FE001.yaml"))
    out = root / "experiments" / INV; out.mkdir(parents=True, exist_ok=True)
    stereo, levels, trims, resamp, chanfeat = [], [], [], [], []
    trim_cfgs = {"cand_abs-40": {"enabled": True, "threshold_db": -40, "threshold_ref": "dbfs", "min_silence_ms": 100, "pad_ms": 50},
                 "abs-30": {"enabled": True, "threshold_db": -30, "threshold_ref": "dbfs", "min_silence_ms": 100, "pad_ms": 50},
                 "abs-50": {"enabled": True, "threshold_db": -50, "threshold_ref": "dbfs", "min_silence_ms": 100, "pad_ms": 50},
                 "rel-40": {"enabled": True, "threshold_db": -40, "threshold_ref": "peak", "min_silence_ms": 100, "pad_ms": 50},
                 "rel-40_nopad": {"enabled": True, "threshold_db": -40, "threshold_ref": "peak", "min_silence_ms": 100, "pad_ms": 0}}
    fe16 = dict(fe001, input_sample_rate_hz=16000)
    for r in reg:
        x, sr, info = audio_io.read_wav(root / r["raw_audio_path"]); L, R = x[:, 0], x[:, 1]; A = (L + R) / 2.0
        rmsL, rmsR, rmsA = pp.rms(L), pp.rms(R), pp.rms(A); pkL, pkR, pkA = pp.peak(L), pp.peak(R), pp.peak(A)
        corr = float(np.corrcoef(L, R)[0, 1]); lag, lagc = xcorr_lag(L, R)
        canc_db = pp.db(rmsA) - pp.db(max(rmsL, rmsR))          # 0 dB if identical & coherent, -6 dB if one channel silent, << for cancellation
        coh_expect = pp.db((rmsL + rmsR) / 2.0) - pp.db(max(rmsL, rmsR))  # what average would give if perfectly coherent
        st = {"recording_id": r["recording_id"], "corr_LR": corr, "best_lag_samples": lag, "corr_at_best_lag": lagc, "rms_L_dbfs": pp.db(rmsL), "rms_R_dbfs": pp.db(rmsR),
              "rms_A_dbfs": pp.db(rmsA), "peak_L_dbfs": pp.db(pkL), "peak_R_dbfs": pp.db(pkR), "peak_A_dbfs": pp.db(pkA), "rms_diff_LR_db": pp.db(rmsL) - pp.db(rmsR),
              "peak_diff_LR_db": pp.db(pkL) - pp.db(pkR), "dc_L": float(L.mean()), "dc_R": float(R.mean()), "avg_vs_louder_rms_db": canc_db, "coherent_expectation_db": coh_expect,
              "cancellation_loss_db": canc_db - coh_expect, "polarity_inverted": corr < -0.5, "time_offset_flag": lag != 0 and lagc > corr + 0.05,
              "cancellation_flag": (canc_db - coh_expect) < -3.0 or corr < 0.5}
        stereo.append(st)
        # level & normalization candidates (on the average channel and on left, gains are per candidate mono signal)
        for name, m in (("L", L), ("R", R), ("A", A)):
            g_peak = pp.gain_for(m, {"type": "peak", "target_dbfs": -1.0}); g_rms = pp.gain_for(m, {"type": "rms", "target_dbfs": -20.0})
            levels.append({"recording_id": r["recording_id"], "channel": name, "rms_dbfs": pp.db(pp.rms(m)), "peak_dbfs": pp.db(pp.peak(m)), "crest_db": pp.db(pp.peak(m)) - pp.db(pp.rms(m)),
                           "gain_peak-1_db": pp.db(g_peak), "gain_rms-20_db": pp.db(g_rms), "post_rms-20_peak_dbfs": pp.db(pp.peak(m) * g_rms), "clips_after_rms-20": int(pp.peak(m) * g_rms > 1.0)})
        # trimming candidates on the average channel at 16 kHz (trim is evaluated after resampling in apply_pp)
        A16 = pp.resample(A, sr, 16000); dur16 = len(A16) / 16000.0
        lvl, n = pp.frame_rms_db(A16, 16000, 10.0)
        for thr in (-30, -40, -50):
            act = np.where(lvl > thr)[0]; lead = act[0] * 10.0 if act.size else dur16 * 1000; trail = (len(lvl) - 1 - act[-1]) * 10.0 if act.size else 0.0
            trims.append({"recording_id": r["recording_id"], "measure": f"abs_dbfs_{thr}", "duration_ms": dur16 * 1000, "leading_ms": lead, "trailing_ms": trail, "active_ms": (act.size * 10.0) if act.size else 0.0})
        for name, cfg in trim_cfgs.items():
            y, ti = pp.trim_silence(A16, 16000, cfg)
            trims.append({"recording_id": r["recording_id"], "measure": f"trim_{name}", "duration_ms": dur16 * 1000, "leading_ms": ti["removed_lead_ms"], "trailing_ms": ti["removed_trail_ms"],
                          "active_ms": ti["n_out"] / 16.0, "removed_fraction": 1 - ti["n_out"] / ti["n_in"], "frames_after_fe001": fe.frame_signal(y, 400, 160).shape[0]})
        # resampling determinism / duration / band energy
        spec = np.abs(np.fft.rfft(A)) ** 2; fr = np.fft.rfftfreq(len(A), 1 / sr); tot = spec.sum() + 1e-30
        row = {"recording_id": r["recording_id"], "n_in": len(A), "sr_in": sr, "energy_above_8k_frac": float(spec[fr > 8000].sum() / tot), "energy_above_11k_frac": float(spec[fr > 11025].sum() / tot), "energy_above_4k_frac": float(spec[fr > 4000].sum() / tot)}
        for tgt in (16000, 22050):
            y1 = pp.resample(A, sr, tgt); y2 = pp.resample(A, sr, tgt)
            row.update({f"n_{tgt}": len(y1), f"expected_n_{tgt}": int(round(len(A) * tgt / sr)), f"dur_err_ms_{tgt}": 1000 * (len(y1) / tgt - len(A) / sr),
                        f"deterministic_{tgt}": bool(np.array_equal(y1, y2)), f"finite_{tgt}": bool(np.all(np.isfinite(y1))), f"peak_change_db_{tgt}": pp.db(pp.peak(y1)) - pp.db(pp.peak(A)),
                        f"sha_{tgt}": audio_io.sha256_array(y1)[:16]})
        resamp.append(row)
        # channel choice & gain sensitivity at the feature level (FE001 on 16 kHz, no trim/normalisation)
        M = {k: fe.mfcc(pp.resample(v, sr, 16000), 16000, fe16)[0] for k, v in (("L", L), ("R", R), ("A", A))}
        A16r = pp.resample(A, sr, 16000); Mg = fe.mfcc(A16r * 0.25, 16000, fe16)[0]
        floor_frac = {g: fe.floor_hit_fraction(A16r * g, 16000, fe16) for g in (1.0, 0.25)}
        Mt = fe.mfcc(pp.trim_silence(A16r, 16000, trim_cfgs["rel-40"])[0], 16000, fe16)[0]; Mtg = fe.mfcc(pp.trim_silence(A16r * 0.25, 16000, trim_cfgs["rel-40"])[0], 16000, fe16)[0]
        def dist(a, b): return float(np.mean(np.linalg.norm(a - b, axis=1))) if len(a) == len(b) and len(a) else float("nan")
        scale = float(np.mean(np.linalg.norm(M["A"] - M["A"].mean(axis=0), axis=1)))
        chanfeat.append({"recording_id": r["recording_id"], "frames": len(M["A"]), "mfcc_dist_L_vs_R": dist(M["L"], M["R"]), "mfcc_dist_L_vs_A": dist(M["L"], M["A"]), "mfcc_dist_R_vs_A": dist(M["R"], M["A"]),
                         "mfcc_frame_spread_A": scale, "mfcc_dist_gain0.25_vs_1": dist(M["A"], Mg), "max_abs_gain_effect": float(np.max(np.abs(M["A"] - Mg))),
                         "floor_hit_frame_frac_gain1": floor_frac[1.0], "floor_hit_frame_frac_gain0.25": floor_frac[0.25], "max_abs_gain_effect_after_rel40_trim": float(np.max(np.abs(Mt - Mtg))) if len(Mt) == len(Mtg) and len(Mt) else float("nan")})
    for name, rows in (("stereo", stereo), ("levels", levels), ("trim", trims), ("resample", resamp), ("feature_sensitivity", chanfeat)): write_csv(out / f"{name}.csv", list(rows[0].keys()), rows)
    s = {k: stats([r[k] for r in stereo]) for k in ("corr_LR", "rms_diff_LR_db", "peak_diff_LR_db", "cancellation_loss_db", "avg_vs_louder_rms_db", "dc_L", "dc_R")}
    s["n"] = len(stereo); s["polarity_inverted_ids"] = [r["recording_id"] for r in stereo if r["polarity_inverted"]]; s["time_offset_ids"] = [r["recording_id"] for r in stereo if r["time_offset_flag"]]
    s["cancellation_flag_ids"] = [r["recording_id"] for r in stereo if r["cancellation_flag"]]; s["louder_channel"] = {"L": sum(1 for r in stereo if r["rms_diff_LR_db"] > 0), "R": sum(1 for r in stereo if r["rms_diff_LR_db"] < 0)}
    s["corr_below_0.9_ids"] = [r["recording_id"] for r in stereo if r["corr_LR"] < 0.9]; s["lag_nonzero_ids"] = [(r["recording_id"], r["best_lag_samples"]) for r in stereo if r["best_lag_samples"] != 0]
    lv = {ch: {k: stats([r[k] for r in levels if r["channel"] == ch]) for k in ("rms_dbfs", "peak_dbfs", "crest_db", "gain_peak-1_db", "gain_rms-20_db", "post_rms-20_peak_dbfs")} for ch in ("L", "R", "A")}
    lv["clips_after_rms-20"] = {ch: sum(r["clips_after_rms-20"] for r in levels if r["channel"] == ch) for ch in ("L", "R", "A")}
    lv["near_full_scale_A_ids"] = [r["recording_id"] for r in levels if r["channel"] == "A" and r["peak_dbfs"] > -0.5]; lv["quiet_A_ids"] = [r["recording_id"] for r in levels if r["channel"] == "A" and r["peak_dbfs"] < -6]
    tr = {}
    for m in sorted({t["measure"] for t in trims}):
        sub = [t for t in trims if t["measure"] == m]; tr[m] = {"leading_ms": stats([t["leading_ms"] for t in sub]), "trailing_ms": stats([t["trailing_ms"] for t in sub])}
        if "removed_fraction" in sub[0]: tr[m].update({"removed_fraction": stats([t["removed_fraction"] for t in sub]), "min_frames_after": int(min(t["frames_after_fe001"] for t in sub)), "ids_removed_over_20pct": [t["recording_id"] for t in sub if t["removed_fraction"] > 0.2], "ids_frames_below_30": [t["recording_id"] for t in sub if t["frames_after_fe001"] < 30]})
    rs = {f"deterministic_{t}": all(r[f"deterministic_{t}"] for r in resamp) for t in (16000, 22050)}
    rs.update({f"finite_{t}": all(r[f"finite_{t}"] for r in resamp) for t in (16000, 22050)}); rs.update({f"dur_err_ms_{t}": stats([r[f"dur_err_ms_{t}"] for r in resamp]) for t in (16000, 22050)})
    rs.update({f"n_mismatch_{t}": [r["recording_id"] for r in resamp if abs(r[f"n_{t}"] - r[f"expected_n_{t}"]) > 1] for t in (16000, 22050)}); rs.update({f"peak_change_db_{t}": stats([r[f"peak_change_db_{t}"] for r in resamp]) for t in (16000, 22050)})
    rs.update({k: stats([r[k] for r in resamp]) for k in ("energy_above_4k_frac", "energy_above_8k_frac", "energy_above_11k_frac")}); rs["min_n_16000"] = min(r["n_16000"] for r in resamp)
    cf = {k: stats([r[k] for r in chanfeat]) for k in ("mfcc_dist_L_vs_R", "mfcc_dist_L_vs_A", "mfcc_dist_R_vs_A", "mfcc_frame_spread_A", "mfcc_dist_gain0.25_vs_1", "max_abs_gain_effect", "floor_hit_frame_frac_gain1", "floor_hit_frame_frac_gain0.25", "max_abs_gain_effect_after_rel40_trim")}
    cf["files_gain_effect_gt_0.01"] = sum(1 for r in chanfeat if r["max_abs_gain_effect"] > 0.01); cf["files_gain_effect_gt_0.01_after_rel40_trim"] = sum(1 for r in chanfeat if r["max_abs_gain_effect_after_rel40_trim"] > 0.01); cf["frames"] = stats([r["frames"] for r in chanfeat])
    summary = {"investigation_id": INV, "generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "corpus_version": ver, "n_recordings": len(reg),
               "registry_sha256": audio_io.sha256_file(root / "metadata" / "reference_recordings.csv"), "raw_checksums_sha256": audio_io.sha256_file(root / "checksums" / f"SHA256SUMS_raw_{'v' + ver.split('_v')[-1]}.txt"),
               "pipeline_version": PIPELINE_VERSION, "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__, "soxr": soxr.__version__, "libsoxr": soxr.__libsoxr_version__,
               "pp001_hash": pp.config_hash(pp001), "fe001_hash": pp.config_hash(fe001), "trim_candidates": trim_cfgs, "stereo": s, "levels": lv, "trim": tr, "resample": rs, "feature_sensitivity": cf}
    (out / "summary.json").write_text(json.dumps(summary, indent=1)); print(json.dumps({k: summary[k] for k in ("n_recordings", "stereo", "resample", "feature_sensitivity")}, indent=1)[:6000]); print("written", out)

if __name__ == "__main__": main()
