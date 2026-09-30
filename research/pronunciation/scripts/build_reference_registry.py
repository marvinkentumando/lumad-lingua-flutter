#!/usr/bin/env python3
"""Build/refresh the canonical registry of validated reference recordings and the vocabulary item table.

Inputs : metadata/source_audio_inventory.csv (probe + sha per object), metadata/source_objects.csv (provenance),
         config/corpus.yaml, staging/firestore_export/words.json (dictionary evidence, optional),
         metadata/reference_mapping_input.csv (human-confirmed mappings, optional).
Outputs: metadata/reference_recordings.csv   one row per physical recording (REF_nnn), validation + mapping status
         metadata/vocabulary.csv             one row per vocabulary item that has at least one mapped recording (Wnnn)
         metadata/reference_mapping_input.csv  rows for every UNRESOLVED recording, for the researcher/validator to fill

Rules: REF ids are assigned once (byte-wise sort of object_name) and preserved on rebuild. W ids are preserved on rebuild.
A mapping is created only from (a) an exact, unique Firestore dictionary-term match, or (b) a row in
reference_mapping_input.csv that names a word_id or firestore_word_doc_id with confirmed_by filled.
Filename similarity never creates a mapping. Nothing here touches audio.
"""
import argparse, datetime as dt, json, re
from collections import OrderedDict, defaultdict
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, rel, RE_WORD

REG_HEADER = ["recording_id","object_name","source_project","source_storage_bucket","source_storage_path","source_public_url_verified","staged_path",
              "raw_audio_path","sha256","file_size_bytes","container","codec","sample_rate_hz","channels","bit_depth","duration_sec","readable",
              "variant_group_id","base_name","variant_suffix","take_number_filename_derived","validation_status","validation_provenance","validator_code",
              "mapping_status","word_id","mapping_evidence","firestore_word_doc_id","mapping_confirmed_by","mapping_confirmation_date","dataset_version","notes"]
VOC_HEADER = ["word_id","item_type","mansaka_text","translation_en","translation_fil","phonetic","part_of_speech","firestore_word_doc_id","source_collection",
              "source_doc_id","mapping_evidence","reference_recording_ids","reference_count","mapping_confirmed_by","mapping_confirmation_date","dataset_version","notes"]
INPUT_HEADER = ["recording_id","object_name","base_name","variant_group_id","word_id","firestore_word_doc_id","mansaka_text","same_item_as_recording_id",
                "confirmed_by","confirmation_date","notes"]

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", default=str(ROOT)); p.add_argument("--project", default="ovdwgowtnlujnbcyldkk"); a = p.parse_args(); root = Path(a.root)
    ver = version(root); c = corpus(root); today = dt.date.today().isoformat()
    _, inv = read_csv(root / "metadata" / "source_audio_inventory.csv")
    _, srcs = read_csv(root / "metadata" / "source_objects.csv"); src_by = {s["object_name"]: s for s in srcs}
    _, old_reg = read_csv(root / "metadata" / "reference_recordings.csv"); old_by_name = {r["object_name"]: r for r in old_reg}
    _, old_voc = read_csv(root / "metadata" / "vocabulary.csv"); old_voc = [v for v in old_voc if v.get("word_id") and RE_WORD.match(v["word_id"]) and v.get("reference_recording_ids")]
    _, mapping_input = read_csv(root / "metadata" / "reference_mapping_input.csv")
    wj = root / "staging" / "firestore_export" / "words.json"; words = {w["_id"]: w for w in json.load(open(wj))} if wj.exists() else {}
    if not inv: raise SystemExit("metadata/source_audio_inventory.csv is empty; run inventory_source_archive.py first")
    expected = int(c.get("expected_reference_recordings", 0))
    if expected and len(inv) != expected: print(f"WARNING: inventory has {len(inv)} objects but corpus.yaml expects {expected}")

    # --- assign / preserve recording ids ---
    used = {r["recording_id"] for r in old_reg}; next_n = 1 + max([int(r["recording_id"][4:]) for r in old_reg] or [0])
    rows = []
    for r in sorted(inv, key=lambda x: x["object_name"].encode()):
        prev = old_by_name.get(r["object_name"])
        if prev: rid = prev["recording_id"]
        else:
            rid = f"REF_{next_n:03d}"; next_n += 1
        src = src_by.get(r["object_name"], {}); suf = r.get("variant_suffix", "")
        raw = root / "raw" / "reference" / (rid + Path(r["object_name"]).suffix)
        row = {k: "" for k in REG_HEADER}
        row.update({"recording_id": rid, "object_name": r["object_name"], "source_project": a.project, "source_storage_bucket": src.get("source_storage_bucket", "audio"),
                    "source_storage_path": src.get("source_storage_path", r.get("source_storage_path", "")), "source_public_url_verified": "false",
                    "staged_path": r["staged_path"], "raw_audio_path": rel(raw, root) if raw.exists() else "", "sha256": r["sha256"], "file_size_bytes": r["file_size_bytes"],
                    "container": r["container"], "codec": r["codec"], "sample_rate_hz": r["sample_rate_hz"], "channels": r["channels"], "bit_depth": r["bit_depth"],
                    "duration_sec": r["duration_sec"], "readable": r["readable"], "variant_group_id": r["variant_group_id"], "base_name": r["base_name"],
                    "variant_suffix": suf, "take_number_filename_derived": (int(suf) + 1) if suf.isdigit() else 1,
                    "validation_status": c.get("reference_validation", {}).get("status", "validated"),
                    "validation_provenance": "supabase_audio_dataset_export_2026-09-30", "validator_code": c.get("reference_validation", {}).get("validator_code", ""),
                    "mapping_status": "unresolved", "dataset_version": (prev or {}).get("dataset_version") or ver, "notes": (prev or {}).get("notes", "")})
        # preserve previously established mapping
        if prev and prev.get("mapping_status") == "mapped" and prev.get("word_id"):
            for k in ("mapping_status","word_id","mapping_evidence","firestore_word_doc_id","mapping_confirmed_by","mapping_confirmation_date"): row[k] = prev.get(k, "")
        # evidence (a): exact unique Firestore term match
        elif r.get("firestore_match_count") == "1" and r.get("firestore_exact_term_match_ids") in words:
            row.update({"mapping_status": "mapped", "mapping_evidence": "firestore_exact_term", "firestore_word_doc_id": r["firestore_exact_term_match_ids"]})
        rows.append(row)
    by_id = {r["recording_id"]: r for r in rows}
    # evidence (b): human-confirmed mapping input
    for m in mapping_input:
        r = by_id.get(m.get("recording_id", "")); 
        if not r or not m.get("confirmed_by", "").strip(): continue
        if r["mapping_status"] == "mapped" and not (m.get("word_id") or m.get("firestore_word_doc_id")): continue
        if m.get("firestore_word_doc_id"): r["firestore_word_doc_id"] = m["firestore_word_doc_id"]
        if m.get("word_id"): r["word_id"] = m["word_id"]
        if r["firestore_word_doc_id"] or r["word_id"]:
            r.update({"mapping_status": "mapped", "mapping_evidence": "validator_confirmed" if m["confirmed_by"].upper().startswith("V") else "researcher_confirmed",
                      "mapping_confirmed_by": m["confirmed_by"], "mapping_confirmation_date": m.get("confirmation_date", "")})
            if m.get("mansaka_text"): r["notes"] = (r["notes"] + f"; confirmed mansaka_text={m['mansaka_text']}").strip("; ")

    # --- vocabulary items: one per distinct mapped identity (firestore doc id, else explicit word_id) ---
    voc_by_key = OrderedDict(); wid_by_doc = {v["firestore_word_doc_id"]: v["word_id"] for v in old_voc if v.get("firestore_word_doc_id")}
    existing_w = {v["word_id"] for v in old_voc} | {r["word_id"] for r in rows if r.get("word_id")}
    next_w = 1 + max([int(w[1:]) for w in existing_w if RE_WORD.match(w)] or [0])
    mapped = [r for r in rows if r["mapping_status"] == "mapped"]
    for r in sorted(mapped, key=lambda x: (x["base_name"], x["recording_id"])):
        key = r["firestore_word_doc_id"] or r["word_id"]
        if key not in voc_by_key:
            wid = r["word_id"] or wid_by_doc.get(key)
            if not wid: wid = f"W{next_w:03d}"; next_w += 1
            w = words.get(r["firestore_word_doc_id"], {})
            prevv = next((v for v in old_voc if v["word_id"] == wid), {})
            voc_by_key[key] = {"word_id": wid, "item_type": ("phrase" if len((w.get("term") or r["base_name"]).split()) > 1 else "word") if w else prevv.get("item_type", ""),
                               "mansaka_text": w.get("term", "") or prevv.get("mansaka_text", ""), "translation_en": w.get("translation", "") or "", "translation_fil": w.get("translationFilipino", "") or "",
                               "phonetic": w.get("phonetic", "") or "", "part_of_speech": w.get("pos", "") or "", "firestore_word_doc_id": r["firestore_word_doc_id"],
                               "source_collection": "words" if r["firestore_word_doc_id"] else prevv.get("source_collection", ""), "source_doc_id": r["firestore_word_doc_id"],
                               "mapping_evidence": r["mapping_evidence"], "reference_recording_ids": [], "mapping_confirmed_by": r["mapping_confirmed_by"],
                               "mapping_confirmation_date": r["mapping_confirmation_date"], "dataset_version": prevv.get("dataset_version") or ver, "notes": prevv.get("notes", "")}
        r["word_id"] = voc_by_key[key]["word_id"]; voc_by_key[key]["reference_recording_ids"].append(r["recording_id"])
    voc_rows = []
    for v in voc_by_key.values():
        v["reference_count"] = len(v["reference_recording_ids"]); v["reference_recording_ids"] = ";".join(sorted(v["reference_recording_ids"])); voc_rows.append(v)
    voc_rows.sort(key=lambda v: v["word_id"])
    write_csv(root / "metadata" / "reference_recordings.csv", REG_HEADER, rows)
    write_csv(root / "metadata" / "vocabulary.csv", VOC_HEADER, voc_rows)
    inp_by = {m["recording_id"]: m for m in mapping_input}
    inp_rows = [inp_by.get(r["recording_id"]) or {"recording_id": r["recording_id"], "object_name": r["object_name"], "base_name": r["base_name"], "variant_group_id": r["variant_group_id"],
                "word_id": "", "firestore_word_doc_id": "", "mansaka_text": "", "same_item_as_recording_id": "", "confirmed_by": "", "confirmation_date": "", "notes": ""}
                for r in rows if r["mapping_status"] == "unresolved"]
    write_csv(root / "metadata" / "reference_mapping_input.csv", INPUT_HEADER, inp_rows)
    multi = [v for v in voc_rows if v["reference_count"] > 1]
    print(f"registry: {len(rows)} recordings (expected {expected}); mapped {len(mapped)}, unresolved {len(rows) - len(mapped)}; "
          f"vocabulary items {len(voc_rows)} ({len(multi)} with >1 reference); mapping input rows {len(inp_rows)}")

if __name__ == "__main__": main()
