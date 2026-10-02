#!/usr/bin/env python3
"""Generate the authoritative learner target list from the canonical metadata (never from filenames).

Input : metadata/vocabulary.csv (112 items), metadata/reference_recordings.csv (128 validated references),
        metadata/mapping_audit_log.csv + validation/review_submissions/*_normalized.csv (how a human-confirmed gloss arose),
        metadata/translation_review_flags.csv (open linguistic flags; optional).
Output: metadata/learner_targets.csv (one row per item) and reports/learner_targets_<ver>.json (counts + sha256).

Translation handling: nothing is corrected or invented. Every item gets translation_status in {available, flagged, missing},
translation_review_required, translation_source and translation_notes. Pronunciation identity = word_id + mansaka_text +
validated reference audio; a missing or flagged gloss never changes it or the item's collection eligibility.
Primary playback reference policy (config/corpus.yaml): lowest REF_nnn of the item; recorded per item; all references kept.
"""
import argparse, datetime as dt, json
from pathlib import Path
from common import ROOT, read_csv, write_csv, version, corpus, sha256_file, truthy

HEADER = ["word_id","mansaka_text","item_type","alternate_forms","form_texts","translation_en","translation_status","translation_review_required","translation_source","translation_notes",
          "reference_recording_ids","reference_count","reference_raw_paths","reference_sha256s","primary_playback_reference_id","playback_reference_policy",
          "source_collection","source_doc_id","evidence_category","mapping_evidence","mapping_confirmed_by","mapping_confirmation_date","gloss_conflict",
          "collection_eligible","eligibility_notes","flags","target_list_version","dataset_version"]
SOURCE_BY_CATEGORY = {"DICTIONARY_HEADWORD_EXACT": "svelmoe1990_headword", "DICTIONARY_HEADWORD_ALTFORM": "svelmoe1990_headword", "DICTIONARY_EXAMPLE_EXACT": "svelmoe1990_example",
                      "DICTIONARY_FINDER_EXACT": "svelmoe1990_finder", "EXACT_TERM_UNIQUE": "firestore_words", "EXACT_EXAMPLE_SENTENCE_UNIQUE": "firestore_words_example",
                      "EXACT_LESSON_ITEM_UNIQUE": "lesson"}

def review_case_categories(root):
    """word_id -> evidence category of the review case that produced the item (from the applied submission)."""
    out = {}
    _, audit = read_csv(root / "metadata" / "mapping_audit_log.csv")
    cases = {}
    for f in sorted((root / "validation" / "review_submissions").glob("*_normalized.csv")) if (root / "validation" / "review_submissions").exists() else []:
        _, rows = read_csv(f); cases.update({r["review_case_id"]: r for r in rows})
    for a in audit:
        c = cases.get(a["review_case_id"])
        if c and a.get("word_id"): out[a["word_id"]] = {"category": c.get("evidence_category", ""), "candidate_translation": c.get("candidate_translation_en", ""), "authoritative_translation": c.get("authoritative_translation_en", ""), "decision": a.get("decision", "")}
    return out

def translation_fields(v, case, flags):
    tr = v.get("translation_en", "").strip(); cat = v.get("evidence_category", ""); notes = []; src = "none"; status = "available"; review = False
    if not tr: status, review = "missing", True; notes.append("no English gloss in any source (dictionary, Firestore, lessons, reviewer); pronunciation identity unaffected")
    elif cat in SOURCE_BY_CATEGORY: src = SOURCE_BY_CATEGORY[cat]; notes.append("verbatim source gloss (dictionary definitions keep their OCR text and POS prefix)")
    elif cat == "HUMAN_CONFIRMED":
        c = case or {}; cc = c.get("category", "")
        if cc == "DICTIONARY_ROOT_CANDIDATE": src = "svelmoe1990_root_gloss_via_review"; status, review = "flagged", True; notes.append("inflected form; gloss is the dictionary definition of the affix-stripped ROOT, accepted by the reviewer; needs linguistic confirmation")
        elif v.get("source_collection") == "svelmoe1990":
            src = "svelmoe1990_headword" if "hw:" in v.get("item_key", "") else "svelmoe1990_finder"
            if v.get("dictionary_definition", "").strip() and tr != v["dictionary_definition"].strip(): status, review = "flagged", True; src += "+reviewer"; notes.append(f"reviewer gloss differs from dictionary gloss '{v['dictionary_definition'].strip()[:80]}'")
            else: notes.append("dictionary gloss confirmed by reviewer (orthographic variant u->o)")
        elif v.get("source_collection") == "lessons": src = "lesson"; notes.append("published lesson gloss confirmed by reviewer")
        elif c.get("category") == "VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE": src = "voice_submission_transcript_via_review"; status, review = "flagged", True; notes.append("gloss comes from a community voice-submission transcript (not curated vocabulary), confirmed by reviewer")
        else: src = "reviewer"; status, review = "flagged", True; notes.append("gloss entered by the reviewer without a dictionary or project source")
    if v.get("gloss_conflict", "").strip(): status, review = "flagged", True; notes.append("lesson vs dictionary gloss conflict: " + v["gloss_conflict"].strip()[:160])
    for fl in flags.get(v["word_id"], []):
        if fl.get("resolution_status", "open") == "open": status, review = ("flagged" if tr else "missing"), True; notes.append(f"open flag {fl['flag_code']}: {fl['detail'][:160]}")
    return tr, status, review, src, " | ".join(notes)

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter); ap.add_argument("--root", default=str(ROOT)); a = ap.parse_args(); root = Path(a.root)
    ver = version(root); c = corpus(root); lc = c.get("learner_collection", {}); policy = lc.get("primary_playback_reference_policy", "lowest_reference_id")
    _, voc = read_csv(root / "metadata" / "vocabulary.csv"); _, reg = read_csv(root / "metadata" / "reference_recordings.csv"); regby = {r["recording_id"]: r for r in reg}
    _, fl = read_csv(root / "metadata" / "translation_review_flags.csv"); flags = {}
    for f in fl: flags.setdefault(f["word_id"], []).append(f)
    cases = review_case_categories(root); rows = []; tlv = f"TL-{ver.split('_v')[-1] if '_v' in ver else ver}"
    for v in sorted(voc, key=lambda x: x["word_id"]):
        refs = [x for x in v.get("reference_recording_ids", "").split(";") if x]; missing_ref = [r for r in refs if r not in regby]
        rr = [regby[r] for r in refs if r in regby]; unreadable = [r["recording_id"] for r in rr if not truthy(r.get("readable"))]
        nofile = [r["recording_id"] for r in rr if not r.get("raw_audio_path") or not (root / r["raw_audio_path"]).exists()]
        notval = [r["recording_id"] for r in rr if r.get("validation_status") != "validated"]
        elig_notes = []
        if not refs: elig_notes.append("no validated reference recording")
        if missing_ref: elig_notes.append(f"reference ids not in registry: {missing_ref}")
        if unreadable: elig_notes.append(f"unreadable references: {unreadable}")
        if nofile: elig_notes.append(f"raw file missing: {nofile}")
        if notval: elig_notes.append(f"not validated: {notval}")
        if not v.get("mansaka_text", "").strip(): elig_notes.append("no Mansaka text")
        eligible = not elig_notes
        primary = min(refs) if refs and policy == "lowest_reference_id" else (refs[0] if refs else "")
        tr, status, review, src, tnotes = translation_fields(v, cases.get(v["word_id"]), flags)
        fset = []
        if status != "available": fset.append(f"TRANSLATION_{status.upper()}")
        if len(refs) > 1: fset.append("MULTI_REFERENCE")
        if v.get("evidence_category") == "HUMAN_CONFIRMED": fset.append("TEXT_HUMAN_CONFIRMED")
        rows.append({"word_id": v["word_id"], "mansaka_text": v["mansaka_text"], "item_type": v.get("item_type", ""), "alternate_forms": v.get("alternate_forms", ""),
                     "form_texts": ";".join(sorted({r.get("form_text", "") for r in rr if r.get("form_text")})), "translation_en": tr, "translation_status": status,
                     "translation_review_required": str(review).lower(), "translation_source": src, "translation_notes": tnotes,
                     "reference_recording_ids": ";".join(refs), "reference_count": len(refs), "reference_raw_paths": ";".join(r.get("raw_audio_path", "") for r in rr),
                     "reference_sha256s": ";".join(r.get("sha256", "") for r in rr), "primary_playback_reference_id": primary, "playback_reference_policy": policy,
                     "source_collection": v.get("source_collection", ""), "source_doc_id": v.get("source_doc_id", ""), "evidence_category": v.get("evidence_category", ""),
                     "mapping_evidence": v.get("mapping_evidence", ""), "mapping_confirmed_by": v.get("mapping_confirmed_by", ""), "mapping_confirmation_date": v.get("mapping_confirmation_date", ""),
                     "gloss_conflict": v.get("gloss_conflict", ""), "collection_eligible": str(eligible).lower(), "eligibility_notes": "; ".join(elig_notes), "flags": ";".join(fset),
                     "target_list_version": tlv, "dataset_version": ver})
    out = root / "metadata" / "learner_targets.csv"; write_csv(out, HEADER, rows)
    from collections import Counter
    summ = {"generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "dataset_version": ver, "target_list_version": tlv, "file": "metadata/learner_targets.csv", "sha256": sha256_file(out),
            "n_items": len(rows), "n_vocabulary_items": len(voc), "n_collection_eligible": sum(1 for r in rows if r["collection_eligible"] == "true"),
            "n_references_represented": len({x for r in rows for x in r["reference_recording_ids"].split(";") if x}), "n_registry_references": len(reg),
            "n_multi_reference_items": sum(1 for r in rows if int(r["reference_count"]) > 1), "playback_reference_policy": policy,
            "translation_status_counts": dict(Counter(r["translation_status"] for r in rows)), "translation_review_required": sum(1 for r in rows if r["translation_review_required"] == "true"),
            "translation_source_counts": dict(Counter(r["translation_source"] for r in rows)), "open_flags": sum(1 for f in fl if f.get("resolution_status", "open") == "open"),
            "rule": "generated from metadata/vocabulary.csv + metadata/reference_recordings.csv; no filename-derived identity; no gloss invented or corrected"}
    (root / "reports").mkdir(exist_ok=True); (root / "reports" / f"learner_targets_{'v' + ver.split('_v')[-1] if '_v' in ver else ver}.json").write_text(json.dumps(summ, indent=1))
    print(f"learner targets: {summ['n_items']} items ({summ['n_collection_eligible']} eligible), {summ['n_references_represented']}/{summ['n_registry_references']} references, "
          f"{summ['n_multi_reference_items']} multi-reference; translations {summ['translation_status_counts']}; sha256 {summ['sha256'][:16]}")

if __name__ == "__main__": main()
