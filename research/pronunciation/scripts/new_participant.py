#!/usr/bin/env python3
"""Create raw/learner/Sxxx/ and append a participants.csv row (code only, no PII).
Usage: new_participant.py S011 [--session CS03] [--device phone] [--environment classroom]
"""
import argparse, sys
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, RE_SPK

def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("speaker_id"); p.add_argument("--session", default=""); p.add_argument("--device", default=""); p.add_argument("--environment", default=""); p.add_argument("--root", default=str(ROOT))
    a = p.parse_args(); root = Path(a.root)
    if not RE_SPK.match(a.speaker_id) or not a.speaker_id.startswith("S"): sys.exit("speaker_id must look like S001")
    hdr, rows = read_csv(root / "metadata" / "participants.csv")
    if any(r["speaker_id"] == a.speaker_id for r in rows): sys.exit(f"{a.speaker_id} already exists")
    order = 1 + max([int(r["enrolment_order"] or 0) for r in rows if r["role"] == "learner"] or [0])
    rows.append({"speaker_id": a.speaker_id, "role": "learner", "consent_form_ref": "", "enrolment_order": order, "collection_session_ids": a.session,
                 "device_class": a.device, "environment_class": a.environment, "dataset_version": version(root), "notes": ""})
    write_csv(root / "metadata" / "participants.csv", hdr, rows)
    (root / "raw" / "learner" / a.speaker_id).mkdir(parents=True, exist_ok=True)
    print(f"created raw/learner/{a.speaker_id}/ and participants row (enrolment_order={order})")

if __name__ == "__main__": main()
