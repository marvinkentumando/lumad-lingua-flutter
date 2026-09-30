#!/usr/bin/env python3
"""Inventory a manually exported archive of Supabase bucket `audio`, path `dataset` (read-only on the archive).

- Extracts every entry byte-for-byte to staging/supabase_audio_dataset/<original name> (never overwrites a differing file).
- Records archive provenance (path, sha256, entry count) in staging/source_archive_provenance.json.
- Fills metadata/source_objects.csv (one row per object) and metadata/source_audio_inventory.csv
  (probe results + sha256 + duplicate/variant grouping + Firestore term matches).
Recording ids (REF_nnn) and vocabulary mapping are handled afterwards by build_reference_registry.py.
"""
import argparse, datetime as dt, hashlib, json, os, re, sys, zipfile
from collections import Counter, defaultdict
from pathlib import Path
from common import ROOT, read_csv, write_csv, sha256_file, rel, version
sys.path.insert(0, str(Path(__file__).parent)); from probe_audio import probe

AUDIO_EXT = {".wav", ".m4a", ".mp3", ".aac", ".ogg", ".flac", ".opus", ".webm"}
INV_HEADER = ["object_name","source_storage_path","staged_path","file_size_bytes","sha256","container","codec","sample_rate_hz","channels",
              "bit_depth","duration_sec","bitrate_kbps","readable","probe_tool","probe_notes","base_name","variant_suffix","variant_group_id",
              "variant_group_size","sha256_duplicate_group","firestore_exact_term_match_ids","firestore_match_count","token_count","notes"]

def base_name(name):
    stem = os.path.splitext(name)[0]
    m = re.match(r"^(.*?)\s*\((\d+)\)\s*$", stem)
    base, suf = (m.group(1), m.group(2)) if m else (stem, "")
    return re.sub(r"\s+", " ", base).strip().lower(), suf

def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("archive"); p.add_argument("--bucket", default="audio"); p.add_argument("--prefix", default="dataset")
    p.add_argument("--root", default=str(ROOT)); a = p.parse_args(); root = Path(a.root); today = dt.date.today().isoformat(); ver = version(root)
    arch = Path(a.archive); z = zipfile.ZipFile(arch); infos = [i for i in z.infolist() if not i.is_dir()]
    dest_dir = root / "staging" / "supabase_audio_dataset"; dest_dir.mkdir(parents=True, exist_ok=True)
    words = json.load(open(root / "staging" / "firestore_export" / "words.json")) if (root / "staging" / "firestore_export" / "words.json").exists() else []
    by_term = defaultdict(list)
    for w in words:
        t = (w.get("term_lowercase") or w.get("term") or "").strip().lower()
        if t: by_term[re.sub(r"\s+", " ", t)].append(w["_id"])
    src_rows, inv_rows, non_audio = [], [], []
    for i in sorted(infos, key=lambda x: x.filename):
        name = os.path.basename(i.filename); ext = os.path.splitext(name)[1].lower()
        dest = dest_dir / name
        data = z.read(i)
        if dest.exists():
            if sha256_file(dest) != hashlib.sha256(data).hexdigest(): print(f"REFUSING to overwrite differing staged file: {name}"); continue
        else:
            dest.write_bytes(data)
        sha = sha256_file(dest)
        path = f"{a.prefix}/{name}" if a.prefix else name
        src_rows.append({"source_storage_bucket": a.bucket, "source_storage_path": path, "object_name": name, "size_bytes": i.file_size,
                         "mimetype": "audio/wav" if ext == ".wav" else ("audio/" + ext.lstrip(".") if ext in AUDIO_EXT else "unknown"),
                         "last_modified": dt.datetime(*i.date_time).isoformat(), "listing_date": today, "staged_path": rel(dest, root),
                         "staged_sha256": sha, "mapped_word_id": "", "notes": f"from archive {arch.name}"})
        if ext not in AUDIO_EXT: non_audio.append(name); continue
        pr = probe(dest); base, suf = base_name(name)
        row = {k: "" for k in INV_HEADER}; row.update({k: v for k, v in pr.items() if k in INV_HEADER})
        row.update({"object_name": name, "source_storage_path": path, "staged_path": rel(dest, root), "file_size_bytes": i.file_size, "sha256": sha,
                    "readable": str(bool(pr.get("readable"))).lower(), "base_name": base, "variant_suffix": suf,
                    "firestore_exact_term_match_ids": ";".join(by_term.get(base, [])), "firestore_match_count": len(by_term.get(base, [])),
                    "token_count": len(base.split())})
        inv_rows.append(row)
    # grouping
    groups = defaultdict(list)
    for r in inv_rows: groups[r["base_name"]].append(r)
    gid = {b: f"VG{n:03d}" for n, b in enumerate(sorted(groups), 1)}
    for r in inv_rows: r["variant_group_id"] = gid[r["base_name"]]; r["variant_group_size"] = len(groups[r["base_name"]])
    shas = defaultdict(list)
    for r in inv_rows: shas[r["sha256"]].append(r["object_name"])
    dg = {s: f"DUP{n:03d}" for n, (s, names) in enumerate(sorted((s, n) for s, n in shas.items() if len(n) > 1), 1)}
    for r in inv_rows: r["sha256_duplicate_group"] = dg.get(r["sha256"], "")
    write_csv(root / "metadata" / "source_objects.csv", read_csv(root / "metadata" / "source_objects.csv")[0] or list(src_rows[0].keys()), src_rows)
    write_csv(root / "metadata" / "source_audio_inventory.csv", INV_HEADER, inv_rows)
    json.dump({"archive_path": str(arch), "archive_sha256": sha256_file(arch), "archive_size_bytes": arch.stat().st_size, "entries": len(infos),
               "extracted_to": rel(dest_dir, root), "extraction_date": today, "declared_source": f"Supabase bucket {a.bucket}, path {a.prefix}"},
              open(root / "staging" / "source_archive_provenance.json", "w"), indent=1)
    print(f"entries={len(infos)} audio={len(inv_rows)} non_audio={len(non_audio)} variant_groups={len(groups)} sha_dup_groups={len(dg)} "
          f"firestore_exact_matches={sum(1 for r in inv_rows if r['firestore_match_count'])}")
    if non_audio: print("non-audio:", non_audio)

if __name__ == "__main__": main()
