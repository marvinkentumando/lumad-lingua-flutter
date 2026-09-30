#!/usr/bin/env python3
"""Write manifests/repro_manifest_<ver>.json: everything needed to reproduce processed audio and features elsewhere
(local Python, Google Colab, deployment-equivalence tests): corpus identity, config hashes, software versions,
artifact locations and hashes, and the list of parameters still PROVISIONAL."""
import argparse, datetime as dt, json, platform, sys
from pathlib import Path
import numpy as np, scipy, soxr, yaml
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pipeline import PIPELINE_VERSION, audio_io, preprocess as pp
from scripts_common import ROOT, version

def main():
    ap = argparse.ArgumentParser(description=__doc__); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root); ver = version(root); vtag = "v" + ver.split("_v")[-1]
    m = {"manifest_version": 1, "generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "corpus_version": ver,
         "corpus_identity": {"registry": "metadata/reference_recordings.csv", "registry_sha256": audio_io.sha256_file(root / "metadata" / "reference_recordings.csv"), "raw_checksums": f"checksums/SHA256SUMS_raw_{vtag}.txt",
                             "raw_checksums_sha256": audio_io.sha256_file(root / "checksums" / f"SHA256SUMS_raw_{vtag}.txt"), "n_reference_recordings": sum(1 for _ in open(root / "checksums" / f"SHA256SUMS_raw_{vtag}.txt")) },
         "software": {"pipeline_version": PIPELINE_VERSION, "pipeline_package": "research/pronunciation/pipeline (repo) == <dataset>/pipeline", "python": platform.python_version(), "numpy": np.__version__, "scipy": scipy.__version__, "soxr": soxr.__version__, "libsoxr": soxr.__libsoxr_version__},
         "configs": {}, "runs": {}, "provisional_parameters": {}}
    for kind, sub in (("preprocessing", "preprocessing"), ("features", "features")):
        for f in sorted((root / "config" / sub).glob("*.yaml")):
            cfg = yaml.safe_load(open(f)); m["configs"][f.stem] = {"path": f.relative_to(root).as_posix(), "status": cfg.get("status"), "config_hash": pp.config_hash(cfg), "file_sha256": audio_io.sha256_file(f)}
            ps = cfg.get("parameter_status") or {}; prov = {k: v for k, v in ps.items() if isinstance(v, dict) and str(v.get("status", "")).startswith("PROVISIONAL")}
            if prov: m["provisional_parameters"][f.stem] = prov
    for d in sorted((root / "processed").glob("*/run_info.json")) + sorted((root / "features").glob("*/run_info.json")):
        info = json.load(open(d)); m["runs"][d.parent.relative_to(root).as_posix()] = {k: info.get(k) for k in ("status", "preproc_status", "config_hash", "preproc_config_hash", "feature_config_hash", "n_ok", "n_failed", "generated", "transformation_log_sha256", "feature_log_sha256", "frames_min", "frames_max")}
    for inv in sorted((root / "experiments").glob("PPINV*/summary.json")): m.setdefault("investigations", {})[inv.parent.name] = {"summary_sha256": audio_io.sha256_file(inv), "path": inv.relative_to(root).as_posix()}
    out = root / "manifests" / f"repro_manifest_{vtag}.json"; out.write_text(json.dumps(m, indent=1, default=str)); print("written", out.relative_to(root))

if __name__ == "__main__": main()
