#!/usr/bin/env python3
"""Generate derived preprocessed audio for a PP config: processed/<PP>[-candidate]/reference/REF_nnn.wav + transformation_log.csv + run_info.json.
raw/ is read-only. Deterministic: same input bytes + same config + same library versions -> identical output bytes.
Use --candidate while the PP config still holds PROVISIONAL parameters (output directory is suffixed '-candidate' and
run_info.status = 'noncanonical'). Refuses to overwrite an existing output with different bytes unless --force-regenerate.
"""
import argparse, datetime as dt, json, platform, sys
from pathlib import Path
import numpy as np, scipy, soxr, yaml
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pipeline import PIPELINE_VERSION, audio_io, preprocess as pp
from scripts_common import ROOT, read_csv, write_csv, version

LOG_HEADER = ["processed_file_id","source_recording_id","source_path","source_sha256","preproc_id","preproc_config_hash","output_path","output_sha256","sample_rate_hz","channels",
              "n_samples","duration_sec","peak_dbfs","rms_dbfs","normalization_gain_db","trim_removed_lead_ms","trim_removed_trail_ms","clipped_samples","pipeline_version","soxr_version","status","error"]

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pp", default="PP001"); ap.add_argument("--candidate", action="store_true"); ap.add_argument("--force-regenerate", action="store_true"); ap.add_argument("--root", default=str(ROOT))
    a = ap.parse_args(); root = Path(a.root); cfg = yaml.safe_load(open(root / "config" / "preprocessing" / f"{a.pp}.yaml")); chash = pp.config_hash(cfg)
    if cfg.get("status") != "frozen" and not a.candidate: sys.exit(f"{a.pp} status is '{cfg.get('status')}' (not frozen): pass --candidate to generate a noncanonical run")
    tag = a.pp + ("-candidate" if a.candidate else ""); out = root / "processed" / tag; (out / "reference").mkdir(parents=True, exist_ok=True)
    _, reg = read_csv(root / "metadata" / "reference_recordings.csv"); rows = []; ver = version(root)
    for i, r in enumerate(reg, 1):
        src = root / r["raw_audio_path"]; dest = out / "reference" / f"{r['recording_id']}.wav"; row = {k: "" for k in LOG_HEADER}
        row.update({"processed_file_id": f"PF{i:05d}", "source_recording_id": r["recording_id"], "source_path": r["raw_audio_path"], "source_sha256": r["sha256"], "preproc_id": a.pp, "preproc_config_hash": chash,
                    "output_path": dest.relative_to(root).as_posix(), "pipeline_version": PIPELINE_VERSION, "soxr_version": f"{soxr.__version__}/{soxr.__libsoxr_version__}"})
        try:
            if audio_io.sha256_file(src) != r["sha256"]: raise RuntimeError("source sha256 mismatch with registry")
            x, sr, _ = audio_io.read_wav(src); y, sr_out, log = pp.apply_pp(x, sr, cfg)
            if not np.all(np.isfinite(y)): raise RuntimeError("non-finite samples")
            tmp = dest.with_suffix(".tmp.wav"); n_clip, _ = audio_io.write_wav_pcm16(tmp, y, sr_out); new_sha = audio_io.sha256_file(tmp)
            if dest.exists() and audio_io.sha256_file(dest) != new_sha and not a.force_regenerate: tmp.unlink(); raise RuntimeError("existing output differs; use --force-regenerate")
            tmp.replace(dest)
            row.update({"output_sha256": new_sha, "sample_rate_hz": sr_out, "channels": 1, "n_samples": len(y), "duration_sec": round(len(y) / sr_out, 6), "peak_dbfs": round(pp.db(log["peak_out"]), 3), "rms_dbfs": round(pp.db(log["rms_out"]), 3),
                        "normalization_gain_db": round(pp.db(log["normalization_gain"]), 3), "trim_removed_lead_ms": round(log["silence_trim"]["removed_lead_ms"], 3), "trim_removed_trail_ms": round(log["silence_trim"]["removed_trail_ms"], 3), "clipped_samples": n_clip, "status": "ok"})
        except Exception as e:
            row.update({"status": "failed", "error": str(e)[:200]})
        rows.append(row)
    write_csv(out / "transformation_log.csv", LOG_HEADER, rows)
    info = {"preproc_id": a.pp, "run_tag": tag, "status": "noncanonical" if a.candidate else "canonical", "config": cfg, "config_hash": chash, "corpus_version": ver, "registry_sha256": audio_io.sha256_file(root / "metadata" / "reference_recordings.csv"),
            "pipeline_version": PIPELINE_VERSION, "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__, "soxr": soxr.__version__, "libsoxr": soxr.__libsoxr_version__,
            "generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "n_ok": sum(1 for r in rows if r["status"] == "ok"), "n_failed": sum(1 for r in rows if r["status"] == "failed"),
            "transformation_log_sha256": audio_io.sha256_file(out / "transformation_log.csv")}
    (out / "run_info.json").write_text(json.dumps(info, indent=1, default=str)); print(f"{tag}: {info['n_ok']} ok, {info['n_failed']} failed -> {out.relative_to(root)} (status {info['status']})")
    if info["n_failed"]: sys.exit(1)

if __name__ == "__main__": main()
