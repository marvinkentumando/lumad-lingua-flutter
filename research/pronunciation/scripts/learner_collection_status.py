#!/usr/bin/env python3
"""Per-learner collection completeness -> metadata/learner_collection_status.csv + reports/learner_collection_status_<ver>.md.
Expected items = every collection-eligible row of metadata/learner_targets.csv. Reports primaries present, missing items, duplicate
primaries, retakes, unreadable files, excluded recordings, active (ratable) takes, pass-1 rating coverage and take inconsistencies.
Never creates or removes anything; a learner with legitimate technical exclusions is reported, not forced to 112 usable files.
"""
import argparse, datetime as dt
from collections import Counter, defaultdict
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, truthy
from learner_common import active_takes, learner_rows, ratings_path

HEADER = ["speaker_id","expected_items","items_with_any_take","primary_present","retakes","missing_items_count","missing_items","duplicate_primaries","unreadable","excluded",
          "active_ratable","rated_pass1","unratable_pass1","unrated_pass1","inconsistent_takes","dataset_version","status_date"]

def compute(root):
    _, tg = read_csv(root / "metadata" / "learner_targets.csv"); items = sorted(t["word_id"] for t in tg if truthy(t.get("collection_eligible")))
    _, parts = read_csv(root / "metadata" / "participants.csv"); learners = sorted(p["speaker_id"] for p in parts if p["role"] == "learner")
    _, man = read_csv(root / "manifests" / "manifest.csv"); _, exc = read_csv(root / "manifests" / "exclusions.csv"); _, rat = read_csv(ratings_path(root, 1))
    active, problems = active_takes(man, exc); lrn = learner_rows(man); excl = {e["recording_id"] for e in exc}
    r1 = {r["recording_id"]: r for r in rat if r.get("validation_status") in ("rated", "unratable")}
    rows = []; today = dt.date.today().isoformat(); ver = version(root)
    for s in learners:
        mine = [m for m in lrn if m["speaker_id"] == s]; prim = [m for m in mine if int(m.get("take_number") or 1) == 1]
        dupp = sorted(w for w, n in Counter(m["word_id"] for m in prim).items() if n > 1); have = {m["word_id"] for m in mine}
        miss = [w for w in items if w not in have]; act = [v for k, v in active.items() if k[0] == s and k[1] in set(items)]
        rated = [v for v in act if v["recording_id"] in r1 and r1[v["recording_id"]]["validation_status"] == "rated"]; unr = [v for v in act if v["recording_id"] in r1 and r1[v["recording_id"]]["validation_status"] == "unratable"]
        rows.append({"speaker_id": s, "expected_items": len(items), "items_with_any_take": len(have & set(items)), "primary_present": len({m["word_id"] for m in prim}), "retakes": sum(1 for m in mine if int(m.get("take_number") or 1) > 1),
                     "missing_items_count": len(miss), "missing_items": ";".join(miss), "duplicate_primaries": ";".join(dupp), "unreadable": sum(1 for m in mine if not truthy(m.get("readable"))),
                     "excluded": sum(1 for m in mine if m["recording_id"] in excl), "active_ratable": len(act), "rated_pass1": len(rated), "unratable_pass1": len(unr), "unrated_pass1": len(act) - len(rated) - len(unr),
                     "inconsistent_takes": ";".join(p for p in problems if p.startswith(s)), "dataset_version": ver, "status_date": today})
    return rows, items, problems

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root)
    rows, items, problems = compute(root); ver = version(root); vt = "v" + ver.split("_v")[-1] if "_v" in ver else ver
    write_csv(root / "metadata" / "learner_collection_status.csv", HEADER, rows)
    md = [f"# Learner collection status — {ver}", "", f"Generated {dt.date.today().isoformat()}. Expected items per learner: {len(items)} (collection-eligible targets). Nothing here is fabricated: a missing item is a recording still to be collected.", ""]
    if not rows: md.append("No learners enrolled yet. Enrol with `scripts/new_participant.py Sxxx` and import with `scripts/import_learner_audio.py --source <folder>`.")
    else:
        md += ["| Learner | Primaries | Missing | Retakes | Unreadable | Excluded | Active (ratable) | Rated p1 | Unratable p1 | Unrated p1 | Take problems |", "|---|---|---|---|---|---|---|---|---|---|---|"]
        md += [f"| {r['speaker_id']} | {r['primary_present']}/{r['expected_items']} | {r['missing_items_count']} | {r['retakes']} | {r['unreadable']} | {r['excluded']} | {r['active_ratable']} | {r['rated_pass1']} | {r['unratable_pass1']} | {r['unrated_pass1']} | {r['inconsistent_takes'] or '-'} |" for r in rows]
        for r in rows:
            if r["missing_items"]: md += ["", f"Missing for {r['speaker_id']}: {r['missing_items'].replace(';', ', ')}"]
            if r["duplicate_primaries"]: md += ["", f"DUPLICATE PRIMARIES for {r['speaker_id']}: {r['duplicate_primaries']}"]
    if problems: md += ["", "Take consistency problems:"] + [f"- {p}" for p in problems]
    (root / "reports").mkdir(exist_ok=True); (root / "reports" / f"learner_collection_status_{vt}.md").write_text("\n".join(md) + "\n")
    print(f"collection status: {len(rows)} learners, {len(items)} expected items each; " + ("; ".join(f"{r['speaker_id']} {r['primary_present']}/{r['expected_items']}" for r in rows) if rows else "no learners yet"))

if __name__ == "__main__": main()
