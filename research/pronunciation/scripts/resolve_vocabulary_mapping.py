#!/usr/bin/env python3
"""Evidence-based vocabulary mapping resolution for the 128 validated reference recordings.

Sources searched (all read-only): staging/dictionary/ (Svelmoe & Svelmoe 1990 Mansaka Dictionary, two OCR transcriptions;
see dictionary_evidence.py), staging/firestore_export/words.json (term, usage-example sentences, definitions),
lessons.json (published lesson vocabulary/matching/MCQ/reordering items), voice_submissions.json (validated transcripts),
and the Flutter repository sources/assets (--flutter-root; mock/quiz data = non-authoritative supporting evidence only).

Outputs:
  metadata/mapping_evidence.csv        one row per recording: every candidate found, category, authoritative flag
  metadata/mapping_review_queue.csv    one row per UNRESOLVED linguistic case (filename group), prefilled with evidence
  reports/mapping_evidence_summary_<ver>.json
Authoritative categories (auto-mapped by build_reference_registry.py): DICTIONARY_HEADWORD_EXACT / _ALTFORM / DICTIONARY_EXAMPLE_EXACT /
DICTIONARY_FINDER_EXACT (filename stem equals a dictionary headword, a listed alternate form, an example sentence or a finder form), EXACT_TERM_UNIQUE (filename stem == one dictionary
term; the app's bulk audio importer uses the same stem==term convention), EXACT_EXAMPLE_SENTENCE_UNIQUE (stem == one
dictionary usage-example sentence, text+translation verbatim), EXACT_LESSON_ITEM_UNIQUE (stem == one published-lesson
item with its meaning). Recordings whose filename carries an explicit take suffix "(n)" are NEVER auto-mapped: their
group becomes a MULTIPLE_TAKE_CANDIDATE review case even when the base text has authoritative evidence.
Everything else is a candidate for human review. No spelling is inferred, no edit distance is used as evidence.
"""
import argparse, csv, datetime as dt, difflib, json, re, sys
from collections import defaultdict, Counter
from pathlib import Path
from common import ROOT, read_csv, write_csv, version
from mapping_common import norm, sent_norm, punct_norm, strip_take_suffix, AUTHORITATIVE
from dictionary_evidence import Dictionary

EV_HEADER = ["recording_id","object_name","filename_stem","base_text","take_suffix","variant_group_id","group_size","evidence_category","authoritative",
             "item_key","item_type","candidate_mansaka_text","candidate_translation_en","candidate_phonetic","candidate_pos","source_collection","source_doc_id","source_field",
             "dict_headword","dict_all_forms","dict_entry_ids","dict_pos","dict_definition","dict_book_page","dict_homonym_count","dict_rule","dict_candidates","gloss_conflict","corroboration",
             "existing_word_id","other_candidates","partial_token_matches","near_variant_groups","repo_hits","notes"]
RQ_HEADER = ["review_case_id","recording_ids","original_filenames","n_recordings","filename_group","display_text_from_filename","evidence_category","rule_tag","candidate_word_id",
             "candidate_item_key","candidate_mansaka_text","candidate_translation_en","candidate_phonetic","candidate_pos","candidate_source","dictionary_candidates","partial_token_matches",
             "gloss_conflict","related_case_ids","reason_for_review","suggested_actions","decision","decision_target","authoritative_mansaka_text","authoritative_translation_en",
             "takes_same_item","confirmed_by","confirmation_date","notes"]

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(ROOT)); ap.add_argument("--flutter-root", default=str(Path(ROOT).parent / "lumad-lingua-flutter")); a = ap.parse_args(); root = Path(a.root); ver = version(root)
    _, reg = read_csv(root / "metadata" / "reference_recordings.csv"); _, voc = read_csv(root / "metadata" / "vocabulary.csv")
    fx = root / "staging" / "firestore_export"; words = json.load(open(fx / "words.json")); lessons = json.load(open(fx / "lessons.json")); vs = json.load(open(fx / "voice_submissions.json"))
    wid_by_doc = {v["firestore_word_doc_id"]: v["word_id"] for v in voc if v.get("firestore_word_doc_id")}; wid_by_key = {v.get("item_key", ""): v["word_id"] for v in voc if v.get("item_key")}
    dic = Dictionary(root)
    # --- indices ---
    term_idx = defaultdict(list); pterm_idx = defaultdict(list)
    for w in words: term_idx[norm(w.get("term"))].append(w); pterm_idx[punct_norm(w.get("term"))].append(w)
    ex_idx = defaultdict(list)
    for w in words:
        nat = [l for l in (w.get("usageExampleNative") or "").split("\n") if l.strip()]; tr = [l for l in (w.get("usageExampleTranslation") or "").split("\n") if l.strip()]
        for i, l in enumerate(nat): ex_idx[sent_norm(l)].append((w, re.sub(r"^\d+[\.\)]\s*", "", l.strip()), re.sub(r"^\d+[\.\)]\s*", "", tr[i].strip()) if i < len(tr) else ""))
    les_idx = defaultdict(list)
    for l in lessons:
        if str(l.get("status", "")).upper() != "PUBLISHED": continue
        for t in l.get("tasks") or []:
            if t.get("nativeWord"): les_idx[norm(t["nativeWord"])].append((l, t, t["nativeWord"], (t.get("options") or [""])[0]))
            for p in t.get("pairs") or []:
                if p.get("meaning"): les_idx[norm(p["meaning"])].append((l, t, p["meaning"], p.get("native", "")))
            m = re.search(r'"([^"]+)" mean', t.get("questionText") or "")
            if m and t.get("options") and t.get("correctAnswerIndex") is not None: les_idx[norm(m.group(1))].append((l, t, m.group(1), t["options"][t["correctAnswerIndex"]]))
            if t.get("expectedSentence"): les_idx[sent_norm(t["expectedSentence"])].append((l, t, t["expectedSentence"].rstrip("."), ""))
    vs_idx = defaultdict(list)
    for v in vs:
        if v.get("transcript"): vs_idx[sent_norm(v["transcript"])].append(v)
    # repo text hits (supporting only)
    repo_hits = defaultdict(list); fr = Path(a.flutter_root)
    if fr.exists():
        files = [p for p in fr.rglob("*") if p.is_file() and p.suffix in (".dart", ".json", ".csv", ".arb") and not any(s in p.parts for s in (".git", "build", ".dart_tool", "research", "ios", "android", "macos", "windows", "linux", "web"))]
        texts = {p: p.read_text(errors="ignore") for p in files}
    else: texts = {}
    groups = defaultdict(list)
    for r in reg: groups[r["variant_group_id"]].append(r)
    bases = {g: strip_take_suffix(Path(rs[0]["object_name"]).stem)[0] for g, rs in groups.items()}
    nb_groups = {g: norm(b) for g, b in bases.items()}
    for g, b in bases.items():
        pat = re.compile(r"(?<![A-Za-z])" + re.escape(b) + r"(?![A-Za-z])", re.I)
        for p, t in texts.items():
            n = len(pat.findall(t))
            if n: repo_hits[g].append(f"{p.relative_to(fr)}×{n}")
    near = defaultdict(set)
    for g1, b1 in nb_groups.items():
        for g2, b2 in nb_groups.items():
            if g1 < g2 and (difflib.SequenceMatcher(None, b1, b2).ratio() >= 0.85 or (len(b1.split()) > 1 and set(b1.split()) == set(b2.split()))): near[g1].add(g2); near[g2].add(g1)
    ev_rows = []; cases = []; cat_count = Counter()
    for g, rs in sorted(groups.items(), key=lambda kv: bases[kv[0]]):
        b = bases[g]; nb = norm(b); ex = ex_idx.get(nb, []); le = les_idx.get(nb, []); te = term_idx.get(nb, []); pt = pterm_idx.get(punct_norm(b), []) if not te else []; vsub = vs_idx.get(nb, [])
        toks = [t for t in punct_norm(b).split() if t]; ptok = [f"{t}:{'/'.join(w['term'] for w in term_idx[t][:2])}" for t in toks if len(toks) > 1 and term_idx.get(t)]
        multi = len(rs) > 1
        cand = None; cat = "NO_PROJECT_MATCH"; dl = dic.lookup(b); dsum = dl["summary"]; corro = []
        if dl["category"] in ("DICTIONARY_HEADWORD_EXACT", "DICTIONARY_HEADWORD_ALTFORM"):
            cat = dl["category"]; cand = dict(item_key=dl["key"], item_type="word", text=dsum["headword"], tr=dsum["definition"], ph="", pos=dsum["pos"], coll="svelmoe1990", doc=dsum["entry_ids"] or f"A:{dsum['a_rows']}", field=f"headword (book p. {dsum['book_page']}; transcriptions {dsum['files']})")
        elif dl["category"] == "DICTIONARY_EXAMPLE_EXACT":
            cat = dl["category"]; cand = dict(item_key=dl["key"], item_type="phrase", text=dsum["mansaka"], tr=dsum["english"], ph="", pos="", coll="svelmoe1990", doc=dsum["entry_ids"], field=f"example sentence under headword '{dsum['headword']}' (book p. {dsum['book_page']}; transcriptions {dsum['files']})")
        elif dl["category"] == "DICTIONARY_FINDER_EXACT":
            cat = dl["category"]; cand = dict(item_key=dl["key"], item_type="word", text=dsum["headword"], tr=dsum["english"], ph="", pos="", coll="svelmoe1990", doc=f"finder pdf p. {dsum['pdf_page']}", field="English-Mansaka finder (headword entry not located in OCR)")
        if cat in AUTHORITATIVE:
            if te: corro.append(f"firestore words {';'.join(w['_id'] for w in te[:3])}")
            if ex: corro.append("firestore usage example"); 
            if le: corro.append(f"lesson item meaning '{'; '.join(sorted({x[3] for x in le if x[3]}))}'")
            if vsub: corro.append("voice submission transcript")
        if cat != "NO_PROJECT_MATCH": pass
        elif len({w["_id"] for w in te}) == 1:
            w = te[0]; cat = "EXACT_TERM_UNIQUE"; cand = dict(item_key=f"words:{w['_id']}", item_type="word", text=w["term"], tr="", ph=w.get("phonetic") or "", pos=w.get("pos") or "", coll="words", doc=w["_id"], field="term")
        elif len({w["_id"] for w in te}) > 1: cat = "MULTIPLE_CANDIDATES"; cand = dict(item_key="", item_type="word", text="; ".join(sorted({w["term"] for w in te})), tr="", ph="", pos="; ".join(sorted({w.get("pos") or "" for w in te})), coll="words", doc=";".join(sorted({w["_id"] for w in te})), field="term")
        elif len({x[0]["_id"] for x in ex}) == 1:
            w, line, trl = ex[0]; cat = "EXACT_EXAMPLE_SENTENCE_UNIQUE"; cand = dict(item_key=f"words_example:{w['_id']}:{sent_norm(line)}", item_type="phrase", text=line, tr=trl, ph="", pos="", coll="words", doc=w["_id"], field=f"usageExampleNative (entry term '{w['term']}')")
        elif len({x[0]["_id"] for x in ex}) > 1: cat = "MULTIPLE_CANDIDATES"; cand = dict(item_key="", item_type="phrase", text="; ".join(sorted({x[1] for x in ex})), tr="; ".join(sorted({x[2] for x in ex})), ph="", pos="", coll="words", doc=";".join(sorted({x[0]["_id"] for x in ex})), field="usageExampleNative")
        elif le:
            meanings = sorted({x[3] for x in le if x[3]}); lids = sorted({x[0]["_id"] for x in le})
            if len(meanings) <= 1:   # one text, one meaning; several published lessons agreeing is corroboration, not conflict
                l, t, txt, mean = le[0]; cat = "EXACT_LESSON_ITEM_UNIQUE"; cand = dict(item_key=f"lesson_item:{nb}", item_type="phrase" if len(txt.split()) > 1 else "word", text=txt, tr=meanings[0] if meanings else "", ph="", pos="", coll="lessons", doc=";".join(lids), field=f"tasks ({', '.join(sorted({x[1].get('type') for x in le}))}; lessons: {', '.join(sorted({str(x[0].get('title')) for x in le}))})")
            else: cat = "MULTIPLE_CANDIDATES"; cand = dict(item_key="", item_type="phrase", text="; ".join(sorted({x[2] for x in le})), tr="; ".join(meanings), ph="", pos="", coll="lessons", doc=";".join(lids), field="tasks")
        elif pt: cat = "NORMALIZED_TEXT_CANDIDATE"; w = pt[0]; cand = dict(item_key="", item_type="word", text=w["term"], tr="", ph=w.get("phonetic") or "", pos=w.get("pos") or "", coll="words", doc=";".join(x["_id"] for x in pt), field="term (differs only by punctuation)")
        elif vsub:
            v = vsub[0]; cat = "VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE"; cand = dict(item_key="", item_type="phrase", text=v["transcript"], tr=v.get("title") or "", ph="", pos="", coll="voice_submissions", doc=";".join(x["_id"] for x in vsub), field=f"transcript/title (status {', '.join(sorted({x.get('status','') for x in vsub}))})")
        elif dl["category"] in ("DICTIONARY_ORTHOGRAPHIC_VARIANT", "DICTIONARY_ROOT_CANDIDATE", "SPELLING_VARIANT_CANDIDATE") and dl["candidates"]:
            c0 = dl["candidates"][0]; cat = dl["category"]; cand = dict(item_key="", item_type="word", text=c0.get("headword", c0["form"]), tr=c0.get("definition", ""), ph="", pos=c0.get("pos", ""), coll="svelmoe1990", doc=c0.get("entry_ids", ""), field=f"{dl['rule']}: '{b}' -> '{c0['form']}'")
        elif near.get(g): cat = "SPELLING_VARIANT_CANDIDATE"
        elif ptok or dl["category"] == "PARTIAL_TOKEN_CANDIDATE": cat = "PARTIAL_TOKEN_CANDIDATE"
        gloss_conflict = ""
        if le and dl["tokens"]:
            lm = "; ".join(sorted({x[3] for x in le if x[3]})); gloss_conflict = f"lesson gloss '{lm}' vs dictionary token glosses [{dl['tokens'][:120]}]"
        authoritative = cat in AUTHORITATIVE and not multi
        if multi and cat in AUTHORITATIVE: cat_review = "MULTIPLE_TAKE_CANDIDATE"
        elif multi: cat_review = "MULTIPLE_TAKE_CANDIDATE"
        else: cat_review = cat
        cat_count[cat_review if not authoritative else cat] += 1
        existing = wid_by_doc.get(cand["doc"], "") if cand and cat == "EXACT_TERM_UNIQUE" else wid_by_key.get(cand["item_key"], "") if cand else ""
        for r in rs:
            stem = Path(r["object_name"]).stem; _, suf = strip_take_suffix(stem)
            ev_rows.append({"recording_id": r["recording_id"], "object_name": r["object_name"], "filename_stem": stem, "base_text": b, "take_suffix": suf, "variant_group_id": g, "group_size": len(rs),
                            "evidence_category": cat if authoritative else cat_review, "authoritative": str(authoritative).lower(), "item_key": cand["item_key"] if cand else "", "item_type": cand["item_type"] if cand else ("phrase" if len(toks) > 1 else "word"),
                            "candidate_mansaka_text": cand["text"] if cand else "", "candidate_translation_en": cand["tr"] if cand else "", "candidate_phonetic": cand["ph"] if cand else "", "candidate_pos": cand["pos"] if cand else "",
                            "source_collection": cand["coll"] if cand else "", "source_doc_id": cand["doc"] if cand else "", "source_field": cand["field"] if cand else "",
                            "dict_headword": dsum.get("headword", ""), "dict_all_forms": dsum.get("all_headword_strings", ""), "dict_entry_ids": dsum.get("entry_ids", ""), "dict_pos": dsum.get("pos", ""), "dict_definition": (dsum.get("definition") or dsum.get("english", ""))[:300],
                            "dict_book_page": dsum.get("book_page", dsum.get("pdf_page", "")), "dict_homonym_count": dsum.get("homonym_count", ""), "dict_rule": dl["rule"], "dict_candidates": " || ".join(f"{c['form']}: {c.get('pos','')} {c.get('definition','')[:60]}" for c in dl["candidates"]),
                            "gloss_conflict": gloss_conflict, "corroboration": "; ".join(corro), "existing_word_id": existing,
                            "other_candidates": ("base evidence " + cat) if multi and cat != "NO_PROJECT_MATCH" else "", "partial_token_matches": dl["tokens"] or "; ".join(ptok), "near_variant_groups": ";".join(sorted(near.get(g, []))), "repo_hits": "; ".join(repo_hits.get(g, [])), "notes": ""})
        if not authoritative:
            reasons = {"MULTIPLE_TAKE_CANDIDATE": f"{len(rs)} recordings share the filename text (explicit '(n)' suffixes); confirm they are all takes of one item" + (f"; item itself is resolved by {cat} evidence (prefilled)" if cat in AUTHORITATIVE else (f"; item candidate: {cat} ({dl['rule']})" if cand else "; no project/dictionary record for the text")),
                       "DICTIONARY_ORTHOGRAPHIC_VARIANT": f"dictionary headword differs only by the 1990 orthography rule {dl['rule']} ('{b}' -> '{dl['candidates'][0]['form'] if dl['candidates'] else ''}'); confirm the rule applies", "DICTIONARY_ROOT_CANDIDATE": "inflected form: only the affix-stripped root is a dictionary headword; the filename form itself is not listed",
                       "MULTIPLE_CANDIDATES": "more than one project record matches the text", "NORMALIZED_TEXT_CANDIDATE": "dictionary term differs only by punctuation; identity not explicit",
                       "VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE": "only a community voice-submission transcript matches (not curated vocabulary)", "SPELLING_VARIANT_CANDIDATE": "similar filename text exists in another group; linguistic identity unknown",
                       "PARTIAL_TOKEN_CANDIDATE": "no record for the whole text; some tokens are dictionary terms", "NO_PROJECT_MATCH": "no project record contains this text"}[cat_review]
            sugg = {"MULTIPLE_TAKE_CANDIDATE": "takes_same_item=Y + CONFIRM_CANDIDATE (if candidate) or CONFIRM_TEXT_NEW_ITEM; takes_same_item=N + SPLIT",
                    "DICTIONARY_ORTHOGRAPHIC_VARIANT": "CONFIRM_CANDIDATE (accepts the dictionary entry; the recorded spelling is kept as form_text) or CONFIRM_TEXT_NEW_ITEM", "DICTIONARY_ROOT_CANDIDATE": "CONFIRM_TEXT_NEW_ITEM with the inflected form as authoritative text (root gloss prefilled)",
                    "MULTIPLE_CANDIDATES": "CONFIRM_CANDIDATE with decision_target=<doc id>; or CONFIRM_TEXT_NEW_ITEM", "NORMALIZED_TEXT_CANDIDATE": "CONFIRM_CANDIDATE (decision_target=<doc id>) or CONFIRM_TEXT_NEW_ITEM",
                    "VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE": "CONFIRM_TEXT_NEW_ITEM (fix spelling/translation if needed)", "SPELLING_VARIANT_CANDIDATE": "CONFIRM_TEXT_NEW_ITEM, or SAME_AS <related case> if it is the same item",
                    "PARTIAL_TOKEN_CANDIDATE": "CONFIRM_TEXT_NEW_ITEM", "NO_PROJECT_MATCH": "CONFIRM_TEXT_NEW_ITEM (correct the spelling in authoritative_mansaka_text if the filename is wrong)"}[cat_review]
            cases.append({"recording_ids": ";".join(r["recording_id"] for r in rs), "original_filenames": " | ".join(r["object_name"] for r in rs), "n_recordings": len(rs), "filename_group": g, "display_text_from_filename": b,
                          "evidence_category": cat_review, "rule_tag": dl["rule"], "candidate_word_id": existing, "candidate_item_key": cand["item_key"] if cand else "", "candidate_mansaka_text": cand["text"] if cand else "", "candidate_translation_en": cand["tr"] if cand else "",
                          "candidate_phonetic": cand["ph"] if cand else "", "candidate_pos": cand["pos"] if cand else "", "candidate_source": f"{cand['coll']}:{cand['doc']} [{cand['field']}]" if cand else "",
                          "dictionary_candidates": " || ".join(f"{c['form']}: {c.get('pos','')} {c.get('definition','')[:80]}" for c in dl["candidates"]), "partial_token_matches": dl["tokens"] or "; ".join(ptok), "gloss_conflict": gloss_conflict,
                          "related_case_ids": ";".join(sorted(near.get(g, []))), "reason_for_review": reasons, "suggested_actions": sugg, "decision": "", "decision_target": "", "authoritative_mansaka_text": "", "authoritative_translation_en": "",
                          "takes_same_item": "" , "confirmed_by": "", "confirmation_date": "", "notes": ""})
    # stable case ids: RC + group number; related ids converted from group ids to case ids
    gid2case = {c["filename_group"]: f"RC{int(c['filename_group'][2:]):03d}" for c in cases}
    for c in cases: c["review_case_id"] = gid2case[c["filename_group"]]; c["related_case_ids"] = ";".join(gid2case.get(x, x) for x in c["related_case_ids"].split(";") if x)
    # preserve decisions already entered in an existing queue
    _, old_q = read_csv(root / "metadata" / "mapping_review_queue.csv"); oldq = {q["review_case_id"]: q for q in old_q}
    for c in cases:
        o = oldq.get(c["review_case_id"])
        if o:
            for k in ("decision", "decision_target", "authoritative_mansaka_text", "authoritative_translation_en", "takes_same_item", "confirmed_by", "confirmation_date", "notes"): c[k] = o.get(k, "")
    write_csv(root / "metadata" / "mapping_evidence.csv", EV_HEADER, ev_rows); write_csv(root / "metadata" / "mapping_review_queue.csv", RQ_HEADER, cases)
    summ = {"generated": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"), "corpus_version": ver, "recordings": len(ev_rows), "filename_groups": len(groups), "category_counts_by_group": dict(cat_count),
            "authoritative_recordings": sum(1 for e in ev_rows if e["authoritative"] == "true"), "review_cases": len(cases), "recordings_in_review": sum(c["n_recordings"] for c in cases),
            "dictionary_available": dic.available, "dictionary_entries": len(dic.entries), "dictionary_examples": len(dic.examples), "dictionary_finder_rows": len(dic.finder), "sources": {"words": len(words), "usage_example_lines": sum(len(v) for v in ex_idx.values()), "published_lesson_items": sum(len(v) for v in les_idx.values()), "voice_submission_transcripts": sum(len(v) for v in vs_idx.values()), "repo_files_scanned": len(texts)}}
    (root / "reports").mkdir(exist_ok=True); (root / "reports" / f"mapping_evidence_summary_{'v' + ver.split('_v')[-1]}.json").write_text(json.dumps(summ, indent=1)); print(json.dumps(summ, indent=1))

if __name__ == "__main__": main()
