#!/usr/bin/env python3
"""SHA-256 list generation and verification (sha256sum-compatible format, relative paths).
  generate  -> checksums/SHA256SUMS_raw_<ver>.txt, SHA256SUMS_metadata_<ver>.txt, SHA256SUMS_config_<ver>.txt, SHA256SUMS_validation_<ver>.txt
  verify    -> re-hash every listed file of the CURRENT version (all versions with --all); exit 1 on any mismatch or missing file
"""
import argparse, sys
from pathlib import Path
from common import ROOT, version, sha256_file, rel

GROUPS = {"raw": ["raw"], "metadata": ["metadata", "manifests"], "config": ["config"], "validation": ["validation"]}
SKIP = {".gitkeep", "README.md"}

def files_in(root, dirs):
    out = []
    for d in dirs:
        base = root / d
        if base.exists(): out += [p for p in sorted(base.rglob("*")) if p.is_file() and p.name not in SKIP]
    return out

def generate(root, ver):
    (root / "checksums").mkdir(exist_ok=True)
    for g, dirs in GROUPS.items():
        out = root / "checksums" / f"SHA256SUMS_{g}_{'v' + ver.split('_v')[-1] if '_v' in ver else ver}.txt"
        lines = [f"{sha256_file(p)}  {rel(p, root)}" for p in files_in(root, dirs)]
        out.write_text("\n".join(lines) + ("\n" if lines else ""))
        print(f"{out.name}: {len(lines)} files")

def verify(root, all_versions=False):
    ok = True; n = 0
    ver = version(root); vtag = "v" + ver.split("_v")[-1] if "_v" in ver else ver
    lists = sorted((root / "checksums").glob("SHA256SUMS_*.txt"))
    if not all_versions: lists = [l for l in lists if l.name.endswith(f"_{vtag}.txt")]
    for lst in lists:
        for line in lst.read_text().splitlines():
            if not line.strip(): continue
            digest, path = line.split("  ", 1); p = root / path; n += 1
            if not p.exists(): print(f"MISSING  {path}"); ok = False
            elif sha256_file(p) != digest: print(f"MISMATCH {path}"); ok = False
    print(f"verified {n} entries: {'OK' if ok else 'FAILED'}")
    return ok

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("cmd", choices=["generate", "verify"]); p.add_argument("--root", default=str(ROOT)); p.add_argument("--all", action="store_true")
    a = p.parse_args(); root = Path(a.root)
    if a.cmd == "generate": generate(root, version(root))
    else: sys.exit(0 if verify(root, a.all) else 1)
