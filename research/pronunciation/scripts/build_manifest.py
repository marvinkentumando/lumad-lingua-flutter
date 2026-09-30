#!/usr/bin/env python3
"""Build/refresh manifests/manifest.csv.

Reference rows come from metadata/reference_recordings.csv (one row per physical validated recording, REF_nnn) and
require the file to be present in raw/reference/. Learner rows are parsed from raw/learner/Sxxx/Sxxx_Wnnn[_Tnn] files.
Editable columns (collection_session_id, recording_date, included_in_experiment, exclusion_id, notes) are preserved.
Reference rows default to included_in_experiment=true (all validated references are corpus members); learner rows
default to false until a rating decision exists. Nothing is fabricated: dates and sessions stay blank until filled.
"""
import argparse
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, rel, RE_LEARNER

HEADER = ["recording_id","recording_type","speaker_id","word_id","mapping_status","variant_group_id","reference_recording_id","take_number",
          "original_audio_path","original_format","original_sha256","duration_sec","readable","collection_session_id","recording_date",
          "validation_status","included_in_experiment","exclusion_id","dataset_version","notes"]
KEEP = ["collection_session_id","recording_date","included_in_experiment","exclusion_id","notes"]

def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("--root", default=str(ROOT)); a = p.parse_args(); root = Path(a.root)
    _, reg = read_csv(root / "metadata" / "reference_recordings.csv")
    _, aq = read_csv(root / "metadata" / "audio_quality.csv"); aq = {r["file_path"]: r for r in aq}
    _, old = read_csv(root / "manifests" / "manifest.csv"); old = {r["recording_id"]: r for r in old}
    ver = version(root); spk = corpus(root).get("reference_speaker_id", "R001"); rows = []
    for r in reg:
        if not r.get("raw_audio_path") or not (root / r["raw_audio_path"]).exists(): continue
        prev = old.get(r["recording_id"], {}); q = aq.get(r["raw_audio_path"], {})
        row = {"recording_id": r["recording_id"], "recording_type": "reference", "speaker_id": spk, "word_id": r.get("word_id", ""), "mapping_status": r.get("mapping_status", ""),
               "variant_group_id": r.get("variant_group_id", ""), "reference_recording_id": r["recording_id"], "take_number": r.get("take_number_filename_derived", ""),
               "original_audio_path": r["raw_audio_path"], "original_format": Path(r["raw_audio_path"]).suffix.lower().lstrip("."), "original_sha256": r["sha256"],
               "duration_sec": q.get("duration_sec") or r.get("duration_sec", ""), "readable": q.get("readable") or r.get("readable", ""),
               "validation_status": r.get("validation_status", ""), "dataset_version": prev.get("dataset_version") or ver}
        for k in KEEP: row[k] = prev.get(k, "")
        row["included_in_experiment"] = row["included_in_experiment"] or "true"
        rows.append(row)
    for f in sorted(x for x in (root / "raw" / "learner").rglob("*") if x.is_file() and x.name != ".gitkeep"):
        m = RE_LEARNER.match(f.stem)
        if not m: print(f"skip (not an id): {rel(f, root)}"); continue
        prev = old.get(f.stem, {}); q = aq.get(rel(f, root), {})
        row = {"recording_id": f.stem, "recording_type": "learner", "speaker_id": m.group(1), "word_id": m.group(2), "mapping_status": "", "variant_group_id": "",
               "reference_recording_id": "", "take_number": int(m.group(3) or 1), "original_audio_path": rel(f, root), "original_format": f.suffix.lower().lstrip("."),
               "original_sha256": q.get("sha256", ""), "duration_sec": q.get("duration_sec", ""), "readable": q.get("readable", ""),
               "validation_status": prev.get("validation_status") or "pending", "dataset_version": prev.get("dataset_version") or ver}
        for k in KEEP: row[k] = prev.get(k, "")
        row["included_in_experiment"] = row["included_in_experiment"] or "false"
        if not q: row["notes"] = (row["notes"] + "; not yet probed (run probe_audio.py)").strip("; ")
        rows.append(row)
    write_csv(root / "manifests" / "manifest.csv", HEADER, rows)
    print(f"manifest: {len(rows)} rows ({sum(1 for r in rows if r['recording_type']=='reference')} reference, {sum(1 for r in rows if r['recording_type']=='learner')} learner)")

if __name__ == "__main__": main()
