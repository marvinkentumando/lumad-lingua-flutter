#!/usr/bin/env python3
"""Build/refresh the canonical registry of validated reference recordings and the vocabulary item table.

Inputs : metadata/source_audio_inventory.csv (probe + sha per object), metadata/source_objects.csv (provenance),
         config/corpus.yaml, metadata/mapping_evidence.csv (from resolve_vocabulary_mapping.py; rows with
         authoritative=true are applied), metadata/reference_mapping_input.csv (human-confirmed mappings written by
         apply_mapping_review.py or by hand), metadata/vocabulary_id_history.csv (stable-id ledger, appended here).
Outputs: metadata/reference_recordings.csv   one row per physical recording (REF_nnn), validation + mapping status
         metadata/vocabulary.csv             one row per vocabulary item that has at least one mapped recording (Wnnn)
         metadata/reference_mapping_input.csv  rows for every UNRESOLVED recording, for the researcher/validator to fill

Rules: REF ids are assigned once (byte-wise sort of object_name) and preserved on rebuild. W ids are preserved on rebuild.
A mapping is created only from (a) an authoritative evidence row (EXACT_TERM_UNIQUE, EXACT_EXAMPLE_SENTENCE_UNIQUE,
EXACT_LESSON_ITEM_UNIQUE; never a recording with a take suffix), or (b) a row in reference_mapping_input.csv that names a
word_id / firestore_word_doc_id / item_key with confirmed_by filled. Filename similarity never creates a mapping.
W ids are allocated once (ledger metadata/vocabulary_id_history.csv) and never renumbered or reused. Nothing here touches audio.
"""
import argparse, datetime as dt, json, re, sys
from collections import OrderedDict, defaultdict
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, rel, RE_WORD

REG_HEADER = ["recording_id","object_name","source_project","source_storage_bucket","source_storage_path","source_public_url_verified","staged_path",
              "raw_audio_path","sha256","file_size_bytes","container","codec","sample_rate_hz","channels","bit_depth","duration_sec","readable",
              "variant_group_id","base_name","variant_suffix","take_number_filename_derived","validation_status","validation_provenance","validator_code",
              "mapping_status","word_id","form_text","mapping_evidence","evidence_category","item_key","firestore_word_doc_id","mapping_confirmed_by","mapping_confirmation_date","dataset_version","notes"]
VOC_HEADER = ["word_id","item_key","item_type","mansaka_text","alternate_forms","translation_en","translation_fil","phonetic","part_of_speech","firestore_word_doc_id","source_collection",
              "source_doc_id","source_field","dictionary_headword","dictionary_entry_ids","dictionary_pos","dictionary_definition","dictionary_book_page","dictionary_homonym_count","gloss_conflict","corroboration",
              "mapping_evidence","evidence_category","reference_recording_ids","reference_count","mapping_confirmed_by","mapping_confirmation_date","dataset_version","notes"]
INPUT_HEADER = ["recording_id","object_name","base_name","variant_group_id","word_id","item_key","firestore_word_doc_id","mansaka_text","translation_en","item_type",
                "source_collection","source_doc_id","evidence_category","review_case_id","confirmed_by","confirmation_date","notes"]
HIST_HEADER = ["word_id","item_key","mansaka_text","assigned_on","assigned_by","evidence_category","recording_ids_at_assignment","dataset_version","note"]

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", default=str(ROOT)); p.add_argument("--project", default="ovdwgowtnlujnbcyldkk"); a = p.parse_args(); root = Path(a.root)
    ver = version(root); c = corpus(root); today = dt.date.today().isoformat()
    _, inv = read_csv(root / "metadata" / "source_audio_inventory.csv")
    _, srcs = read_csv(root / "metadata" / "source_objects.csv"); src_by = {s["object_name"]: s for s in srcs}
    _, old_reg = read_csv(root / "metadata" / "reference_recordings.csv"); old_by_name = {r["object_name"]: r for r in old_reg}
    _, old_voc = read_csv(root / "metadata" / "vocabulary.csv"); old_voc = [v for v in old_voc if v.get("word_id") and RE_WORD.match(v["word_id"]) and v.get("reference_recording_ids")]
    _, mapping_input = read_csv(root / "metadata" / "reference_mapping_input.csv")
    _, evidence = read_csv(root / "metadata" / "mapping_evidence.csv"); ev_by = {e["recording_id"]: e for e in evidence}
    hh, history = read_csv(root / "metadata" / "vocabulary_id_history.csv"); hist_by_key = {h["item_key"]: h["word_id"] for h in history if h.get("item_key")}
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
                    "variant_suffix": suf, "take_number_filename_derived": (int(suf) + 1) if suf.isdigit() else 1, "form_text": re.sub(r"\s*\(\d+\)\s*$", "", Path(r["object_name"]).stem).strip(),
                    "validation_status": c.get("reference_validation", {}).get("status", "validated"),
                    "validation_provenance": "supabase_audio_dataset_export_2026-09-30", "validator_code": c.get("reference_validation", {}).get("validator_code", ""),
                    "mapping_status": "unresolved", "dataset_version": (prev or {}).get("dataset_version") or ver, "notes": (prev or {}).get("notes", "")})
        # preserve previously established mapping
        if prev and prev.get("mapping_status") == "mapped" and prev.get("word_id"):
            for k in ("mapping_status","word_id","mapping_evidence","evidence_category","item_key","firestore_word_doc_id","mapping_confirmed_by","mapping_confirmation_date"): row[k] = prev.get(k, "")
            if not row["item_key"] and row["firestore_word_doc_id"]: row["item_key"] = f"words:{row['firestore_word_doc_id']}"
            if not row["evidence_category"]: row["evidence_category"] = "EXACT_TERM_UNIQUE" if row["mapping_evidence"] == "firestore_exact_term" else "HUMAN_CONFIRMED"
        # evidence (a): authoritative evidence row (never a suffixed take)
        else:
            e = ev_by.get(rid)
            if e and e.get("authoritative") == "true" and e.get("item_key"):
                row.update({"mapping_status": "mapped", "mapping_evidence": "firestore_exact_term" if e["evidence_category"] == "EXACT_TERM_UNIQUE" else ("dictionary_exact" if e["evidence_category"].startswith("DICTIONARY_") else "project_record_exact"), "evidence_category": e["evidence_category"],
                            "item_key": e["item_key"], "firestore_word_doc_id": e["source_doc_id"] if e["evidence_category"] == "EXACT_TERM_UNIQUE" else ""})
            elif e: row["evidence_category"] = e.get("evidence_category", "")
        rows.append(row)
    by_id = {r["recording_id"]: r for r in rows}
    # evidence (b): human-confirmed mapping input
    inp_meta = {}
    for m in mapping_input:
        r = by_id.get(m.get("recording_id", ""))
        if not r or not m.get("confirmed_by", "").strip(): continue
        if not (m.get("word_id") or m.get("firestore_word_doc_id") or m.get("item_key")): continue
        if m.get("firestore_word_doc_id"): r["firestore_word_doc_id"] = m["firestore_word_doc_id"]
        r["item_key"] = m.get("item_key") or (f"words:{m['firestore_word_doc_id']}" if m.get("firestore_word_doc_id") else "") or r.get("item_key") or ""
        if m.get("word_id"): r["word_id"] = m["word_id"]
        r.update({"mapping_status": "mapped", "mapping_evidence": "validator_confirmed" if m["confirmed_by"].upper().startswith("V") else "researcher_confirmed", "evidence_category": "HUMAN_CONFIRMED",
                  "mapping_confirmed_by": m["confirmed_by"], "mapping_confirmation_date": m.get("confirmation_date", "")})
        if m.get("review_case_id"): r["notes"] = (r["notes"] + f"; review {m['review_case_id']}").strip("; ")
        inp_meta[r["item_key"] or r["word_id"]] = m

    # --- vocabulary items: one per distinct item_key (words:<doc>, words_example:<doc>:<sent>, lesson:<id>:<text>, human:<...>) ---
    voc_by_key = OrderedDict(); wid_by_key = {v["item_key"]: v["word_id"] for v in old_voc if v.get("item_key")}
    wid_by_key.update({f"words:{v['firestore_word_doc_id']}": v["word_id"] for v in old_voc if v.get("firestore_word_doc_id") and not v.get("item_key")}); wid_by_key.update(hist_by_key)
    existing_w = {v["word_id"] for v in old_voc} | {r["word_id"] for r in rows if r.get("word_id")} | {h["word_id"] for h in history}
    next_w = 1 + max([int(w[1:]) for w in existing_w if RE_WORD.match(w)] or [0])
    mapped = [r for r in rows if r["mapping_status"] == "mapped"]; new_hist = []
    for r in sorted(mapped, key=lambda x: (x["base_name"], x["recording_id"])):
        key = r["item_key"] or (f"words:{r['firestore_word_doc_id']}" if r["firestore_word_doc_id"] else "") or (f"word_id:{r['word_id']}" if r["word_id"] else "")
        if not key: continue
        r["item_key"] = key
        if key not in voc_by_key:
            wid = r["word_id"] or wid_by_key.get(key)
            if not wid: wid = f"W{next_w:03d}"; next_w += 1
            e = ev_by.get(r["recording_id"], {}); m = inp_meta.get(key, {}); w = words.get(r["firestore_word_doc_id"], {}) if r["firestore_word_doc_id"] else {}
            prevv = next((v for v in old_voc if v["word_id"] == wid), {})
            text = w.get("term") or m.get("mansaka_text") or (e.get("candidate_mansaka_text") if e.get("authoritative") == "true" else "") or prevv.get("mansaka_text", "")
            if not text and prevv: text = prevv.get("mansaka_text", "")
            voc_by_key[key] = {"word_id": wid, "item_key": key, "item_type": m.get("item_type") or e.get("item_type") or prevv.get("item_type") or ("phrase" if len(text.split()) > 1 else "word"),
                               "mansaka_text": text, "translation_en": w.get("translation") or m.get("translation_en") or (e.get("candidate_translation_en") if e.get("authoritative") == "true" else "") or prevv.get("translation_en", ""),
                               "translation_fil": w.get("translationFilipino") or prevv.get("translation_fil", ""), "phonetic": w.get("phonetic") or prevv.get("phonetic", ""), "part_of_speech": w.get("pos") or prevv.get("part_of_speech", ""),
                               "firestore_word_doc_id": r["firestore_word_doc_id"], "source_collection": m.get("source_collection") or e.get("source_collection") or prevv.get("source_collection", ""),
                               "source_doc_id": m.get("source_doc_id") or e.get("source_doc_id") or prevv.get("source_doc_id", ""), "source_field": e.get("source_field") or prevv.get("source_field", ""),
                               "alternate_forms": e.get("dict_all_forms", "") if e.get("dict_all_forms", "") and "|" in e.get("dict_all_forms", "") or "," in e.get("dict_headword", "") else "",
                               "dictionary_headword": e.get("dict_headword", ""), "dictionary_entry_ids": e.get("dict_entry_ids", ""), "dictionary_pos": e.get("dict_pos", ""), "dictionary_definition": e.get("dict_definition", ""),
                               "dictionary_book_page": e.get("dict_book_page", ""), "dictionary_homonym_count": e.get("dict_homonym_count", ""), "gloss_conflict": e.get("gloss_conflict", ""), "corroboration": e.get("corroboration", ""),
                               "mapping_evidence": r["mapping_evidence"], "evidence_category": r["evidence_category"], "reference_recording_ids": [], "mapping_confirmed_by": r["mapping_confirmed_by"],
                               "mapping_confirmation_date": r["mapping_confirmation_date"], "dataset_version": prevv.get("dataset_version") or ver, "notes": prevv.get("notes", "")}
            if key not in hist_by_key and not prevv: new_hist.append({"word_id": wid, "item_key": key, "mansaka_text": text, "assigned_on": today, "assigned_by": "build_reference_registry.py", "evidence_category": r["evidence_category"], "recording_ids_at_assignment": "", "dataset_version": ver, "note": ""})
        r["word_id"] = voc_by_key[key]["word_id"]; voc_by_key[key]["reference_recording_ids"].append(r["recording_id"])
    for h in new_hist: h["recording_ids_at_assignment"] = ";".join(voc_by_key[h["item_key"]]["reference_recording_ids"])
    ledgered = {h["word_id"] for h in history} | {h["word_id"] for h in new_hist}
    for v in voc_by_key.values():   # backfill ids that pre-date the ledger (never renumbered)
        if v["word_id"] not in ledgered: new_hist.append({"word_id": v["word_id"], "item_key": v["item_key"], "mansaka_text": v["mansaka_text"], "assigned_on": today, "assigned_by": "build_reference_registry.py", "evidence_category": v["evidence_category"], "recording_ids_at_assignment": ";".join(v["reference_recording_ids"]), "dataset_version": ver, "note": "backfilled: id existed before the ledger was introduced"}); ledgered.add(v["word_id"])
    if new_hist or not (root / "metadata" / "vocabulary_id_history.csv").exists(): write_csv(root / "metadata" / "vocabulary_id_history.csv", HIST_HEADER, sorted(history + new_hist, key=lambda h: h["word_id"]))
    voc_rows = []
    for v in voc_by_key.values():
        v["reference_count"] = len(v["reference_recording_ids"]); v["reference_recording_ids"] = ";".join(sorted(v["reference_recording_ids"])); voc_rows.append(v)
    voc_rows.sort(key=lambda v: v["word_id"])
    write_csv(root / "metadata" / "reference_recordings.csv", REG_HEADER, rows)
    write_csv(root / "metadata" / "vocabulary.csv", VOC_HEADER, voc_rows)
    inp_by = {m["recording_id"]: m for m in mapping_input}
    inp_rows = [dict(inp_by[r["recording_id"]]) if r["recording_id"] in inp_by else {**{k: "" for k in INPUT_HEADER}, "recording_id": r["recording_id"], "object_name": r["object_name"], "base_name": r["base_name"], "variant_group_id": r["variant_group_id"]}
                for r in rows if r["mapping_status"] == "unresolved" or r["recording_id"] in inp_by]
    write_csv(root / "metadata" / "reference_mapping_input.csv", INPUT_HEADER, inp_rows)
    multi = [v for v in voc_rows if v["reference_count"] > 1]
    print(f"registry: {len(rows)} recordings (expected {expected}); mapped {len(mapped)}, unresolved {len(rows) - len(mapped)}; "
          f"vocabulary items {len(voc_rows)} ({len(multi)} with >1 reference); new ids {[h['word_id'] for h in new_hist]}; mapping input rows {len(inp_rows)}")

if __name__ == "__main__": main()
