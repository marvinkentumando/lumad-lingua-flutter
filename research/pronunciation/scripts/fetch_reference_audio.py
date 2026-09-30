#!/usr/bin/env python3
"""Read-only Supabase Storage tooling for the validated reference recordings.

Uses the same Storage REST endpoints the Flutter SupabaseStorageService uses
(POST /storage/v1/object/list/<bucket>, GET /storage/v1/object/<bucket>/<path>).
It never uploads, deletes, renames, moves or overwrites remote objects, and never prints credentials.

Subcommands
  list     List objects under <bucket>/<prefix>; write staging/supabase_listing_<date>.json and
           refresh metadata/source_objects.csv (existing mapped_word_id / notes are preserved).
  stage    Download every listed object byte-for-byte to staging/supabase_audio_dataset/<object name>,
           verify size against the listing, record sha256 in metadata/source_objects.csv.
  promote  Copy every registered recording (metadata/reference_recordings.csv) from staging to
           raw/reference/REF_nnn.<original ext>. Refuses to overwrite; verifies sha256 after copy.
Credentials: SUPABASE_URL and SUPABASE_ANON_KEY from the environment, else from --env-file.
"""
import argparse, datetime as dt, json, os, shutil, sys
from pathlib import Path
import requests
from common import ROOT, read_csv, write_csv, sha256_file, rel, die

def load_env(env_file):
    url, key = os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_ANON_KEY")
    if (not url or not key) and env_file and Path(env_file).exists():
        for line in Path(env_file).read_text().splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k, v = line.split("=", 1); v = v.strip().strip('"').strip("'")
                if k.strip() == "SUPABASE_URL" and not url: url = v
                if k.strip() == "SUPABASE_ANON_KEY" and not key: key = v
    if not url or not key:
        die("SUPABASE_URL / SUPABASE_ANON_KEY not available (env or --env-file). Nothing printed.")
    return url.rstrip("/"), key

def headers(key):
    return {"apikey": key, "Authorization": f"Bearer {key}"}

def cmd_list(a):
    url, key = load_env(a.env_file)
    items, offset = [], 0
    while True:
        body = {"prefix": a.prefix, "limit": 1000, "offset": offset, "sortBy": {"column": "name", "order": "asc"}}
        try:
            r = requests.post(f"{url}/storage/v1/object/list/{a.bucket}", headers={**headers(key), "Content-Type": "application/json"}, json=body, timeout=60)
        except requests.exceptions.RequestException as e:
            die(f"cannot reach Supabase Storage host ({url.split('//')[-1]}): {type(e).__name__}. If this is a proxy 403, the host is denied by the environment's network policy.")
        if not r.ok:
            die(f"listing failed: HTTP {r.status_code} {r.text[:200]}")
        page = r.json(); items.extend(page)
        if len(page) < 1000: break
        offset += 1000
    today = dt.date.today().isoformat()
    (ROOT / "staging").mkdir(exist_ok=True)
    out = ROOT / "staging" / f"supabase_listing_{a.bucket}_{a.prefix.replace('/','_')}_{today}.json"
    out.write_text(json.dumps(items, indent=1))
    hdr, existing = read_csv(ROOT / "metadata" / "source_objects.csv")
    keep = {r["source_storage_path"]: r for r in existing}
    rows = []
    for it in items:
        name = it.get("name"); is_dir = it.get("id") is None
        md = it.get("metadata") or {}
        path = f"{a.prefix.rstrip('/')}/{name}" if a.prefix else name
        prev = keep.get(path, {})
        rows.append({"source_storage_bucket": a.bucket, "source_storage_path": path, "object_name": name,
                     "size_bytes": "" if is_dir else md.get("size", ""), "mimetype": "folder" if is_dir else md.get("mimetype", ""),
                     "last_modified": it.get("updated_at", ""), "listing_date": today,
                     "staged_path": prev.get("staged_path", ""), "staged_sha256": prev.get("staged_sha256", ""),
                     "mapped_word_id": prev.get("mapped_word_id", ""), "notes": prev.get("notes", "")})
    write_csv(ROOT / "metadata" / "source_objects.csv", hdr, rows)
    print(f"listed {len(items)} entries under {a.bucket}/{a.prefix} -> {rel(out)} and metadata/source_objects.csv")

def cmd_stage(a):
    url, key = load_env(a.env_file)
    hdr, rows = read_csv(ROOT / "metadata" / "source_objects.csv")
    if not rows: die("metadata/source_objects.csv is empty; run `list` first")
    dest_dir = ROOT / "staging" / "supabase_audio_dataset"; dest_dir.mkdir(parents=True, exist_ok=True)
    n = 0
    for r in rows:
        if r.get("mimetype") == "folder" or not r.get("object_name"): continue
        dest = dest_dir / r["object_name"]
        if dest.exists():
            print(f"skip (exists): {dest.name}"); r["staged_path"] = rel(dest); r["staged_sha256"] = sha256_file(dest); continue
        try:
            g = requests.get(f"{url}/storage/v1/object/{r['source_storage_bucket']}/{r['source_storage_path']}", headers=headers(key), timeout=120, stream=True)
        except requests.exceptions.RequestException as e:
            print(f"FAILED {r['source_storage_path']}: {type(e).__name__}"); r["notes"] = f"download failed: {type(e).__name__}"; continue
        if not g.ok: print(f"FAILED {r['source_storage_path']}: HTTP {g.status_code}"); r["notes"] = f"download failed HTTP {g.status_code}"; continue
        tmp = dest.with_suffix(dest.suffix + ".part")
        with tmp.open("wb") as f:
            for chunk in g.iter_content(1 << 20): f.write(chunk)
        size = tmp.stat().st_size
        if r.get("size_bytes") and int(r["size_bytes"]) != size:
            tmp.unlink(); print(f"SIZE MISMATCH {r['object_name']}: listing {r['size_bytes']} vs downloaded {size}"); r["notes"] = "size mismatch; not staged"; continue
        tmp.rename(dest); r["staged_path"] = rel(dest); r["staged_sha256"] = sha256_file(dest); n += 1
    write_csv(ROOT / "metadata" / "source_objects.csv", hdr, rows)
    print(f"staged {n} new objects into {rel(dest_dir)}")

def cmd_promote(a):
    """Copy every staged object listed in metadata/reference_recordings.csv to raw/reference/<recording_id><ext>.
    Byte-for-byte (shutil.copyfile), sha256 verified after copy, never overwrites a differing file, never renames staged files."""
    rh, reg = read_csv(ROOT / "metadata" / "reference_recordings.csv")
    if not reg: die("metadata/reference_recordings.csv is empty; run build_reference_registry.py first")
    ref_dir = ROOT / "raw" / "reference"; ref_dir.mkdir(parents=True, exist_ok=True)
    done = skipped = 0
    for r in reg:
        staged = ROOT / r["staged_path"] if r.get("staged_path") else None
        if not staged or not staged.exists(): print(f"{r['recording_id']}: staged file missing ({r.get('staged_path')}); run `stage`"); continue
        dest = ref_dir / (r["recording_id"] + Path(r["object_name"]).suffix)
        if dest.exists():
            if sha256_file(dest) == r["sha256"]: skipped += 1
            else: print(f"{r['recording_id']}: REFUSING to overwrite {dest.name} (hash differs from registry)")
            r["raw_audio_path"] = rel(dest); continue
        if sha256_file(staged) != r["sha256"]: print(f"{r['recording_id']}: staged file hash != registry; not promoted"); continue
        shutil.copyfile(staged, dest)
        if sha256_file(dest) != r["sha256"]: dest.unlink(); print(f"{r['recording_id']}: copy hash mismatch, removed"); continue
        r["raw_audio_path"] = rel(dest); done += 1
    write_csv(ROOT / "metadata" / "reference_recordings.csv", rh, reg)
    print(f"promoted {done} new reference files into raw/reference/ ({skipped} already present with matching hash)")

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("cmd", choices=["list", "stage", "promote"])
    p.add_argument("--bucket", default="audio"); p.add_argument("--prefix", default="dataset")
    p.add_argument("--env-file", default=str(ROOT.parent / "lumad-lingua-flutter" / ".env"))
    a = p.parse_args(); {"list": cmd_list, "stage": cmd_stage, "promote": cmd_promote}[a.cmd](a)
