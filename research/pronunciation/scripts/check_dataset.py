#!/usr/bin/env python3
"""Dataset integrity checks -> reports/checks_report_<version>.md (and stdout).

Model: N validated physical reference recordings (N from config/corpus.yaml) registered in
metadata/reference_recordings.csv with stable ids REF_nnn; vocabulary items (Wnnn) in metadata/vocabulary.csv may own
several reference recordings; every recording carries validation_status (all must be `validated`) and a separate
mapping_status (`mapped` | `unresolved`). Learner recordings and ratings are checked when present.

Statuses: PASS | ERROR | WARN | EXPECTED-NOT-YET-COLLECTED | INFO
  --mode prefreeze (default): legitimately absent data (learners, ratings, unresolved mappings) -> EXPECTED-NOT-YET-COLLECTED
  --mode freeze: everything required for a frozen dataset must be present; absences -> ERROR
  --verify-hashes: re-hash raw files against the registry/manifest and verify SHA256SUMS lists
Exit code 1 if any ERROR.
"""
import argparse, datetime as dt, sys
from collections import Counter, defaultdict
from pathlib import Path
from common import (ROOT, RE_WORD, RE_SPK, RE_REF, RE_LEARNER, REASON_CODES, STAGES, MAPPING_STATUS, MAPPING_EVIDENCE,
                    read_csv, version, corpus, sha256_file, rel, truthy)
from mapping_common import AUTHORITATIVE, CATEGORIES, DECISIONS
from learner_common import active_takes, validate_ratings, ratings_path, freeze_path, vtag
import json

class Report:
    def __init__(self): self.lines = []; self.counts = Counter()
    def add(self, s, c, d=""): self.counts[s] += 1; self.lines.append((s, c, d))
    def pass_(self, c, d=""): self.add("PASS", c, d)
    def error(self, c, d=""): self.add("ERROR", c, d)
    def warn(self, c, d=""): self.add("WARN", c, d)
    def pending(self, c, d=""): self.add("EXPECTED-NOT-YET-COLLECTED", c, d)
    def info(self, c, d=""): self.add("INFO", c, d)

def run(root, mode, verify_hashes):
    rep = Report(); ver = version(root); c = corpus(root); N = int(c.get("expected_reference_recordings", 0))
    absent = rep.error if mode == "freeze" else rep.pending
    rep.info("dataset_version", ver or "(VERSION missing)"); rep.info("corpus contract", f"expected_reference_recordings={N}, multiple_references_per_item={c.get('multiple_references_per_item')}")
    if not ver: rep.error("VERSION", "missing"); 
    if not N: rep.error("config/corpus.yaml", "expected_reference_recordings missing")
    gh, reg = read_csv(root / "metadata" / "reference_recordings.csv")
    vh, voc = read_csv(root / "metadata" / "vocabulary.csv")
    _, srcs = read_csv(root / "metadata" / "source_objects.csv")
    ph, parts = read_csv(root / "metadata" / "participants.csv")
    _, vals = read_csv(root / "metadata" / "validators.csv")
    _, aq = read_csv(root / "metadata" / "audio_quality.csv")
    mh, man = read_csv(root / "manifests" / "manifest.csv")
    _, exc = read_csv(root / "manifests" / "exclusions.csv")
    _, rat = read_csv(root / "validation" / "ratings.csv")
    _, minp = read_csv(root / "metadata" / "reference_mapping_input.csv")
    for name, hdr, need in [("reference_recordings.csv", gh, ["recording_id","object_name","source_storage_path","sha256","raw_audio_path","validation_status","mapping_status","word_id","variant_group_id"]),
                            ("vocabulary.csv", vh, ["word_id","mansaka_text","reference_recording_ids","reference_count","mapping_evidence"]),
                            ("manifest.csv", mh, ["recording_id","recording_type","speaker_id","word_id","mapping_status","original_audio_path","original_sha256","validation_status","included_in_experiment","exclusion_id","dataset_version"]),
                            ("participants.csv", ph, ["speaker_id","role"])]:
        miss = [x for x in need if x not in hdr]; (rep.error if miss else rep.pass_)(f"schema:{name}", f"missing columns {miss}" if miss else "required columns present")

    # ---------------- reference registry ----------------
    ids = Counter(r["recording_id"] for r in reg); dup = sorted(k for k, n in ids.items() if n > 1); bad = sorted(k for k in ids if not RE_REF.match(k))
    (rep.error if dup or bad else rep.pass_)("registry:recording_id unique & well-formed", f"dup={dup} bad={bad}" if dup or bad else f"{len(reg)} ids REF_nnn")
    (rep.pass_ if len(reg) == N else rep.error)("registry:validated reference count", f"{len(reg)} registered, expected {N}")
    dupn = [k for k, n in Counter(r["object_name"] for r in reg).items() if n > 1]; dups = [k[:12] for k, n in Counter(r["sha256"] for r in reg).items() if n > 1]
    (rep.error if dupn else rep.pass_)("registry:object_name unique", str(dupn) if dupn else "ok"); (rep.warn if dups else rep.pass_)("registry:sha256 unique", f"byte-identical groups {dups}" if dups else "no byte-identical recordings")
    nv = [r["recording_id"] for r in reg if r.get("validation_status") != "validated"]
    (rep.error if nv else rep.pass_)("registry:validation_status", f"{len(nv)} not 'validated': {nv[:8]}" if nv else f"all {len(reg)} recordings validated (provenance: {c.get('reference_validation',{}).get('provenance','').strip()[:60]}…)")
    bms = [r["recording_id"] for r in reg if r.get("mapping_status") not in MAPPING_STATUS]; (rep.error if bms else rep.pass_)("registry:mapping_status values", str(bms[:8]) if bms else "all in {mapped, unresolved}")
    bme = [r["recording_id"] for r in reg if r.get("mapping_status") == "mapped" and r.get("mapping_evidence") not in MAPPING_EVIDENCE]
    (rep.error if bme else rep.pass_)("registry:mapping_evidence for mapped rows", str(bme[:8]) if bme else "ok")
    unres = [r for r in reg if r.get("mapping_status") == "unresolved"]; mapped = [r for r in reg if r.get("mapping_status") == "mapped"]
    if unres: absent("registry:vocabulary mapping", f"{len(unres)}/{len(reg)} recordings unresolved (validated audio, item identity pending); {len(mapped)} mapped")
    else: rep.pass_("registry:vocabulary mapping", f"all {len(reg)} recordings mapped")
    # mapping input file covers unresolved
    cov = {m["recording_id"] for m in minp}; missing_inp = [r["recording_id"] for r in unres if r["recording_id"] not in cov]
    if unres: (rep.error if missing_inp else rep.pass_)("registry:mapping input rows for unresolved", str(missing_inp[:8]) if missing_inp else f"{len(cov)} rows in reference_mapping_input.csv")
    # raw files
    noraw = [r["recording_id"] for r in reg if not r.get("raw_audio_path")]; missraw = [r["recording_id"] for r in reg if r.get("raw_audio_path") and not (root / r["raw_audio_path"]).exists()]
    if missraw: rep.error("registry:raw file exists", f"path set but missing: {missraw[:8]}")
    if noraw: absent("registry:canonical raw copy", f"{len(noraw)} recordings not yet promoted to raw/reference/")
    if not noraw and not missraw: rep.pass_("registry:canonical raw copy", f"all {len(reg)} present in raw/reference/")
    badname = [r["recording_id"] for r in reg if r.get("raw_audio_path") and Path(r["raw_audio_path"]).stem != r["recording_id"]]
    (rep.error if badname else rep.pass_)("registry:raw filename == recording_id", str(badname[:8]) if badname else "ok")
    unread = [r["recording_id"] for r in reg if not truthy(r.get("readable"))]; (rep.error if unread else rep.pass_)("registry:readable", str(unread[:8]) if unread else "all readable")
    # provenance vs source_objects
    sby = {s["object_name"]: s for s in srcs}; nosrc = [r["recording_id"] for r in reg if r["object_name"] not in sby]
    shamis = [r["recording_id"] for r in reg if r["object_name"] in sby and sby[r["object_name"]].get("staged_sha256") and sby[r["object_name"]]["staged_sha256"] != r["sha256"]]
    (rep.error if nosrc or shamis else rep.pass_)("registry↔source_objects provenance", f"no source row {nosrc[:5]} sha mismatch {shamis[:5]}" if nosrc or shamis else f"{len(srcs)} source objects, hashes agree")
    (rep.pass_ if len(srcs) == N else rep.error)("source_objects:count", f"{len(srcs)} (expected {N})")
    if verify_hashes:
        badh = [r["recording_id"] for r in reg if r.get("raw_audio_path") and (root / r["raw_audio_path"]).exists() and sha256_file(root / r["raw_audio_path"]) != r["sha256"]]
        (rep.error if badh else rep.pass_)("registry:raw bytes match sha256", str(badh[:8]) if badh else f"{sum(1 for r in reg if r.get('raw_audio_path'))} files re-hashed OK")
    raw_files = {rel(p, root) for p in (root / "raw" / "reference").glob("*") if p.is_file() and p.name not in {".gitkeep", "README.md"}}
    orph = sorted(raw_files - {r["raw_audio_path"] for r in reg}); (rep.error if orph else rep.pass_)("raw/reference:orphan files", str(orph[:8]) if orph else "none")

    # ---------------- mapping evidence / review queue / id ledger ----------------
    _, ev = read_csv(root / "metadata" / "mapping_evidence.csv"); _, rq = read_csv(root / "metadata" / "mapping_review_queue.csv"); _, hist = read_csv(root / "metadata" / "vocabulary_id_history.csv")
    if ev:
        (rep.pass_ if len(ev) == len(reg) else rep.error)("evidence:coverage", f"{len(ev)} evidence rows for {len(reg)} recordings")
        badcat = [e["recording_id"] for e in ev if e["evidence_category"] not in CATEGORIES]; (rep.error if badcat else rep.pass_)("evidence:categories valid", str(badcat[:8]) if badcat else "ok")
        promo = [e["recording_id"] for e in ev if e["authoritative"] == "true" and (e["evidence_category"] not in AUTHORITATIVE or e["take_suffix"])]
        (rep.error if promo else rep.pass_)("evidence:no candidate/take auto-promotion", str(promo[:8]) if promo else "authoritative rows are exact, unsuffixed matches only")
        badm = [r["recording_id"] for r in mapped if r.get("evidence_category") not in AUTHORITATIVE | {"HUMAN_CONFIRMED"}]
        (rep.error if badm else rep.pass_)("registry:mapped rows carry authoritative/human evidence", str(badm[:8]) if badm else f"{len(mapped)} mapped rows ok")
        rep.info("evidence:category counts", str(dict(Counter(e["evidence_category"] for e in ev))))
    else: rep.warn("evidence", "metadata/mapping_evidence.csv missing; run resolve_vocabulary_mapping.py")
    if rq:
        qr = {x for c in rq for x in c["recording_ids"].split(";") if x}; unres_ids = {r["recording_id"] for r in unres}
        (rep.pass_ if qr == unres_ids else rep.error)("review queue ↔ unresolved recordings", f"{len(rq)} cases cover {len(qr)} recordings; unresolved {len(unres_ids)}" + ("" if qr == unres_ids else f"; missing {sorted(unres_ids - qr)[:5]} extra {sorted(qr - unres_ids)[:5]}"))
        badd = [c["review_case_id"] for c in rq if c.get("decision", "").strip() and c["decision"].strip().upper() not in DECISIONS]; (rep.error if badd else rep.pass_)("review queue:decisions parse", str(badd[:8]) if badd else "no invalid decisions")
        pend = [c["review_case_id"] for c in rq if c.get("decision", "").strip()]; 
        if pend: rep.warn("review queue:decisions awaiting apply", f"{len(pend)} decided cases not yet applied (run apply_mapping_review.py)")
    elif unres: rep.warn("review queue", "unresolved recordings but no queue; run resolve_vocabulary_mapping.py")
    hid = Counter(h["word_id"] for h in hist); dh = [k for k, n in hid.items() if n > 1]; (rep.error if dh else rep.pass_)("id ledger:unique", str(dh) if dh else f"{len(hist)} ids recorded")
    unledgered = sorted(v["word_id"] for v in voc if v["word_id"] not in hid) if hist else []
    (rep.warn if unledgered else rep.pass_)("id ledger:vocabulary ids recorded", f"missing {unledgered[:8]}" if unledgered else "all vocabulary ids in vocabulary_id_history.csv")
    ledger_key = {h["word_id"]: h["item_key"] for h in hist}; drift = [v["word_id"] for v in voc if v["word_id"] in ledger_key and ledger_key[v["word_id"]] and ledger_key[v["word_id"]] != v.get("item_key")]
    (rep.error if drift else rep.pass_)("id ledger:ids never reassigned", str(drift[:8]) if drift else "item_key per id stable")

    # ---------------- vocabulary ----------------
    wids = Counter(v["word_id"] for v in voc); dupw = [k for k, n in wids.items() if n > 1]; badw = [k for k in wids if not RE_WORD.match(k)]
    (rep.error if dupw or badw else rep.pass_)("vocabulary:word_id unique & well-formed", f"dup={dupw} bad={badw}" if dupw or badw else f"{len(voc)} items")
    dupd = [k for k, n in Counter(v["firestore_word_doc_id"] for v in voc if v.get("firestore_word_doc_id")).items() if n > 1]
    (rep.error if dupd else rep.pass_)("vocabulary:firestore_word_doc_id unique", str(dupd) if dupd else "ok")
    notext = [v["word_id"] for v in voc if not v.get("mansaka_text", "").strip()]; (rep.error if notext else rep.pass_)("vocabulary:mansaka_text present", str(notext[:8]) if notext else "all items have text from source data")
    regw = defaultdict(list)
    for r in mapped: regw[r["word_id"]].append(r["recording_id"])
    unknown_w = sorted(set(regw) - set(wids)); (rep.error if unknown_w else rep.pass_)("registry→vocabulary word_id exists", str(unknown_w[:8]) if unknown_w else "ok")
    inconsistent = [v["word_id"] for v in voc if sorted(regw.get(v["word_id"], [])) != sorted(filter(None, v.get("reference_recording_ids", "").split(";"))) or str(len(regw.get(v["word_id"], []))) != str(v.get("reference_count"))]
    (rep.error if inconsistent else rep.pass_)("vocabulary↔registry reference lists", str(inconsistent[:8]) if inconsistent else "reference_recording_ids and counts agree")
    multi = {w: ids_ for w, ids_ in regw.items() if len(ids_) > 1}
    rep.info("vocabulary:items with multiple validated references", f"{len(multi)} items (allowed): " + ", ".join(f"{w}×{len(v)}" for w, v in sorted(multi.items())[:10]) if multi else "none yet")
    # filename groups vs items (informational; grouping is not identity)
    vg = defaultdict(set)
    for r in reg: vg[r["variant_group_id"]].add(r.get("word_id") or "?")
    rep.info("filename variant groups", f"{len(vg)} groups (not linguistic identity); groups containing >1 distinct mapped item: {sum(1 for s in vg.values() if len(s - {'?'}) > 1)}")

    # ---------------- participants / validators ----------------
    spk = Counter(p["speaker_id"] for p in parts); dsp = [k for k, n in spk.items() if n > 1]; bsp = [k for k in spk if not RE_SPK.match(k)]
    (rep.error if dsp or bsp else rep.pass_)("participants:ids", f"dup={dsp} bad={bsp}" if dsp or bsp else f"{len(parts)} rows")
    rspk = c.get("reference_speaker_id", "R001")
    (rep.pass_ if any(p["speaker_id"] == rspk and p["role"] == "reference" for p in parts) else rep.error)(f"participants:{rspk}", "reference speaker present")
    learners = sorted(p["speaker_id"] for p in parts if p["role"] == "learner")
    if not learners: absent("participants:learners", "none enrolled yet (design expects ≥10)")
    elif len(learners) < 10: (rep.error if mode == "freeze" else rep.warn)("participants:learners", f"{len(learners)} enrolled; design expects ≥10")
    else: rep.pass_("participants:learners", f"{len(learners)} enrolled")
    (rep.pass_ if any(v["validator_code"] == "V01" for v in vals) else rep.error)("validators:V01", "present" if vals else "missing")
    pii = [x for x in ph if x.lower() in {"name","full_name","email","phone","birthdate","age","gender","address"}]; (rep.error if pii else rep.pass_)("participants:no PII columns", str(pii) if pii else "ok")

    # ---------------- manifest ----------------
    rid = Counter(m["recording_id"] for m in man); dupm = sorted(k for k, n in rid.items() if n > 1)
    (rep.error if dupm else rep.pass_)("manifest:recording_id unique", str(dupm[:8]) if dupm else f"{len(man)} rows")
    refs = [m for m in man if m["recording_type"] == "reference"]; lrn = [m for m in man if m["recording_type"] == "learner"]
    promoted = [r for r in reg if r.get("raw_audio_path")]
    if len(refs) == len(promoted) == N: rep.pass_("manifest:reference rows", f"{N} = registry = corpus")
    elif len(refs) == len(promoted): absent("manifest:reference rows", f"{len(refs)} rows match {len(promoted)} promoted recordings; corpus expects {N}")
    else: rep.error("manifest:reference rows", f"{len(refs)} rows vs {len(promoted)} promoted registry recordings")
    regby = {r["recording_id"]: r for r in reg}
    badref = [m["recording_id"] for m in refs if m["recording_id"] not in regby or m["original_sha256"] != regby[m["recording_id"]]["sha256"] or m["speaker_id"] != rspk
              or m["reference_recording_id"] != m["recording_id"] or m["validation_status"] != "validated" or m.get("word_id", "") != regby[m["recording_id"]].get("word_id", "")
              or m.get("mapping_status") != regby[m["recording_id"]].get("mapping_status")]
    (rep.error if badref else (rep.pass_ if refs else rep.info))("manifest↔registry consistency", str(badref[:8]) if badref else ("ids, sha256, speaker, status and mapping agree" if refs else "no reference rows"))
    acc_excl = [m["recording_id"] for m in refs if not truthy(m.get("included_in_experiment")) and not m.get("exclusion_id")]
    (rep.error if acc_excl else rep.pass_)("manifest:no accidental reference exclusion", f"validated references not included without exclusion: {acc_excl[:8]}" if acc_excl else "every reference row included or explicitly excluded")
    badl = [m["recording_id"] for m in lrn if not (RE_LEARNER.match(m["recording_id"]) and RE_LEARNER.match(m["recording_id"]).group(1) == m["speaker_id"] and RE_LEARNER.match(m["recording_id"]).group(2) == m["word_id"])]
    if badl: rep.error("manifest:learner row consistency", str(badl[:8]))
    unk_l = sorted({m["speaker_id"] for m in lrn} - set(learners)); 
    if unk_l: rep.error("manifest:learner speaker enrolled", str(unk_l))
    unk_w = sorted({m["word_id"] for m in lrn} - set(wids))
    if unk_w: rep.error("manifest:learner word_id in vocabulary", str(unk_w[:8]))
    missf = [m["recording_id"] for m in man if not (root / m["original_audio_path"]).exists()]; (rep.error if missf else rep.pass_)("manifest:files exist", str(missf[:8]) if missf else f"{len(man)} paths resolve")
    rawall = {rel(p, root) for p in (root / "raw").rglob("*") if p.is_file() and p.name not in {".gitkeep", "README.md"}}
    orphan = sorted(rawall - {m["original_audio_path"] for m in man}); (rep.error if orphan else rep.pass_)("raw:orphan files (all tiers)", str(orphan[:8]) if orphan else "every raw file has a manifest row")
    aqp = {r["file_path"]: r for r in aq}; unpr = [m["recording_id"] for m in man if m["original_audio_path"] not in aqp]
    (rep.error if unpr else (rep.pass_ if man else rep.info))("audio_quality:coverage", str(unpr[:8]) if unpr else f"{len(aq)} probed")
    inc_unread = [m["recording_id"] for m in man if not truthy(m.get("readable")) and truthy(m.get("included_in_experiment"))]
    (rep.error if inc_unread else rep.pass_)("manifest:no unreadable included", str(inc_unread[:8]) if inc_unread else "ok")
    # exclusions
    eid = Counter(e["exclusion_id"] for e in exc); dupe = [k for k, n in eid.items() if n > 1]
    if dupe: rep.error("exclusions:duplicate exclusion_id", str(dupe))
    bc = [e["exclusion_id"] for e in exc if e["reason_code"] not in REASON_CODES]; bs = [e["exclusion_id"] for e in exc if e["stage"] not in STAGES]; oe = [e["exclusion_id"] for e in exc if e["recording_id"] not in rid]
    if bc: rep.error("exclusions:reason_code", str(bc)); 
    if bs: rep.error("exclusions:stage", str(bs)); 
    if oe: rep.error("exclusions:orphan rows", str(oe))
    prob = defaultdict(list)
    for m in man:
        inc = truthy(m.get("included_in_experiment")); ex = m.get("exclusion_id", "").strip()
        if inc and ex: prob["included_with_exclusion"].append(m["recording_id"])
        if ex and ex not in eid: prob["dangling_exclusion_id"].append(m["recording_id"])
        if m["recording_type"] == "learner" and not inc and not ex: prob["learner_pending_decision"].append(m["recording_id"])
    for k, v in prob.items():
        if k == "learner_pending_decision": absent("manifest:learner rows neither included nor excluded", f"{len(v)} pending")
        else: rep.error(f"manifest:{k}", str(v[:8]))
    if not exc: rep.info("exclusions", "none logged")
    elif not prob: rep.pass_("exclusions:consistency")

    # ---------------- learner targets (authoritative collection list) ----------------
    _, tg = read_csv(root / "metadata" / "learner_targets.csv"); tby = {t["word_id"]: t for t in tg}
    if not tg: absent("learner targets", "metadata/learner_targets.csv missing; run build_learner_targets.py")
    else:
        (rep.pass_ if set(tby) == set(wids) else rep.error)("learner targets:items = vocabulary", f"{len(tg)} targets vs {len(wids)} items" + ("" if set(tby) == set(wids) else f"; missing {sorted(set(wids) - set(tby))[:5]} extra {sorted(set(tby) - set(wids))[:5]}"))
        badt = [t["word_id"] for t in tg if sorted(filter(None, t["reference_recording_ids"].split(";"))) != sorted(regw.get(t["word_id"], [])) or t["primary_playback_reference_id"] not in t["reference_recording_ids"].split(";")
                or t["primary_playback_reference_id"] != min(filter(None, t["reference_recording_ids"].split(";")), default="")]
        (rep.error if badt else rep.pass_)("learner targets:references & primary playback (lowest id)", str(badt[:8]) if badt else "every item lists its registry references; primary = lowest REF id")
        badtx = [t["word_id"] for t in tg if t["mansaka_text"] != next((v["mansaka_text"] for v in voc if v["word_id"] == t["word_id"]), None)]
        (rep.error if badtx else rep.pass_)("learner targets:text = vocabulary", str(badtx[:8]) if badtx else "ok")
        inel = [t["word_id"] for t in tg if not truthy(t.get("collection_eligible"))]; (rep.warn if inel else rep.pass_)("learner targets:collection eligible", f"not eligible: {inel[:8]}" if inel else f"all {len(tg)} items eligible")
        badts = [t["word_id"] for t in tg if t.get("translation_status") not in {"available", "flagged", "missing"} or (t["translation_status"] != "available") != truthy(t.get("translation_review_required"))]
        (rep.error if badts else rep.pass_)("learner targets:translation flags consistent", str(badts[:8]) if badts else f"{sum(1 for t in tg if t['translation_status']=='missing')} missing, {sum(1 for t in tg if t['translation_status']=='flagged')} flagged, {sum(1 for t in tg if t['translation_status']=='available')} available (none auto-corrected)")
        badlr = [m["recording_id"] for m in lrn if m["word_id"] in tby and m.get("reference_recording_id") != tby[m["word_id"]]["primary_playback_reference_id"]]
        if lrn: (rep.error if badlr else rep.pass_)("manifest:learner reference = primary playback reference", str(badlr[:8]) if badlr else "ok")
    if lrn:
        act, probs = active_takes(man, exc); (rep.error if probs else rep.pass_)("learner takes:consistency", "; ".join(probs[:5]) if probs else f"{len(act)} active takes; retakes only after excluded takes")
        unenr = sorted({m["speaker_id"] for m in lrn if m["speaker_id"] not in set(learners)})
        if unenr: rep.error("learner recordings:speaker enrolled", str(unenr))
        _, ilog = read_csv(root / "metadata" / "learner_import_log.csv"); logged = {l["recording_id"] for l in ilog if l.get("status") == "imported"}
        unl = [m["recording_id"] for m in lrn if m["recording_id"] not in logged]; (rep.warn if unl else rep.pass_)("learner recordings:import provenance", f"{len(unl)} files not in learner_import_log.csv: {unl[:5]}" if unl else f"all {len(lrn)} logged")
    # ---------------- learner grid ----------------
    items = sorted(wids)
    if learners and items:
        for s in learners:
            have = {m["word_id"] for m in lrn if m["speaker_id"] == s}; miss = [w for w in items if w not in have]
            multi_t = [w for w, n in Counter(m["word_id"] for m in lrn if m["speaker_id"] == s and truthy(m.get("included_in_experiment"))).items() if n > 1]
            if multi_t: rep.error(f"learner grid:{s}", f"more than one included take for {multi_t}")
            if miss: absent(f"learner grid:{s}", f"{len(miss)}/{len(items)} items not recorded")
            else: rep.pass_(f"learner grid:{s}", f"{len(items)}/{len(items)} recorded")
        rep.info("learner recordings", f"{len(lrn)} files; item list currently {len(items)} mapped items (mapping completeness: {len(mapped)}/{len(reg)} recordings)")
    else: absent("learner recordings", f"none yet; {len(items)} target items await collection" if len(mapped) == len(reg) else f"none yet; item list not final until mapping is complete ({len(mapped)}/{len(reg)} mapped)")

    # ---------------- ratings (pass 1 = validation/ratings.csv, pass 2 = validation/ratings_pass2.csv) ----------------
    _, rat2 = read_csv(ratings_path(root, 2))
    for rp, rows_ in ((1, rat), (2, rat2)):
        if rows_:
            errs = validate_ratings(root, rp, rows=rows_, manifest=man, targets=tg, validators=vals)
            (rep.error if errs else rep.pass_)(f"ratings pass {rp}:rules", "; ".join(errs[:5]) + (f" (+{len(errs)-5})" if len(errs) > 5 else "") if errs else f"{len(rows_)} rows valid (integer 1-5 or unratable+reason, blind, unique, ids and primary reference match)")
        fp = freeze_path(root, rp)
        if fp.exists():
            fz = json.loads(fp.read_text()); ok = fz.get("ratings_sha256") == (sha256_file(ratings_path(root, rp)) if ratings_path(root, rp).exists() else None)
            (rep.pass_ if ok else rep.error)(f"ratings pass {rp}:frozen", f"{fp.name} sha256 {fz.get('ratings_sha256','')[:16]} matches" if ok else f"{fp.name} does not match the ratings file (modified after freeze)")
            if rp == 1:
                drift = [k for k, pth in [("targets_sha256", "metadata/learner_targets.csv"), ("manifest_sha256", "manifests/manifest.csv"), ("exclusions_sha256", "manifests/exclusions.csv")] if (root / pth).exists() and sha256_file(root / pth) != fz.get(k)]
                (rep.error if drift else rep.pass_)("ratings pass 1:frozen companions", f"changed since freeze: {drift}" if drift else "targets, manifest and exclusions unchanged since the freeze")
        elif rp == 1 and lrn: absent("ratings pass 1:frozen", "no freeze record yet (rating_tool.py freeze --pass 1)")
    inc_l = [m["recording_id"] for m in lrn if truthy(m.get("included_in_experiment"))]
    act_ids = {v["recording_id"] for v in active_takes(man, exc)[0].values()} if lrn else set()
    decided1 = {r["recording_id"] for r in rat if str(r.get("rating_pass", "1")) == "1" and r.get("validation_status") in ("rated", "unratable")}
    und = sorted(act_ids - decided1)
    if act_ids and not und: rep.pass_("ratings:coverage", f"all {len(act_ids)} active learner recordings have a pass-1 decision ({len(inc_l)} included)")
    elif act_ids: absent("ratings:coverage", f"{len(und)}/{len(act_ids)} active learner recordings lack a pass-1 decision")
    else: absent("ratings:coverage", "no learner recordings yet")
    if mode == "freeze":
        pst = next((l.split(":", 1)[1].strip() for l in (root / "config" / "preprocessing" / "PP001.yaml").read_text().splitlines() if l.startswith("status:")), "") if (root / "config" / "preprocessing" / "PP001.yaml").exists() else "missing"
        (rep.pass_ if pst == "frozen" else rep.warn)("PP001 status", pst if pst == "frozen" else f"'{pst}': provisional values must be fixed before the experiment runs (loader refuses otherwise)")
        (rep.pass_ if (root / "manifests" / f"repro_manifest_{vtag(ver)}.json").exists() else rep.error)("repro manifest", "PP/FE versions recorded" if (root / "manifests" / f"repro_manifest_{vtag(ver)}.json").exists() else "run build_repro_manifest.py")

    # ---------------- versions & checksums ----------------
    badv = {n: sorted({r.get("dataset_version") for r in rows if r.get("dataset_version") and r["dataset_version"] != ver}) for n, rows in [("registry", reg), ("vocabulary", voc), ("manifest", man), ("ratings", rat), ("exclusions", exc), ("participants", parts), ("validators", vals)]}
    badv = {k: v for k, v in badv.items() if v}; (rep.warn if badv else rep.pass_)("dataset_version consistency", f"rows on other versions: {badv}" if badv else f"all rows agree with VERSION ({ver})")
    lists = sorted((root / "checksums").glob("SHA256SUMS_*.txt")) if (root / "checksums").exists() else []
    vtag = "v" + ver.split("_v")[-1] if "_v" in ver else ver; cur = [l for l in lists if l.name.endswith(f"_{vtag}.txt")]
    if not cur: absent("checksums:lists for current version", "run scripts/checksums.py generate")
    else:
        rep.pass_("checksums:lists for current version", ", ".join(l.name for l in cur))
        if verify_hashes:
            badc = 0; n = 0
            for l in cur:
                for line in l.read_text().splitlines():
                    if not line.strip(): continue
                    d, pth = line.split("  ", 1); n += 1
                    if not (root / pth).exists() or sha256_file(root / pth) != d: badc += 1
            (rep.error if badc else rep.pass_)("checksums:verify lists", f"{badc} mismatches/missing of {n}" if badc else f"{n} entries verified")
        else: rep.info("checksums:verify", "skipped (use --verify-hashes)")
    return rep

def render(rep, root, mode, ver):
    out = [f"# Dataset integrity check — {ver}", "", f"Generated: {dt.date.today().isoformat()}  Mode: `{mode}`  Root: `{root}`", "", "| Status | Count |", "|---|---|"]
    out += [f"| {s} | {n} |" for s, n in sorted(rep.counts.items())] + ["", "| Status | Check | Detail |", "|---|---|---|"]
    out += [f"| {s} | {c} | {d.replace('|', '/')} |" for s, c, d in rep.lines]
    out += ["", "EXPECTED-NOT-YET-COLLECTED = legitimately absent in the pre-freeze state; becomes ERROR in `--mode freeze`.",
            f"Frozen-ready: {'YES' if rep.counts['ERROR'] == 0 and rep.counts['EXPECTED-NOT-YET-COLLECTED'] == 0 else 'NO'}"]
    return "\n".join(out) + "\n"

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--mode", choices=["prefreeze", "freeze"], default="prefreeze"); p.add_argument("--verify-hashes", action="store_true")
    p.add_argument("--root", default=str(ROOT)); p.add_argument("--no-report", action="store_true")
    a = p.parse_args(); root = Path(a.root); ver = version(root); rep = run(root, a.mode, a.verify_hashes); text = render(rep, root, a.mode, ver); print(text)
    if not a.no_report:
        (root / "reports").mkdir(exist_ok=True); (root / "reports" / f"checks_report_{'v' + ver.split('_v')[-1] if '_v' in ver else ver}.md").write_text(text)
    sys.exit(1 if rep.counts["ERROR"] else 0)
