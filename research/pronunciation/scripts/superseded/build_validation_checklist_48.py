#!/usr/bin/env python3
# SUPERSEDED 2026-09-30: built a "select 48 of 128" checklist under an obsolete assumption. All 128 recordings are validated references. Kept for history only; do not run.
"""Build the V01 reference-validation checklist (Markdown) and its machine-readable companion (CSV)
from reports/reference_selection_<ver>.csv. Groups takes by variant_group_id. Assigns no W ids.
Spelling variants across different base names are NOT merged; they are listed as separate items.
"""
import argparse, datetime as dt
from collections import OrderedDict
from pathlib import Path
from common import ROOT, read_csv, write_csv, version

CSV_HEADER = ["item_no","variant_group_id","base_name","source_filenames","n_takes","take_durations_sec","firestore_exact_term_match_ids",
              "selected","selected_take_filename","correct_mansaka_spelling","confirmed_by","confirmation_date","notes"]

def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("--root", default=str(ROOT)); a = p.parse_args(); root = Path(a.root)
    ver = "v" + version(root).split("_v")[-1]
    _, sel = read_csv(root / "reports" / f"reference_selection_{ver}.csv")
    groups = OrderedDict()
    for r in sel: groups.setdefault(r["variant_group_id"], []).append(r)
    items = sorted(groups.values(), key=lambda g: g[0]["base_name"])
    n_files = sum(len(g) for g in items); multi = [g for g in items if len(g) > 1]
    csv_rows, md = [], []
    md += [f"# Reference validation checklist — {version(root)}", "",
           f"Prepared {dt.date.today().isoformat()} for validator V01 and the researcher. Source: {n_files} recordings exported from Supabase `audio/dataset`, grouped into {len(items)} candidate items ({len(multi)} items have more than one take).", "",
           "## Instructions", "",
           "1. Select **exactly 48** items as the validated reference set. Mark `SELECTED?` with `YES` for each; leave the rest blank or `NO`.",
           "2. Where an item has more than one take (marked **MULTIPLE TAKES**), write the **exact source filename** of the validated take in `SELECTED TAKE`. Only one take per item.",
           "3. Write the correct Mansaka spelling of the item in `CORRECT MANSAKA SPELLING`. Filenames are working labels only and may be misspelled.",
           "4. Items with similar filenames (for example `pasaylowak doon` and `pasayluwak doon`, `madyaw` and `madayaw`, `madyaw na gabi` and `madyaw na gabila`) are listed **separately**. Do not treat them as the same item unless you confirm it in `NOTES`; if two entries are the same item, select only one and say so.",
           "5. `Firestore match` means the filename equals a dictionary term in the app's database. It is information only, not a selection.",
           "6. Do not edit, rename or re-record any file during this step. Listen from `staging/supabase_audio_dataset/`.",
           "7. Record your validator code (V01) and the date at the end. Do not assign W-numbers; they are allocated after the 48 are confirmed.", "",
           f"## Candidate items ({len(items)})", ""]
    for n, g in enumerate(items, 1):
        base = g[0]["base_name"]; files = [r["object_name"] for r in g]; durs = [r["duration_sec"] for r in g]
        fs = g[0]["firestore_exact_term_match_ids"]; flag = "  **MULTIPLE TAKES**" if len(g) > 1 else ""
        md += [f"### Item {n:03d} — `{base}`{flag}", ""]
        md += [f"- Takes: {len(g)}"]
        for r in g: md += [f"  - `{r['object_name']}` — {r['duration_sec']} s ({r['candidate_id']})"]
        md += [f"- Firestore dictionary match: {'YES (' + fs + ')' if fs else 'no'}",
               "- SELECTED? ______", "- SELECTED TAKE (exact filename): ______________________",
               "- CORRECT MANSAKA SPELLING: ______________________", "- NOTES: ______________________", ""]
        csv_rows.append({"item_no": f"{n:03d}", "variant_group_id": g[0]["variant_group_id"], "base_name": base, "source_filenames": " | ".join(files),
                         "n_takes": len(g), "take_durations_sec": " | ".join(durs), "firestore_exact_term_match_ids": fs,
                         "selected": "", "selected_take_filename": "", "correct_mansaka_spelling": "", "confirmed_by": "", "confirmation_date": "", "notes": ""})
    md += ["## Sign-off", "", f"Items selected (must equal 48): ______   Validator code: ______   Date: ______", "",
           f"Summary: {len(items)} candidate items, {n_files} recordings, {len(multi)} multiple-take items: " + ", ".join(f"`{g[0]['base_name']}` ({len(g)})" for g in multi) + "."]
    out_md = root / "validation" / f"reference_validation_checklist_{ver}.md"; out_csv = root / "validation" / f"reference_validation_confirmations_{ver}.csv"
    out_md.write_text("\n".join(md) + "\n"); write_csv(out_csv, CSV_HEADER, csv_rows)
    print(f"{out_md}: {len(items)} items, {n_files} recordings, {len(multi)} multi-take"); print(out_csv)

if __name__ == "__main__": main()
