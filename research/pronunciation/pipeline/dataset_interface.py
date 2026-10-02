"""Read-only loader contract for the future algorithm-comparison notebook (DTW / HMM / Cosine are NOT implemented here).

    from pipeline.dataset_interface import load_experiment_inputs
    d = load_experiment_inputs(root)            # raises unless the learner dataset is frozen and unchanged since the freeze

Returned dict (all paths relative to root; nothing is modified):
  version, corpus                              VERSION string, config/corpus.yaml
  targets                                      metadata/learner_targets.csv rows (112 items; identity = word_id + mansaka_text)
  references                                   metadata/reference_recordings.csv rows (128 validated references, sha256, raw paths)
  reference_relationships                      {word_id: {reference_recording_ids, primary_playback_reference_id, raw_paths}} — every
                                               validated reference of an item is listed; aggregation across them is an experiment decision
  learner_manifest                             manifest learner rows; learner_included / learner_excluded / learner_pending partitions
  exclusions                                   manifests/exclusions.csv rows
  ratings_pass1, ratings_pass2                 human ratings (pass 2 may be empty); ratings_pass1_by_recording index
  ratings_freeze                               the pass-1 freeze record (sha256 of ratings/targets/manifest/exclusions, PP/FE file hashes)
  pp_config, fe_config, pp_config_hash, fe_config_hash   PP001 / FE001 contents and canonical hashes
"""
import csv, hashlib, json
from pathlib import Path

class DatasetNotFrozen(RuntimeError): pass

def _csv(p):
    p = Path(p)
    if not p.exists(): return []
    with p.open(newline="", encoding="utf-8") as f: return list(csv.DictReader(f))

def _sha(p, chunk=1 << 20):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(chunk), b""): h.update(b)
    return h.hexdigest()

def _truthy(v): return str(v).strip().lower() in {"true", "1", "yes", "y"}

def _yaml(p):
    import yaml
    return yaml.safe_load(Path(p).read_text())

def load_experiment_inputs(root, require_frozen=True, require_frozen_pp=True):
    root = Path(root); ver = (root / "VERSION").read_text().strip(); vt = "v" + ver.split("_v")[-1] if "_v" in ver else ver
    corpus = _yaml(root / "config" / "corpus.yaml") if (root / "config" / "corpus.yaml").exists() else {}
    targets = _csv(root / "metadata" / "learner_targets.csv"); refs = _csv(root / "metadata" / "reference_recordings.csv"); man = _csv(root / "manifests" / "manifest.csv")
    exc = _csv(root / "manifests" / "exclusions.csv"); r1 = _csv(root / "validation" / "ratings.csv"); r2 = _csv(root / "validation" / "ratings_pass2.csv")
    fp = root / "validation" / f"ratings_freeze_{vt}_pass1.json"; freeze = json.loads(fp.read_text()) if fp.exists() else None
    problems = []
    if not targets: problems.append("metadata/learner_targets.csv missing")
    if not freeze: problems.append(f"{fp.relative_to(root)} missing: human ratings are not frozen")
    else:
        for key, path in [("ratings_sha256", "validation/ratings.csv"), ("targets_sha256", "metadata/learner_targets.csv"), ("manifest_sha256", "manifests/manifest.csv"), ("exclusions_sha256", "manifests/exclusions.csv")]:
            if not (root / path).exists() or _sha(root / path) != freeze.get(key): problems.append(f"{path} differs from the frozen record ({key})")
        for cid, info in (freeze.get("configs") or {}).items():
            if not (root / info["path"]).exists() or _sha(root / info["path"]) != info["file_sha256"]: problems.append(f"{info['path']} changed since the freeze")
    pp = _yaml(root / "config" / "preprocessing" / "PP001.yaml"); fe = _yaml(root / "config" / "features" / "FE001.yaml")
    if require_frozen_pp and pp.get("status") != "frozen": problems.append(f"PP001 status is '{pp.get('status')}': provisional preprocessing values must be fixed (new PP id or freeze) before an experiment")
    if require_frozen and problems: raise DatasetNotFrozen("; ".join(problems))
    from pipeline import preprocess as _pp
    regby = {r["recording_id"]: r for r in refs}
    rel = {t["word_id"]: {"reference_recording_ids": [x for x in t["reference_recording_ids"].split(";") if x], "primary_playback_reference_id": t["primary_playback_reference_id"],
                          "raw_paths": [regby[x]["raw_audio_path"] for x in t["reference_recording_ids"].split(";") if x in regby]} for t in targets}
    lrn = [m for m in man if m.get("recording_type") == "learner"]
    return {"version": ver, "corpus": corpus, "targets": targets, "references": refs, "reference_relationships": rel, "learner_manifest": lrn,
            "learner_included": [m for m in lrn if _truthy(m.get("included_in_experiment")) and not m.get("exclusion_id")],
            "learner_excluded": [m for m in lrn if m.get("exclusion_id")], "learner_pending": [m for m in lrn if not _truthy(m.get("included_in_experiment")) and not m.get("exclusion_id")],
            "exclusions": exc, "ratings_pass1": r1, "ratings_pass2": r2, "ratings_pass1_by_recording": {r["recording_id"]: r for r in r1 if r.get("rating_pass", "1") == "1"},
            "ratings_freeze": freeze, "pp_config": pp, "fe_config": fe, "pp_config_hash": _pp.config_hash(pp), "fe_config_hash": _pp.config_hash(fe),
            "readiness_problems": problems}

def summary(d):
    return {"version": d["version"], "n_targets": len(d["targets"]), "n_references": len(d["references"]), "n_learner_recordings": len(d["learner_manifest"]), "n_included": len(d["learner_included"]),
            "n_excluded": len(d["learner_excluded"]), "n_pending": len(d["learner_pending"]), "n_ratings_pass1": len(d["ratings_pass1"]), "n_ratings_pass2": len(d["ratings_pass2"]),
            "ratings_frozen": bool(d["ratings_freeze"]), "ratings_sha256": (d["ratings_freeze"] or {}).get("ratings_sha256"), "pp_status": d["pp_config"].get("status"), "fe_status": d["fe_config"].get("status"),
            "pp_config_hash": d["pp_config_hash"], "fe_config_hash": d["fe_config_hash"], "readiness_problems": d["readiness_problems"]}

if __name__ == "__main__":
    import argparse, os, sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter); ap.add_argument("--root", default=os.environ.get("LLP_DATASET_ROOT", str(Path(__file__).resolve().parents[1]))); ap.add_argument("--allow-unfrozen", action="store_true")
    a = ap.parse_args()
    try: print(json.dumps(summary(load_experiment_inputs(a.root, require_frozen=not a.allow_unfrozen, require_frozen_pp=not a.allow_unfrozen)), indent=1))
    except DatasetNotFrozen as e: print(f"NOT READY: {e}"); sys.exit(1)
