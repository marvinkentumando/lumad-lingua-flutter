#!/usr/bin/env python3
"""Ingest the completed human review (metadata/mapping_review_queue.csv) and turn decisions into canonical mappings.

For every case with a non-empty `decision`:
  CONFIRM_TEXT_NEW_ITEM  create one item from `authoritative_mansaka_text` (falls back to the filename text only if
                         the reviewer left it blank AND wrote the text is correct in notes -> refused otherwise);
                         all recordings of the case map to it (multi-take cases need takes_same_item=Y)
  CONFIRM_CANDIDATE      map to the prefilled candidate (candidate_word_id / candidate_item_key); `decision_target`
                         may name a specific Firestore doc id, item_key or Wnnn when the candidate was ambiguous
  SAME_AS                map to the same item as another case (`decision_target` = RCnnn) or an existing Wnnn
  SPLIT                  the recordings are NOT one item: the case is expanded into one review row per recording
  EXCLUDE                recordings are validated audio but not a learner target (reason required in notes); they keep
                         validation_status=validated, mapping_status stays unresolved with evidence_category EXCLUDED_BY_REVIEW
  DEFER                  leave unresolved
Validation: allowed decisions only; confirmed_by + confirmation_date required; targets must resolve; a recording may not
receive two different items; SAME_AS chains must terminate in a decided case; W ids are allocated from the ledger and
never reused. Writes metadata/reference_mapping_input.csv (+ audit rows in metadata/mapping_audit_log.csv), then
rebuilds registry, manifest and runs the integrity check. Use --dry-run to validate without writing.
"""
import argparse, datetime as dt, subprocess, sys
from collections import defaultdict
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, RE_WORD
from mapping_common import DECISIONS

AUDIT_HEADER = ["applied_on","review_case_id","decision","decision_target","recording_ids","word_id","item_key","mansaka_text","translation_en","confirmed_by","confirmation_date","notes"]

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(ROOT)); ap.add_argument("--queue", default=None); ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--no-rebuild", action="store_true")
    a = ap.parse_args(); root = Path(a.root); ver = version(root); today = dt.date.today().isoformat()
    qpath = Path(a.queue) if a.queue else root / "metadata" / "mapping_review_queue.csv"
    qh, queue = read_csv(qpath); _, voc = read_csv(root / "metadata" / "vocabulary.csv"); _, reg = read_csv(root / "metadata" / "reference_recordings.csv")
    _, hist = read_csv(root / "metadata" / "vocabulary_id_history.csv"); ih, inp = read_csv(root / "metadata" / "reference_mapping_input.csv")
    reg_by = {r["recording_id"]: r for r in reg}; voc_by_id = {v["word_id"]: v for v in voc}; voc_by_key = {v.get("item_key", ""): v for v in voc if v.get("item_key")}
    fs_to_w = {v["firestore_word_doc_id"]: v["word_id"] for v in voc if v.get("firestore_word_doc_id")}
    used_ids = {v["word_id"] for v in voc} | {h["word_id"] for h in hist} | {r["word_id"] for r in reg if r.get("word_id")}
    next_w = 1 + max([int(w[1:]) for w in used_ids if RE_WORD.match(w)] or [0]); errors = []; cases = {c["review_case_id"]: c for c in queue}
    decided = {k: c for k, c in cases.items() if c.get("decision", "").strip()}
    if not decided: print("no decisions in queue; nothing to apply"); return 0
    # ---- validation ----
    for cid, c in decided.items():
        d = c["decision"].strip().upper(); c["decision"] = d
        if d not in DECISIONS: errors.append(f"{cid}: unknown decision '{d}'"); continue
        if d != "DEFER" and (not c.get("confirmed_by", "").strip() or not c.get("confirmation_date", "").strip()): errors.append(f"{cid}: confirmed_by and confirmation_date required")
        if int(c["n_recordings"]) > 1 and d in ("CONFIRM_TEXT_NEW_ITEM", "CONFIRM_CANDIDATE", "SAME_AS") and c.get("takes_same_item", "").strip().upper() != "Y": errors.append(f"{cid}: multi-take case needs takes_same_item=Y (or decision SPLIT)")
        if d == "CONFIRM_TEXT_NEW_ITEM" and not c.get("authoritative_mansaka_text", "").strip(): errors.append(f"{cid}: authoritative_mansaka_text required for CONFIRM_TEXT_NEW_ITEM")
        if d == "CONFIRM_CANDIDATE" and not (c.get("candidate_word_id") or c.get("candidate_item_key") or c.get("decision_target")): errors.append(f"{cid}: no candidate to confirm")
        if d == "SAME_AS" and not c.get("decision_target", "").strip(): errors.append(f"{cid}: SAME_AS needs decision_target (RCnnn or Wnnn)")
        if d == "EXCLUDE" and not c.get("notes", "").strip(): errors.append(f"{cid}: EXCLUDE needs a reason in notes")
        for rid in c["recording_ids"].split(";"):
            if rid not in reg_by: errors.append(f"{cid}: unknown recording {rid}")
            elif reg_by[rid].get("mapping_status") == "mapped" and d in ("CONFIRM_TEXT_NEW_ITEM", "CONFIRM_CANDIDATE", "SAME_AS"): errors.append(f"{cid}: {rid} is already mapped to {reg_by[rid]['word_id']}")
    # ---- resolve targets (SAME_AS chains) ----
    resolved = {}  # case id -> (word_id or None, item_key, text, translation, item_type, source_collection, source_doc_id)
    new_items = {}
    def resolve(cid, stack=()):
        if cid in resolved: return resolved[cid]
        if cid in stack: errors.append(f"{cid}: circular SAME_AS chain {'->'.join(stack + (cid,))}"); return None
        c = decided.get(cid)
        if not c: errors.append(f"SAME_AS target {cid} has no decision"); return None
        d = c["decision"]; res = None
        if d == "CONFIRM_TEXT_NEW_ITEM":
            text = c["authoritative_mansaka_text"].strip(); key = f"human:{cid}:{text.casefold()}"
            res = dict(word_id=None, item_key=key, text=text, tr=c.get("authoritative_translation_en", "").strip(), item_type="phrase" if len(text.split()) > 1 else "word", coll="human_review", doc=cid)
        elif d == "CONFIRM_CANDIDATE":
            tgt = c.get("decision_target", "").strip(); key = c.get("candidate_item_key", ""); wid = c.get("candidate_word_id", "")
            if tgt:
                if RE_WORD.match(tgt): wid = tgt; key = voc_by_id[tgt]["item_key"] if tgt in voc_by_id else key
                elif tgt in fs_to_w: wid = fs_to_w[tgt]; key = f"words:{tgt}"
                elif ":" in tgt: key = tgt
                else: key = f"words:{tgt}"
            if not key and wid and wid in voc_by_id: key = voc_by_id[wid]["item_key"]
            if not key: errors.append(f"{cid}: cannot resolve candidate target"); return None
            v = voc_by_key.get(key)
            res = dict(word_id=wid or (v["word_id"] if v else None), item_key=key, text=c.get("authoritative_mansaka_text", "").strip() or c.get("candidate_mansaka_text", ""), tr=c.get("authoritative_translation_en", "").strip() or c.get("candidate_translation_en", ""),
                       item_type="phrase" if len((c.get("candidate_mansaka_text") or "x").split()) > 1 else "word", coll=c.get("candidate_source", "").split(":")[0] or "human_review", doc=c.get("candidate_source", "").split(":")[1].split(" ")[0] if ":" in c.get("candidate_source", "") else cid)
        elif d == "SAME_AS":
            tgt = c["decision_target"].strip()
            if RE_WORD.match(tgt):
                if tgt not in voc_by_id: errors.append(f"{cid}: SAME_AS target {tgt} does not exist"); return None
                v = voc_by_id[tgt]; res = dict(word_id=tgt, item_key=v["item_key"], text=v["mansaka_text"], tr=v["translation_en"], item_type=v["item_type"], coll=v["source_collection"], doc=v["source_doc_id"])
            else: res = resolve(tgt, stack + (cid,))
        resolved[cid] = res; return res
    for cid, c in decided.items():
        if c["decision"] in ("CONFIRM_TEXT_NEW_ITEM", "CONFIRM_CANDIDATE", "SAME_AS"): resolve(cid)
    # allocate ids for new items (deterministic: case id order)
    for cid in sorted(resolved):
        res = resolved[cid]
        if res and not res["word_id"]:
            if res["item_key"] in voc_by_key: res["word_id"] = voc_by_key[res["item_key"]]["word_id"]
            elif res["item_key"] in new_items: res["word_id"] = new_items[res["item_key"]]
            else: res["word_id"] = f"W{next_w:03d}"; next_w += 1; new_items[res["item_key"]] = res["word_id"]
    # conflicts: one recording -> one item
    assign = defaultdict(set)
    for cid, res in resolved.items():
        if res:
            for rid in decided[cid]["recording_ids"].split(";"): assign[rid].add(res["word_id"])
    for rid, ws in assign.items():
        if len(ws) > 1: errors.append(f"{rid}: conflicting items {sorted(ws)}")
    if errors:
        print("REJECTED — fix the review file:"); [print("  -", e) for e in errors]; return 1
    # ---- write mapping input, audit, split rows ----
    inp_by = {r["recording_id"]: r for r in inp}; audit = []; n_map = 0; new_rows_for_queue = []
    for cid, c in decided.items():
        d = c["decision"]; rids = c["recording_ids"].split(";")
        if d in ("CONFIRM_TEXT_NEW_ITEM", "CONFIRM_CANDIDATE", "SAME_AS"):
            res = resolved[cid]
            for rid in rids:
                r = reg_by[rid]; inp_by[rid] = {"recording_id": rid, "object_name": r["object_name"], "base_name": r["base_name"], "variant_group_id": r["variant_group_id"], "word_id": res["word_id"], "item_key": res["item_key"],
                                              "firestore_word_doc_id": res["item_key"].split(":", 1)[1] if res["item_key"].startswith("words:") else "", "mansaka_text": res["text"], "translation_en": res["tr"], "item_type": res["item_type"],
                                              "source_collection": res["coll"], "source_doc_id": res["doc"], "evidence_category": "HUMAN_CONFIRMED", "review_case_id": cid, "confirmed_by": c["confirmed_by"], "confirmation_date": c["confirmation_date"], "notes": c.get("notes", "")}; n_map += 1
            audit.append({"applied_on": today, "review_case_id": cid, "decision": d, "decision_target": c.get("decision_target", ""), "recording_ids": c["recording_ids"], "word_id": res["word_id"], "item_key": res["item_key"], "mansaka_text": res["text"], "translation_en": res["tr"], "confirmed_by": c["confirmed_by"], "confirmation_date": c["confirmation_date"], "notes": c.get("notes", "")})
        elif d == "EXCLUDE":
            for rid in rids: inp_by[rid] = {**{k: "" for k in ih}, "recording_id": rid, "object_name": reg_by[rid]["object_name"], "base_name": reg_by[rid]["base_name"], "variant_group_id": reg_by[rid]["variant_group_id"], "evidence_category": "EXCLUDED_BY_REVIEW", "review_case_id": cid, "confirmed_by": c["confirmed_by"], "confirmation_date": c["confirmation_date"], "notes": c["notes"]}
            audit.append({"applied_on": today, "review_case_id": cid, "decision": d, "decision_target": "", "recording_ids": c["recording_ids"], "word_id": "", "item_key": "", "mansaka_text": "", "translation_en": "", "confirmed_by": c["confirmed_by"], "confirmation_date": c["confirmation_date"], "notes": c["notes"]})
        elif d == "SPLIT":
            for i, rid in enumerate(rids, 1):
                row = dict(c); row.update({"review_case_id": f"{cid}-{i}", "recording_ids": rid, "original_filenames": reg_by[rid]["object_name"], "n_recordings": 1, "evidence_category": "SPLIT_FROM_" + c["evidence_category"], "decision": "", "decision_target": "", "takes_same_item": "", "confirmed_by": "", "confirmation_date": "", "notes": f"split from {cid}; " + c.get("notes", "")}); new_rows_for_queue.append(row)
            audit.append({"applied_on": today, "review_case_id": cid, "decision": d, "decision_target": "", "recording_ids": c["recording_ids"], "word_id": "", "item_key": "", "mansaka_text": "", "translation_en": "", "confirmed_by": c["confirmed_by"], "confirmation_date": c["confirmation_date"], "notes": c.get("notes", "")})
    if a.dry_run: print(f"DRY RUN OK: {len(decided)} decisions valid; {n_map} recordings would be mapped; new items {new_items}"); return 0
    write_csv(root / "metadata" / "reference_mapping_input.csv", ih, list(inp_by.values()))
    ah, old_audit = read_csv(root / "metadata" / "mapping_audit_log.csv"); write_csv(root / "metadata" / "mapping_audit_log.csv", AUDIT_HEADER, old_audit + audit)
    # queue: drop applied cases, keep undecided + split rows
    remaining = [c for c in queue if not c.get("decision", "").strip() or c["decision"].strip().upper() == "DEFER"] + new_rows_for_queue
    for c in remaining:
        if c.get("decision", "").strip().upper() == "DEFER": c["decision"] = ""
    write_csv(qpath, qh, remaining)
    print(f"applied {len(decided)} decisions: {n_map} recordings mapped, new items {new_items}, {len(new_rows_for_queue)} split rows added, {len(remaining)} cases remain")
    if not a.no_rebuild:
        here = Path(__file__).parent
        for cmd in (["build_reference_registry.py"], ["build_manifest.py"], ["checksums.py", "generate"], ["check_dataset.py"]):
            r = subprocess.run([sys.executable, str(here / cmd[0]), *cmd[1:], "--root", str(root)] if cmd[0] != "checksums.py" else [sys.executable, str(here / cmd[0]), cmd[1], "--root", str(root)], capture_output=True, text=True)
            print(f"  {cmd[0]}: exit {r.returncode}; {r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr.strip()[-200:]}")
    return 0

if __name__ == "__main__": sys.exit(main())
