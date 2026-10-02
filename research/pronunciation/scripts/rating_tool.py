#!/usr/bin/env python3
"""Human ground-truth tooling: blind rating packages, ingestion with validation, freeze.

  rating_tool.py package  --pass 1 --validator V01 --seed 20261101 [--speakers S001,S002]
  rating_tool.py package  --pass 2 --validator V01 --seed 20261201 [--fraction 0.10]      (requires the pass-1 freeze record)
  rating_tool.py ingest   <package_dir> [--dry-run]
  rating_tool.py validate [--pass 1|2]
  rating_tool.py freeze   --pass 1|2 [--allow-fewer-learners]

package: writes validation/rating_packages/<package_id>/rating_order.csv (randomised with python random.Random(seed); seed, rule and
         sha256 recorded in package.json) listing, per learner recording, the item text, the deterministic primary playback reference
         (metadata/learner_targets.csv) and the audio paths, plus blank rating fields. No algorithm field can appear (guarded).
         Pass 1 covers every active learner take (readable, not excluded) not yet rated by that validator. Pass 2 draws a reproducible
         ~fraction sample (random.Random(seed).sample) of the pass-1 rated recordings and never shows the pass-1 rating.
ingest : validates each completed row (integer 1-5 or unratable+reason, blind_confirmed, ISO date, ids and reference match, no
         duplicate per recording/validator/pass, pass-2 rows only from the sample) and appends to validation/ratings.csv (pass 1) or
         validation/ratings_pass2.csv (pass 2) with RTnnnnnn ids. Pass-1 decisions drive the manifest: rated -> included_in_experiment
         = true; unratable -> exclusion row (UNRATABLE, stage validation) and included = false. Any error -> nothing written.
freeze : refuses unless validation passes and every active learner take has a pass-1 decision (pass 2: every sampled recording);
         writes validation/ratings_freeze_<ver>_pass<k>.json with the sha256 of the ratings file, targets, manifest, exclusions and
         the PP/FE config files. Experiments must cite this record. Ratings are never converted to production tiers here.
"""
import argparse, datetime as dt, json, os, random, sys
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, sha256_file, truthy
from learner_common import (RATING_HEADER, EXCL_HEADER, FORBIDDEN_TERMS, active_takes, learner_rows, validate_ratings, ratings_path, freeze_path, vtag, iso_date_ok, RE_RATING)

ORDER_HEADER = ["sequence","package_id","recording_id","word_id","mansaka_text","speaker_id","take_number","reference_recording_id","reference_audio_path","learner_audio_path",
                "human_rating","validation_status","unratable_reason","blind_confirmed","rating_date","notes"]

def load(root):
    _, tg = read_csv(root / "metadata" / "learner_targets.csv"); _, man = read_csv(root / "manifests" / "manifest.csv"); _, exc = read_csv(root / "manifests" / "exclusions.csv")
    _, reg = read_csv(root / "metadata" / "reference_recordings.csv"); _, vals = read_csv(root / "metadata" / "validators.csv")
    return {t["word_id"]: t for t in tg}, man, exc, {r["recording_id"]: r for r in reg}, {v["validator_code"] for v in vals}

def cmd_package(a, root):
    targets, man, exc, reg, vcodes = load(root); ver = version(root); c = corpus(root); hr = c.get("human_rating", {})
    if a.validator not in vcodes: sys.exit(f"validator {a.validator} not in metadata/validators.csv")
    if not targets: sys.exit("metadata/learner_targets.csv missing: run build_learner_targets.py")
    for h in ORDER_HEADER:
        if any(t in h.lower() for t in FORBIDDEN_TERMS): sys.exit(f"blindness guard: column '{h}' is not allowed in a rating package")
    active, problems = active_takes(man, exc)
    if problems: sys.exit("take consistency problems must be resolved first:\n  " + "\n  ".join(problems))
    speakers = set(a.speakers.split(",")) if a.speakers else None
    _, r1 = read_csv(ratings_path(root, 1)); r1v = {r["recording_id"]: r for r in r1 if r.get("validator_code") == a.validator}
    if a.rating_pass == 1:
        cands = sorted(v["recording_id"] for k, v in active.items() if (speakers is None or k[0] in speakers) and v["recording_id"] not in r1v and v["word_id"] in targets)
        rule = "all active learner takes (highest take per item that is readable and not excluded) without a pass-1 decision by this validator; order = random.Random(seed).shuffle(sorted ids)"
        sampled = []; frac = None
    else:
        fp = freeze_path(root, 1)
        if not fp.exists(): sys.exit(f"pass 2 requires the pass-1 freeze record {fp.name}; run `rating_tool.py freeze --pass 1` first")
        fz = json.loads(fp.read_text())
        if sha256_file(ratings_path(root, 1)) != fz["ratings_sha256"]: sys.exit("validation/ratings.csv changed after the pass-1 freeze; re-freeze before sampling")
        pool = sorted(r for r, row in r1v.items() if row.get("validation_status") == "rated" and (speakers is None or row["speaker_id"] in speakers))
        if not pool: sys.exit("no pass-1 rated recordings to sample from")
        frac = a.fraction if a.fraction is not None else float(hr.get("pass2_fraction", 0.10)); k = max(1, round(frac * len(pool)))
        rng = random.Random(a.seed); sampled = sorted(rng.sample(pool, k)); cands = sampled
        rule = f"random.Random(seed).sample(sorted pass-1 rated ids, k=max(1, round({frac} * {len(pool)})) = {k}); order = random.Random(seed).shuffle after sampling; pass-1 ratings are not included"
    if not cands: sys.exit("nothing to rate: no candidate learner recordings (import learners first, or all are already rated)")
    order = list(cands); random.Random(a.seed).shuffle(order)
    pid = f"RP{a.rating_pass}-{a.validator}-{vtag(ver)}-seed{a.seed}"; pdir = root / "validation" / "rating_packages" / pid
    if pdir.exists(): sys.exit(f"package {pid} already exists; packages are immutable (choose another seed)")
    mb = {m["recording_id"]: m for m in learner_rows(man)}; rows = []
    for i, rid in enumerate(order, 1):
        m = mb[rid]; t = targets[m["word_id"]]; pref = t["primary_playback_reference_id"]
        if pref not in reg: sys.exit(f"{rid}: primary playback reference {pref} not registered")
        rows.append({"sequence": i, "package_id": pid, "recording_id": rid, "word_id": m["word_id"], "mansaka_text": t["mansaka_text"], "speaker_id": m["speaker_id"], "take_number": m.get("take_number", ""),
                     "reference_recording_id": pref, "reference_audio_path": reg[pref]["raw_audio_path"], "learner_audio_path": m["original_audio_path"],
                     "human_rating": "", "validation_status": "", "unratable_reason": "", "blind_confirmed": "", "rating_date": "", "notes": ""})
    pdir.mkdir(parents=True); write_csv(pdir / "rating_order.csv", ORDER_HEADER, rows)
    info = {"package_id": pid, "rating_pass": a.rating_pass, "validator_code": a.validator, "seed": a.seed, "rng": "python random.Random(seed) (Mersenne Twister, CPython stdlib)", "selection_rule": rule,
            "fraction": frac, "n_recordings": len(rows), "speakers": sorted({r["speaker_id"] for r in rows}), "generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "dataset_version": ver,
            "rating_protocol_version": hr.get("protocol_version", "RP1.1"), "reference_policy": hr.get("rating_reference_policy", "primary_playback_reference"),
            "targets_sha256": sha256_file(root / "metadata" / "learner_targets.csv"), "manifest_sha256": sha256_file(root / "manifests" / "manifest.csv"), "order_sha256": sha256_file(pdir / "rating_order.csv"),
            "sampled_recording_ids": sampled, "pass1_freeze_sha256": (json.loads(freeze_path(root, 1).read_text())["ratings_sha256"] if a.rating_pass == 2 else None),
            "algorithm_fields_present": False, "forbidden_terms_checked": list(FORBIDDEN_TERMS), "columns": ORDER_HEADER}
    (pdir / "package.json").write_text(json.dumps(info, indent=1))
    (pdir / "README.txt").write_text(f"""Rating package {pid} — pass {a.rating_pass}, validator {a.validator}, {len(rows)} recordings. Protocol: validation/rating_protocol.md ({info['rating_protocol_version']}).
Work through rating_order.csv in the given sequence. For each row: read the Mansaka target, play reference_audio_path, then play learner_audio_path immediately after
(replays allowed), and fill ONLY these columns: human_rating (integer 1-5), validation_status (rated | unratable), unratable_reason (required when unratable),
blind_confirmed (true: no algorithm output was visible), rating_date (YYYY-MM-DD), notes (optional). Leave a row blank to rate it later.
Do not reorder rows, do not edit other columns, do not listen to another reference than the one listed, do not compare learners with each other.
Return the completed rating_order.csv for `scripts/rating_tool.py ingest validation/rating_packages/{pid}`.
""")
    print(f"package {pid}: {len(rows)} recordings, seed {a.seed}, speakers {info['speakers']}, order sha256 {info['order_sha256'][:16]} -> {pdir.relative_to(root)}")

def cmd_ingest(a, root):
    pdir = Path(a.package); pdir = pdir if pdir.is_absolute() else (root / pdir if (root / pdir).exists() else pdir)
    info = json.loads((pdir / "package.json").read_text()); rp = int(info["rating_pass"]); val = info["validator_code"]; ver = version(root); c = corpus(root); hr = c.get("human_rating", {})
    targets, man, exc, reg, vcodes = load(root); oh, order = read_csv(pdir / "rating_order.csv"); rpath = ratings_path(root, rp); rh, existing = read_csv(rpath)
    if any(any(t in h.lower() for t in FORBIDDEN_TERMS) for h in oh): sys.exit("blindness guard: the returned file carries an algorithm-related column; refuse")
    errors = []; pending = []; new = []; mb = {m["recording_id"]: m for m in learner_rows(man)}; have = {(r["recording_id"], r["validator_code"], str(r["rating_pass"])) for r in existing}
    next_id = 1 + max([int(r["rating_id"][2:]) for r in existing if r.get("rating_id", "").startswith("RT")] or [0]); seen = set()
    for o in order:
        rid = o["recording_id"]; st = (o.get("validation_status") or "").strip(); hrv = (o.get("human_rating") or "").strip()
        if not st and not hrv: pending.append(rid); continue
        if o.get("package_id") != info["package_id"]: errors.append(f"{rid}: package_id mismatch"); continue
        if rid in seen: errors.append(f"{rid}: listed twice in the package file"); continue
        seen.add(rid)
        if rid not in mb: errors.append(f"{rid}: not a learner recording in the manifest"); continue
        m = mb[rid]; t = targets.get(m["word_id"])
        if not t: errors.append(f"{rid}: item {m['word_id']} not in learner targets"); continue
        if o.get("word_id") != m["word_id"] or o.get("speaker_id") != m["speaker_id"]: errors.append(f"{rid}: word_id/speaker_id edited (manifest says {m['word_id']}, {m['speaker_id']})"); continue
        if o.get("reference_recording_id") != t["primary_playback_reference_id"] or o["reference_recording_id"] not in t["reference_recording_ids"].split(";"): errors.append(f"{rid}: reference_recording_id must be the item's primary playback reference {t['primary_playback_reference_id']}"); continue
        if rp == 2 and rid not in set(info.get("sampled_recording_ids", [])): errors.append(f"{rid}: not in the pass-2 sample"); continue
        if (rid, val, str(rp)) in have: errors.append(f"{rid}: already rated by {val} in pass {rp} (duplicate rating rejected)"); continue
        if st == "rated":
            if not RE_RATING.match(hrv): errors.append(f"{rid}: human_rating '{hrv}' is not an integer 1-5"); continue
        elif st == "unratable":
            if hrv: errors.append(f"{rid}: unratable rows must leave human_rating blank"); continue
            if not (o.get("unratable_reason") or "").strip(): errors.append(f"{rid}: unratable requires unratable_reason"); continue
        else: errors.append(f"{rid}: validation_status '{st}' must be rated or unratable"); continue
        if not truthy(o.get("blind_confirmed")): errors.append(f"{rid}: blind_confirmed must be true"); continue
        if not iso_date_ok(o.get("rating_date", "")): errors.append(f"{rid}: rating_date must be YYYY-MM-DD"); continue
        new.append({"rating_id": f"RT{next_id:06d}", "recording_id": rid, "word_id": m["word_id"], "speaker_id": m["speaker_id"], "reference_recording_id": o["reference_recording_id"], "validator_code": val, "rating_pass": rp,
                    "human_rating": hrv, "validation_status": st, "unratable_reason": (o.get("unratable_reason") or "").strip(), "blind_confirmed": "true", "rating_date": o["rating_date"],
                    "rating_protocol_version": hr.get("protocol_version", "RP1.1"), "dataset_version": ver, "notes": (o.get("notes") or "").strip() + (f"; package {info['package_id']}" if True else "")}); next_id += 1
    if errors: print("REJECTED — nothing written:\n  " + "\n  ".join(errors)); return 1
    errs2 = validate_ratings(root, rp, rows=existing + new, manifest=man, targets=list(targets.values()), strict_pass2_sample=(rp == 2))
    if errs2: print("REJECTED — resulting ratings file would be invalid:\n  " + "\n  ".join(errs2[:20])); return 1
    if a.dry_run: print(f"DRY RUN OK: {len(new)} ratings would be appended to {rpath.name}; {len(pending)} rows still pending"); return 0
    if rp == 1 and freeze_path(root, 1).exists(): print(f"REFUSED: pass 1 is frozen ({freeze_path(root, 1).name}); ratings.csv is immutable"); return 1
    write_csv(rpath, RATING_HEADER, existing + new)
    if rp == 1:
        mh, man2 = read_csv(root / "manifests" / "manifest.csv"); eh, exc2 = read_csv(root / "manifests" / "exclusions.csv"); nid = 1 + max([int(e["exclusion_id"][2:]) for e in exc2 if e.get("exclusion_id", "").startswith("EX")] or [0])
        byn = {n["recording_id"]: n for n in new}
        for mrow in man2:
            n = byn.get(mrow["recording_id"])
            if not n: continue
            if n["validation_status"] == "rated" and not mrow.get("exclusion_id"): mrow["included_in_experiment"] = "true"; mrow["validation_status"] = "rated"
            elif n["validation_status"] == "unratable":
                if not mrow.get("exclusion_id"):
                    exc2.append({"exclusion_id": f"EX{nid:04d}", "recording_id": mrow["recording_id"], "speaker_id": mrow["speaker_id"], "word_id": mrow["word_id"], "reason_code": "UNRATABLE", "reason_detail": n["unratable_reason"],
                                 "stage": "validation", "recollection_attempted": "false", "recollection_recording_id": "", "decided_by": val, "decision_date": n["rating_date"], "dataset_version": ver}); mrow["exclusion_id"] = f"EX{nid:04d}"; nid += 1
                mrow["included_in_experiment"] = "false"; mrow["validation_status"] = "unratable"
        write_csv(root / "manifests" / "manifest.csv", mh, man2); write_csv(root / "manifests" / "exclusions.csv", EXCL_HEADER if not eh else eh, exc2)
    print(f"ingested {len(new)} ratings into {rpath.relative_to(root)} (pass {rp}, {val}); {len(pending)} rows pending; rated {sum(1 for n in new if n['validation_status']=='rated')}, unratable {sum(1 for n in new if n['validation_status']=='unratable')}")
    return 0

def cmd_validate(a, root):
    errs = validate_ratings(root, a.rating_pass); _, rows = read_csv(ratings_path(root, a.rating_pass))
    print(f"pass {a.rating_pass}: {len(rows)} rows, {len(errs)} errors" + ("" if not errs else ":\n  " + "\n  ".join(errs[:30]))); return 1 if errs else 0

def cmd_freeze(a, root):
    ver = version(root); c = corpus(root); rp = a.rating_pass; rpath = ratings_path(root, rp); fp = freeze_path(root, rp)
    if fp.exists(): print(f"already frozen: {fp.name}"); return 1
    errs = validate_ratings(root, rp); targets, man, exc, reg, vcodes = load(root); _, rows = read_csv(rpath); val = c.get("human_rating", {}).get("validator_code", "V01")
    active, problems = active_takes(man, exc); errs += problems; excl = {e["recording_id"] for e in exc}
    decided = {r["recording_id"]: r for r in rows if r.get("validation_status") in ("rated", "unratable") and r.get("validator_code") == val}
    if rp == 1:
        if not active: errs.append("no learner recordings imported")
        missing = sorted(v["recording_id"] for v in active.values() if v["recording_id"] not in decided)
        if missing: errs.append(f"{len(missing)} active learner recordings without a pass-1 decision by {val}: {missing[:10]}")
        unx = [r for r in rows if r.get("validation_status") == "unratable" and r["recording_id"] not in excl]
        if unx: errs.append(f"unratable recordings without exclusion rows: {[r['recording_id'] for r in unx][:10]}")
        learners = {v["speaker_id"] for v in active.values()}; mn = int(c.get("learner_collection", {}).get("minimum_learners", 10))
        if len(learners) < mn and not a.allow_fewer_learners: errs.append(f"{len(learners)} learners with recordings; design minimum is {mn} (pass --allow-fewer-learners to freeze a smaller collection deliberately)")
    else:
        f1 = freeze_path(root, 1)
        if not f1.exists(): errs.append("pass 1 must be frozen first")
        elif sha256_file(ratings_path(root, 1)) != json.loads(f1.read_text())["ratings_sha256"]: errs.append("ratings.csv changed after the pass-1 freeze")
        sampled = set()
        for pj in sorted((root / "validation" / "rating_packages").glob("*/package.json")):
            d = json.loads(pj.read_text()); sampled |= set(d.get("sampled_recording_ids", [])) if int(d.get("rating_pass", 0)) == 2 else set()
        if not sampled: errs.append("no pass-2 package exists")
        missing = sorted(s for s in sampled if s not in decided)
        if missing: errs.append(f"{len(missing)} sampled recordings without a pass-2 decision: {missing[:10]}")
    if errs: print("FREEZE REFUSED:\n  " + "\n  ".join(errs)); return 1
    pk = [json.loads(p.read_text())["package_id"] for p in sorted((root / "validation" / "rating_packages").glob("*/package.json")) if int(json.loads(p.read_text())["rating_pass"]) == rp] if (root / "validation" / "rating_packages").exists() else []
    cfg = {k: {"path": p, "file_sha256": sha256_file(root / p), "status": next((l.split(":", 1)[1].strip() for l in (root / p).read_text().splitlines() if l.startswith("status:")), "")} for k, p in [("PP001", "config/preprocessing/PP001.yaml"), ("FE001", "config/features/FE001.yaml")] if (root / p).exists()}
    rec = {"frozen_on": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "dataset_version": ver, "rating_pass": rp, "ratings_file": rpath.relative_to(root).as_posix(), "ratings_sha256": sha256_file(rpath), "n_rows": len(rows),
           "n_rated": sum(1 for r in rows if r.get("validation_status") == "rated"), "n_unratable": sum(1 for r in rows if r.get("validation_status") == "unratable"), "validator_code": val,
           "learners": sorted({r["speaker_id"] for r in rows}), "n_items": len({r["word_id"] for r in rows}), "n_included_learner_recordings": sum(1 for m in learner_rows(man) if truthy(m.get("included_in_experiment"))),
           "targets_sha256": sha256_file(root / "metadata" / "learner_targets.csv"), "manifest_sha256": sha256_file(root / "manifests" / "manifest.csv"), "exclusions_sha256": sha256_file(root / "manifests" / "exclusions.csv"),
           "rating_protocol_version": c.get("human_rating", {}).get("protocol_version", "RP1.1"), "rating_scale_sha256": sha256_file(root / "validation" / "rating_scale.md") if (root / "validation" / "rating_scale.md").exists() else "",
           "packages": pk, "configs": cfg, "rule": "this file is the only admissible ground-truth reference for an experiment; any later change to the ratings file invalidates it and requires a new dataset version"}
    fp.write_text(json.dumps(rec, indent=1)); os.chmod(rpath, 0o444)
    print(f"frozen pass {rp}: {rec['n_rows']} rows ({rec['n_rated']} rated, {rec['n_unratable']} unratable), sha256 {rec['ratings_sha256'][:16]} -> {fp.relative_to(root)}"); return 0

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter); sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("package"); p.add_argument("--pass", dest="rating_pass", type=int, choices=[1, 2], required=True); p.add_argument("--validator", default="V01"); p.add_argument("--seed", type=int, required=True); p.add_argument("--fraction", type=float, default=None); p.add_argument("--speakers", default="")
    p = sub.add_parser("ingest"); p.add_argument("package"); p.add_argument("--dry-run", action="store_true")
    p = sub.add_parser("validate"); p.add_argument("--pass", dest="rating_pass", type=int, choices=[1, 2], default=1)
    p = sub.add_parser("freeze"); p.add_argument("--pass", dest="rating_pass", type=int, choices=[1, 2], required=True); p.add_argument("--allow-fewer-learners", action="store_true")
    for sp in sub.choices.values(): sp.add_argument("--root", default=str(ROOT))
    a = ap.parse_args(); root = Path(a.root)
    return {"package": cmd_package, "ingest": cmd_ingest, "validate": cmd_validate, "freeze": cmd_freeze}[a.cmd](a, root) or 0

if __name__ == "__main__": sys.exit(main())
