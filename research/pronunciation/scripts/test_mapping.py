#!/usr/bin/env python3
"""Mapping-specific tests (unittest). Runs on a temporary copy of the dataset metadata (no audio needed).
Covers: evidence categories, no auto-promotion of candidates or suffixed takes, stable W ids, multi-reference items,
review ingestion (valid decisions, conflicts rejected, SAME_AS chains, SPLIT, EXCLUDE), ledger append-only."""
import csv, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
HERE = Path(__file__).resolve().parent; sys.path.insert(0, str(HERE))
from common import read_csv, write_csv
from mapping_common import AUTHORITATIVE, CATEGORIES
SRC = Path(os.environ.get("LLP_DATASET_ROOT", HERE.parent))
PY = sys.executable

def run(script, root, *args):
    return subprocess.run([PY, str(HERE / script), *args, "--root", str(root)], capture_output=True, text=True)

class Mapping(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(); root = Path(cls.tmp)
        for d in ("metadata", "manifests", "config", "staging/firestore_export", "validation", "reports", "raw/reference"):
            (root / d).mkdir(parents=True)
        for f in ("VERSION",): shutil.copy(SRC / f, root / f)
        for f in (SRC / "metadata").glob("*.csv"): shutil.copy(f, root / "metadata" / f.name)
        for f in (SRC / "manifests").glob("*.csv"): shutil.copy(f, root / "manifests" / f.name)
        for f in (SRC / "staging" / "firestore_export").glob("*.json"): shutil.copy(f, root / "staging" / "firestore_export" / f.name)
        if (SRC / "staging" / "dictionary").exists():
            (root / "staging" / "dictionary").mkdir(); [shutil.copy(f, root / "staging" / "dictionary" / f.name) for f in (SRC / "staging" / "dictionary").glob("*.csv")]
        shutil.copy(SRC / "config" / "corpus.yaml", root / "config" / "corpus.yaml"); (root / "metadata" / "vocabulary_id_history.csv").unlink(missing_ok=True)
        # the fixture replays the review from the pre-review state: human-confirmed mappings are stripped (the live dataset may already carry them)
        (root / "metadata" / "mapping_audit_log.csv").unlink(missing_ok=True)
        ih, _ = read_csv(root / "metadata" / "reference_mapping_input.csv"); write_csv(root / "metadata" / "reference_mapping_input.csv", ih, [])
        rh, reg0 = read_csv(root / "metadata" / "reference_recordings.csv")
        for x in reg0:
            if x.get("evidence_category") == "HUMAN_CONFIRMED":
                x.update(mapping_status="unresolved", word_id="", item_key="", mapping_evidence="", evidence_category="", mapping_confirmed_by="", mapping_confirmation_date="")
        write_csv(root / "metadata" / "reference_recordings.csv", rh, reg0)
        vh, voc0 = read_csv(root / "metadata" / "vocabulary.csv"); write_csv(root / "metadata" / "vocabulary.csv", vh, [v for v in voc0 if v.get("evidence_category") != "HUMAN_CONFIRMED"])
        cls.root = root
        r = run("resolve_vocabulary_mapping.py", root, "--flutter-root", "/nonexistent"); assert r.returncode == 0, r.stderr
        # drop raw paths so the fixture does not require audio
        _, reg = read_csv(root / "metadata" / "reference_recordings.csv")
        for x in reg: x["raw_audio_path"] = ""
        write_csv(root / "metadata" / "reference_recordings.csv", list(reg[0].keys()), reg)
        r = run("build_reference_registry.py", root); assert r.returncode == 0, r.stderr
    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.tmp)
    def reg(self): return read_csv(self.root / "metadata" / "reference_recordings.csv")[1]
    def voc(self): return read_csv(self.root / "metadata" / "vocabulary.csv")[1]
    def test_evidence_categories_valid_and_no_candidate_promotion(self):
        _, ev = read_csv(self.root / "metadata" / "mapping_evidence.csv"); self.assertEqual(len(ev), 128)
        self.assertTrue(all(e["evidence_category"] in CATEGORIES for e in ev))
        for e in ev:
            if e["authoritative"] == "true": self.assertIn(e["evidence_category"], AUTHORITATIVE); self.assertEqual(e["take_suffix"], "")
        for r in self.reg():
            if r["mapping_status"] == "mapped": self.assertIn(r["evidence_category"], AUTHORITATIVE | {"HUMAN_CONFIRMED"})
    def test_stable_ids_preserved(self):
        v = {x["word_id"]: x for x in self.voc()}
        for wid, doc in [("W001", "9wYfRCZDf3elrtSWzbe4"), ("W011", "WvotzMcPJqYRVSZOz68O")]: self.assertEqual(v[wid]["firestore_word_doc_id"], doc)
        _, hist = read_csv(self.root / "metadata" / "vocabulary_id_history.csv"); ids = [h["word_id"] for h in hist]; self.assertEqual(len(ids), len(set(ids)))
        before = self.voc(); run("build_reference_registry.py", self.root); after = self.voc(); self.assertEqual([(a["word_id"], a["item_key"]) for a in before], [(a["word_id"], a["item_key"]) for a in after])
    def test_review_ingestion_multi_reference_same_as_split_exclude(self):
        qp = self.root / "metadata" / "mapping_review_queue.csv"; qh, q = read_csv(qp); by = {c["review_case_id"]: c for c in q}
        masurom = next(c for c in q if c["display_text_from_filename"] == "madyaw na masurom"); gabila = next(c for c in q if c["display_text_from_filename"] == "madyaw na gabila")
        pas1 = by["RC074"]; pas2 = by["RC075"]; upat = next(c for c in q if c["display_text_from_filename"] == "upat"); nomatch = next(c for c in q if c["evidence_category"] == "NO_PROJECT_MATCH")
        masurom.update(decision="CONFIRM_CANDIDATE", takes_same_item="Y", confirmed_by="V01", confirmation_date="2026-10-01")
        gabila.update(decision="CONFIRM_CANDIDATE", takes_same_item="Y", confirmed_by="V01", confirmation_date="2026-10-01")
        pas1.update(decision="CONFIRM_TEXT_NEW_ITEM", authoritative_mansaka_text="FIXTURE TEXT", confirmed_by="V01", confirmation_date="2026-10-01")
        pas2.update(decision="SAME_AS", decision_target="RC074", confirmed_by="V01", confirmation_date="2026-10-01")
        upat.update(decision="SPLIT", confirmed_by="RESEARCHER", confirmation_date="2026-10-01", notes="fixture split")
        nomatch.update(decision="EXCLUDE", confirmed_by="RESEARCHER", confirmation_date="2026-10-01", notes="fixture exclusion")
        write_csv(qp, qh, q)
        r = run("apply_mapping_review.py", self.root, "--dry-run"); self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        r = run("apply_mapping_review.py", self.root, "--no-rebuild"); self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        r = run("build_reference_registry.py", self.root); self.assertEqual(r.returncode, 0, r.stderr)
        reg = {x["recording_id"]: x for x in self.reg()}; voc = {x["item_key"]: x for x in self.voc()}
        m_ids = masurom["recording_ids"].split(";"); wids = {reg[i]["word_id"] for i in m_ids}; self.assertEqual(len(wids), 1); w = wids.pop()
        item = next(v for v in voc.values() if v["word_id"] == w); self.assertEqual(int(item["reference_count"]), 4); self.assertEqual(item["translation_en"], "Good morning")
        g = {reg[i]["word_id"] for i in gabila["recording_ids"].split(";")}; self.assertEqual(len(g), 1); self.assertNotEqual(g, {w})
        p1 = reg[pas1["recording_ids"]]["word_id"]; p2 = reg[pas2["recording_ids"]]["word_id"]; self.assertEqual(p1, p2); self.assertEqual(next(v for v in voc.values() if v["word_id"] == p1)["mansaka_text"], "FIXTURE TEXT")
        for i in nomatch["recording_ids"].split(";"): self.assertEqual(reg[i]["mapping_status"], "unresolved"); self.assertEqual(reg[i]["validation_status"], "validated")
        _, q2 = read_csv(qp); ids = [c["review_case_id"] for c in q2]; self.assertTrue(any(i.startswith(upat["review_case_id"] + "-") for i in ids)); self.assertNotIn(masurom["review_case_id"], ids)
        _, audit = read_csv(self.root / "metadata" / "mapping_audit_log.csv"); self.assertEqual(len(audit), 6)
    def test_conflict_and_bad_decisions_rejected(self):
        qp = self.root / "metadata" / "mapping_review_queue.csv"; qh, q = read_csv(qp)
        c = next(x for x in q if x["evidence_category"] == "NO_PROJECT_MATCH" and not x["decision"]); c.update(decision="CONFIRM_TEXT_NEW_ITEM", confirmed_by="V01", confirmation_date="2026-10-01")  # missing text
        d = next(x for x in q if x["evidence_category"] == "MULTIPLE_TAKE_CANDIDATE" and not x["decision"]); d.update(decision="CONFIRM_TEXT_NEW_ITEM", authoritative_mansaka_text="X", confirmed_by="V01", confirmation_date="2026-10-01")  # no takes_same_item
        undecided = [x for x in q if not x["decision"] and x not in (c, d)]
        e = undecided[0]; e.update(decision="SAME_AS", decision_target="RC999", confirmed_by="V01", confirmation_date="2026-10-01")
        f = undecided[1]; f.update(decision="BOGUS")
        write_csv(qp, qh, q); r = run("apply_mapping_review.py", self.root, "--dry-run"); self.assertEqual(r.returncode, 1); out = r.stdout
        for msg in ("authoritative_mansaka_text required", "takes_same_item=Y", "has no decision", "unknown decision"): self.assertIn(msg, out)
        for x in (c, d, e, f): x.update(decision="", decision_target="", authoritative_mansaka_text="", confirmed_by="", confirmation_date="")
        write_csv(qp, qh, q)

if __name__ == "__main__": unittest.main(verbosity=2)
