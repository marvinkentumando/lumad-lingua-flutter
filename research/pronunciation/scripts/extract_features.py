#!/usr/bin/env python3
"""Extract MFCC features for an FE config from a processed PP run: features/<PPtag>_<FE>/reference/REF_nnn.npy + feature_log.csv + run_info.json.
Reads the processed PCM16 WAV files (the same bytes a Colab notebook would read), so features are reproducible from the
processed artifacts alone. Artifact format: .npy float32 array of shape (n_frames, n_coeffs), C order.
"""
import argparse, datetime as dt, json, platform, sys
from pathlib import Path
import numpy as np, scipy, yaml
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pipeline import PIPELINE_VERSION, audio_io, preprocess as pp, features as fe
from scripts_common import ROOT, read_csv, write_csv, version

LOG_HEADER = ["feature_file_id","recording_id","processed_file_id","processed_path","processed_sha256","preproc_id","preproc_config_hash","feature_id","feature_config_hash","output_path","output_sha256",
              "sample_rate_hz","n_samples","duration_sec","n_frames","n_coeffs","dtype","finite","pipeline_version","status","error"]

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pp-tag", default="PP001"); ap.add_argument("--fe", default="FE001"); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root)
    fcfg = yaml.safe_load(open(root / "config" / "features" / f"{a.fe}.yaml")); fhash = pp.config_hash(fcfg)
    pdir = root / "processed" / a.pp_tag; pinfo = json.load(open(pdir / "run_info.json")); _, plog = read_csv(pdir / "transformation_log.csv")
    if str(fcfg.get("input_preproc_id")) != pinfo["preproc_id"]: sys.exit(f"{a.fe} expects input_preproc_id {fcfg.get('input_preproc_id')} but run is {pinfo['preproc_id']}")
    out = root / "features" / f"{a.pp_tag}_{a.fe}"; (out / "reference").mkdir(parents=True, exist_ok=True); rows = []
    for i, p in enumerate(plog, 1):
        row = {k: "" for k in LOG_HEADER}; row.update({"feature_file_id": f"FF{i:05d}", "recording_id": p["source_recording_id"], "processed_file_id": p["processed_file_id"], "processed_path": p["output_path"], "processed_sha256": p["output_sha256"],
               "preproc_id": p["preproc_id"], "preproc_config_hash": p["preproc_config_hash"], "feature_id": a.fe, "feature_config_hash": fhash, "pipeline_version": PIPELINE_VERSION})
        dest = out / "reference" / f"{p['source_recording_id']}.npy"; row["output_path"] = dest.relative_to(root).as_posix()
        try:
            if p["status"] != "ok": raise RuntimeError("processed file not ok")
            src = root / p["output_path"]
            if audio_io.sha256_file(src) != p["output_sha256"]: raise RuntimeError("processed file sha256 mismatch with transformation log")
            x, sr, _ = audio_io.read_wav(src); M, meta = fe.mfcc(x.reshape(-1), sr, fcfg); M32 = np.ascontiguousarray(M, dtype=np.float32)
            if M32.shape[0] == 0: raise RuntimeError("zero frames")
            if not np.all(np.isfinite(M32)): raise RuntimeError("non-finite coefficients")
            np.save(dest, M32)
            row.update({"output_sha256": audio_io.sha256_file(dest), "sample_rate_hz": sr, "n_samples": len(x), "duration_sec": round(len(x) / sr, 6), "n_frames": M32.shape[0], "n_coeffs": M32.shape[1], "dtype": "float32", "finite": "true", "status": "ok"})
        except Exception as e:
            row.update({"status": "failed", "finite": "", "error": str(e)[:200]})
        rows.append(row)
    write_csv(out / "feature_log.csv", LOG_HEADER, rows)
    info = {"feature_id": a.fe, "pp_tag": a.pp_tag, "preproc_id": pinfo["preproc_id"], "preproc_status": pinfo["status"], "preproc_config_hash": pinfo["config_hash"], "feature_config": fcfg, "feature_config_hash": fhash,
            "artifact_format": "numpy .npy, float32, shape (n_frames, n_coeffs), C-order", "corpus_version": version(root), "pipeline_version": PIPELINE_VERSION, "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__,
            "generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "n_ok": sum(1 for r in rows if r["status"] == "ok"), "n_failed": sum(1 for r in rows if r["status"] == "failed"),
            "frames_min": min((int(r["n_frames"]) for r in rows if r["status"] == "ok"), default=0), "frames_max": max((int(r["n_frames"]) for r in rows if r["status"] == "ok"), default=0), "feature_log_sha256": audio_io.sha256_file(out / "feature_log.csv")}
    (out / "run_info.json").write_text(json.dumps(info, indent=1, default=str)); print(f"{a.pp_tag}_{a.fe}: {info['n_ok']} ok, {info['n_failed']} failed, frames {info['frames_min']}–{info['frames_max']} -> {out.relative_to(root)}")
    if info["n_failed"]: sys.exit(1)

if __name__ == "__main__": main()
