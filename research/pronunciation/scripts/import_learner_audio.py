#!/usr/bin/env python3
"""Import learner recordings into raw/learner/ (write-once) with full validation and provenance.

  import_learner_audio.py --source <folder> [--speaker S001] [--session CS01] [--date 2026-10-15] [--device phone]
                          [--environment classroom] [--enrol] [--dry-run] [--no-rebuild]

Discovers every file under --source; a file is importable only if its name is Sxxx_Wnnn.<ext> (primary) or Sxxx_Wnnn_Tnn.<ext>
(retake, nn >= 02) with an accepted extension (config/corpus.yaml learner_collection.accepted_formats), the speaker is enrolled
(or --enrol), the word_id is a collection-eligible target in metadata/learner_targets.csv, and no other file in the batch or in
raw/learner/ already carries that recording id. Bytes are copied unchanged (sha256 verified after copy, file set read-only);
an existing file is never overwritten: identical bytes = already_imported, different bytes = rejected (conflict).
A retake needs its previous take present (and should have an exclusion row). Unreadable files are imported and flagged
(readable=false), never dropped. Everything is logged to metadata/learner_import_log.csv (source basename only, no paths
that could identify a person). Then manifest, collection status, checksums and the integrity check are refreshed.
Nothing is fabricated: missing items are reported, not created.
"""
import argparse, datetime as dt, os, shutil, subprocess, sys
from collections import Counter
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, sha256_file, rel, RE_LEARNER, truthy
from probe_audio import probe, HEADER as AQ_HEADER
from learner_common import iso_date_ok

LOG_HEADER = ["import_batch_id","import_date","source_filename","recording_id","speaker_id","word_id","take_number","dest_path","sha256","file_size_bytes","container","codec",
              "sample_rate_hz","channels","duration_sec","readable","status","reason","collection_session_id","recording_date","dataset_version"]

def accepted_exts(c):
    af = c.get("learner_collection", {}).get("accepted_formats", {}) or {}
    return {"." + e.lower() for e in (af.get("lossless_preferred") or ["wav", "flac"]) + (af.get("device_formats_preserved_as_is") or [])}

def enrol(root, spk, session, device, environment):
    hdr, rows = read_csv(root / "metadata" / "participants.csv")
    if any(r["speaker_id"] == spk for r in rows): return False
    order = 1 + max([int(r["enrolment_order"] or 0) for r in rows if r["role"] == "learner"] or [0])
    rows.append({"speaker_id": spk, "role": "learner", "consent_form_ref": "", "enrolment_order": order, "collection_session_ids": session, "device_class": device, "environment_class": environment, "dataset_version": version(root), "notes": ""})
    write_csv(root / "metadata" / "participants.csv", hdr, rows); (root / "raw" / "learner" / spk).mkdir(parents=True, exist_ok=True); return True

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", required=True); ap.add_argument("--speaker", default=""); ap.add_argument("--session", default=""); ap.add_argument("--date", default="")
    ap.add_argument("--device", default=""); ap.add_argument("--environment", default=""); ap.add_argument("--enrol", action="store_true"); ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--no-rebuild", action="store_true"); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root); ver = version(root); c = corpus(root); exts = accepted_exts(c)
    src = Path(a.source)
    if not src.is_dir(): sys.exit(f"--source {src} is not a directory")
    if a.date and not iso_date_ok(a.date): sys.exit("--date must be YYYY-MM-DD")
    _, tg = read_csv(root / "metadata" / "learner_targets.csv"); targets = {t["word_id"]: t for t in tg}
    if not targets: sys.exit("metadata/learner_targets.csv missing or empty: run build_learner_targets.py first")
    _, parts = read_csv(root / "metadata" / "participants.csv"); learners = {p["speaker_id"] for p in parts if p["role"] == "learner"}
    _, exc = read_csv(root / "manifests" / "exclusions.csv"); excluded = {e["recording_id"] for e in exc}
    lh, log = read_csv(root / "metadata" / "learner_import_log.csv"); today = dt.date.today().isoformat()
    batch = f"IMP{today.replace('-', '')}-{1 + sum(1 for b in {l['import_batch_id'] for l in log} if b.startswith('IMP' + today.replace('-', ''))):02d}"
    files = sorted(p for p in src.rglob("*") if p.is_file() and not p.name.startswith("."))
    results = []; warnings = []
    def rec(f, status, reason="", rid="", spk="", w="", tk="", **extra):
        row = {k: "" for k in LOG_HEADER}; row.update({"import_batch_id": batch, "import_date": today, "source_filename": f.name, "recording_id": rid, "speaker_id": spk, "word_id": w, "take_number": tk,
                                                      "status": status, "reason": reason, "collection_session_id": a.session, "recording_date": a.date, "dataset_version": ver}); row.update(extra); results.append(row)
    cand = {}
    for f in files:
        stem = f.stem; m = RE_LEARNER.match(stem); ext = f.suffix.lower()
        if not m:
            hint = "ids are case-sensitive (S001_W001)" if RE_LEARNER.match(stem.upper()) else ("T01 is not allowed: the primary take carries no suffix" if stem.upper().endswith("_T01") else "expected Sxxx_Wnnn or Sxxx_Wnnn_Tnn")
            rec(f, "rejected", f"malformed_id: {hint}"); continue
        if ext not in exts: rec(f, "rejected", f"unsupported_format: {ext or '(none)'} not in {sorted(exts)}", stem); continue
        spk, w, tk = m.group(1), m.group(2), int(m.group(3) or 1)
        if tk < 2 and m.group(3): rec(f, "rejected", "malformed_id: T01 is not allowed", stem, spk, w, tk); continue
        if a.speaker and spk != a.speaker: rec(f, "rejected", f"speaker_mismatch: batch declared for {a.speaker}", stem, spk, w, tk); continue
        if spk not in learners:
            if a.enrol and not a.dry_run: enrol(root, spk, a.session, a.device, a.environment); learners.add(spk); warnings.append(f"enrolled new participant {spk}")
            elif a.enrol: learners.add(spk)
            else: rec(f, "rejected", f"speaker_not_enrolled: run new_participant.py {spk} or pass --enrol", stem, spk, w, tk); continue
        if w not in targets: rec(f, "rejected", "unknown_word_id: not in metadata/learner_targets.csv", stem, spk, w, tk); continue
        if not truthy(targets[w].get("collection_eligible")): rec(f, "rejected", f"item_not_collection_eligible: {targets[w].get('eligibility_notes')}", stem, spk, w, tk); continue
        cand.setdefault(stem, []).append(f)
    for rid, fl in cand.items():
        if len(fl) > 1:
            m = RE_LEARNER.match(rid)
            for f in fl: rec(f, "rejected", f"duplicate_in_batch: {len(fl)} files share recording id {rid} ({', '.join(x.name for x in fl)})", rid, m.group(1), m.group(2), int(m.group(3) or 1))
    singles = {rid: fl[0] for rid, fl in cand.items() if len(fl) == 1}
    existing = {p.stem: p for p in (root / "raw" / "learner").rglob("*") if p.is_file() and p.name != ".gitkeep"} if (root / "raw" / "learner").exists() else {}
    aqh, aq = read_csv(root / "metadata" / "audio_quality.csv"); aqby = {r["file_path"]: r for r in aq}; imported = []
    for rid in sorted(singles):
        f = singles[rid]; m = RE_LEARNER.match(rid); spk, w, tk = m.group(1), m.group(2), int(m.group(3) or 1)
        if tk >= 2:
            prev = f"{spk}_{w}" if tk == 2 else f"{spk}_{w}_T{tk - 1:02d}"
            if prev not in existing and prev not in singles: rec(f, "rejected", f"retake_without_prior_take: {prev} must exist first", rid, spk, w, tk); continue
            if prev not in excluded: warnings.append(f"{rid}: previous take {prev} has no exclusion row yet; log the technical failure in manifests/exclusions.csv")
        sha = sha256_file(f); size = f.stat().st_size
        if rid in existing:
            p = existing[rid]
            if sha256_file(p) == sha: rec(f, "already_imported", f"identical bytes already at {rel(p, root)}", rid, spk, w, tk, dest_path=rel(p, root), sha256=sha, file_size_bytes=size)
            else: rec(f, "rejected", f"conflict_existing_file_differs: {rel(p, root)} holds different bytes; raw is write-once", rid, spk, w, tk, sha256=sha, file_size_bytes=size)
            continue
        dest = root / "raw" / "learner" / spk / f"{rid}{f.suffix.lower()}"
        if a.dry_run: rec(f, "would_import", "", rid, spk, w, tk, dest_path=rel(dest, root) if dest.exists() or True else "", sha256=sha, file_size_bytes=size); continue
        dest.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(f, dest)
        if sha256_file(dest) != sha: dest.unlink(); rec(f, "rejected", "copy_verification_failed", rid, spk, w, tk); continue
        os.chmod(dest, 0o444); existing[rid] = dest
        q = {k: "" for k in AQ_HEADER}; q.update({"recording_id": rid, "file_path": rel(dest, root), "file_size_bytes": size, "sha256": sha, "probe_date": today})
        q.update({k: v for k, v in probe(dest).items() if k in AQ_HEADER}); q["readable"] = str(bool(q["readable"])).lower(); aqby[q["file_path"]] = q
        rec(f, "imported", "" if q["readable"] == "true" else f"unreadable: {q.get('probe_notes', '')}", rid, spk, w, tk, dest_path=q["file_path"], sha256=sha, file_size_bytes=size,
            container=q.get("container", ""), codec=q.get("codec", ""), sample_rate_hz=q.get("sample_rate_hz", ""), channels=q.get("channels", ""), duration_sec=q.get("duration_sec", ""), readable=q["readable"]); imported.append(rid)
    if not a.dry_run:
        write_csv(root / "metadata" / "audio_quality.csv", AQ_HEADER, sorted(aqby.values(), key=lambda r: r["file_path"]))
        write_csv(root / "metadata" / "learner_import_log.csv", LOG_HEADER, log + results)
        if not a.no_rebuild:
            here = Path(__file__).resolve().parent; py = sys.executable
            subprocess.run([py, str(here / "build_manifest.py"), "--root", str(root)], check=True, capture_output=True, text=True)
            if a.session or a.date:
                mh, man = read_csv(root / "manifests" / "manifest.csv")
                for mrow in man:
                    if mrow["recording_id"] in imported:
                        if a.session and not mrow.get("collection_session_id"): mrow["collection_session_id"] = a.session
                        if a.date and not mrow.get("recording_date"): mrow["recording_date"] = a.date
                write_csv(root / "manifests" / "manifest.csv", mh, man)
            for s in (["learner_collection_status.py"], ["checksums.py", "generate"]):
                r = subprocess.run([py, str(here / s[0]), *s[1:], "--root", str(root)], capture_output=True, text=True); print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "", file=sys.stderr) if r.returncode else None
            r = subprocess.run([py, str(here / "check_dataset.py"), "--root", str(root)], capture_output=True, text=True); print("check_dataset:", r.stdout.strip().splitlines()[-1] if r.stdout.strip() else f"exit {r.returncode}")
    cnt = Counter(r["status"] for r in results); reasons = Counter(r["reason"].split(":")[0] for r in results if r["status"] == "rejected")
    print(f"{batch}: {len(files)} files in {src.name}/ -> {dict(cnt)}" + (f"; rejected by reason {dict(reasons)}" if reasons else ""))
    for r in results:
        if r["status"] == "rejected" or (r["status"] == "imported" and r["readable"] == "false"): print(f"  {r['status'].upper():9} {r['source_filename']}: {r['reason']}")
    for w_ in warnings: print(f"  WARNING  {w_}")
    if not a.dry_run and not a.no_rebuild:
        _, st = read_csv(root / "metadata" / "learner_collection_status.csv")
        for s in st:
            if not a.speaker or s["speaker_id"] == a.speaker: print(f"  {s['speaker_id']}: {s['primary_present']}/{s['expected_items']} primaries, missing {s['missing_items_count']}, retakes {s['retakes']}, unreadable {s['unreadable']}, excluded {s['excluded']}")
    return 1 if cnt["rejected"] else 0

if __name__ == "__main__": sys.exit(main())
