#!/usr/bin/env python3
"""Learner-collection and human-rating tests (unittest). Temporary fixtures only: the fixture copies the dataset metadata/config
into a temp root and synthesises tiny WAV files as stand-ins for reference and learner audio. No real learner data, participants
or ratings are created anywhere outside the temp directory, and nothing is written back to the dataset.
Covers: valid import, malformed speaker/word ids, unknown word id, duplicate primary, valid retake, retake without prior take,
missing-item reporting, corrupt file handling, checksum creation, raw preservation (bytes, read-only, no overwrite), rating 1-5
validation, invalid rating / unratable-without-reason / wrong reference / wrong item / duplicate / blind-flag rejection,
deterministic randomisation, deterministic ~10% pass-2 sampling, freeze refusal when ratings are missing, loader contract."""
import csv, json, os, random, shutil, struct, subprocess, sys, tempfile, unittest, wave
from pathlib import Path
HERE = Path(__file__).resolve().parent; sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from common import read_csv, write_csv
SRC = Path(os.environ.get("LLP_DATASET_ROOT", HERE.parent)); PY = sys.executable

def run(script, root, *args, check=False):
    r = subprocess.run([PY, str(HERE / script), *args, "--root", str(root)], capture_output=True, text=True)
    if check and r.returncode != 0: raise AssertionError(f"{script} {args} failed:\n{r.stdout}\n{r.stderr}")
    return r

def synth_wav(path, seed=0, sr=16000, dur=0.6, channels=1):
    rng = random.Random(seed); n = int(sr * dur); frames = bytearray()
    for i in range(n):
        v = int(8000 * (0.5 + 0.5 * ((i * 7 * (seed + 1)) % 100) / 100) * (1 if (i // 37) % 2 else -1)) + rng.randint(-200, 200)
        for _ in range(channels): frames += struct.pack("<h", max(-32768, min(32767, v)))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w: w.setnchannels(channels); w.setsampwidth(2); w.setframerate(sr); w.writeframes(bytes(frames))

class Fixture:
    @staticmethod
    def build(tmp):
        root = Path(tmp)
        for d in ("metadata", "manifests", "config/preprocessing", "config/features", "validation", "reports", "raw/reference", "raw/learner", "staging", "checksums"): (root / d).mkdir(parents=True, exist_ok=True)
        shutil.copy(SRC / "VERSION", root / "VERSION"); shutil.copy(SRC / "config" / "corpus.yaml", root / "config" / "corpus.yaml")
        shutil.copy(SRC / "config" / "preprocessing" / "PP001.yaml", root / "config" / "preprocessing" / "PP001.yaml"); shutil.copy(SRC / "config" / "features" / "FE001.yaml", root / "config" / "features" / "FE001.yaml")
        for f in (SRC / "metadata").glob("*.csv"):
            if f.name not in {"learner_import_log.csv", "learner_collection_status.csv"}: shutil.copy(f, root / "metadata" / f.name)
        shutil.copy(SRC / "manifests" / "exclusions.csv", root / "manifests" / "exclusions.csv"); shutil.copy(SRC / "validation" / "ratings.csv", root / "validation" / "ratings.csv")
        for f in ("rating_scale.md",): shutil.copy(SRC / "validation" / f, root / "validation" / f)
        shutil.copytree(SRC / "pipeline", root / "pipeline", ignore=shutil.ignore_patterns("__pycache__"))
        hdr, reg = read_csv(root / "metadata" / "reference_recordings.csv")
        for i, r in enumerate(reg): synth_wav(root / r["raw_audio_path"], seed=1000 + i, sr=44100, dur=0.5, channels=2); r["sha256"] = __import__("common").sha256_file(root / r["raw_audio_path"])
        write_csv(root / "metadata" / "reference_recordings.csv", hdr, reg)
        sh, so = read_csv(root / "metadata" / "source_objects.csv"); shas = {r["object_name"]: r["sha256"] for r in reg}
        for o in so: o["staged_sha256"] = shas.get(o["object_name"], o.get("staged_sha256", ""))   # fixture audio replaces the real bytes
        write_csv(root / "metadata" / "source_objects.csv", sh, so)
        run("probe_audio.py", root, check=True); run("build_learner_targets.py", root, check=True); run("build_manifest.py", root, check=True)
        return root

class LearnerImport(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.tmp = tempfile.mkdtemp(); cls.root = Fixture.build(cls.tmp); cls.inbox = Path(cls.tmp) / "inbox"; cls.inbox.mkdir()
    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.tmp, ignore_errors=True)
    def log(self): return read_csv(self.root / "metadata" / "learner_import_log.csv")[1]
    def manifest(self): return {m["recording_id"]: m for m in read_csv(self.root / "manifests" / "manifest.csv")[1]}
    def test_01_targets_generated_from_metadata(self):
        _, t = read_csv(self.root / "metadata" / "learner_targets.csv"); _, v = read_csv(self.root / "metadata" / "vocabulary.csv")
        self.assertEqual(len(t), len(v)); self.assertEqual(len(t), 112)
        for row in t:
            refs = row["reference_recording_ids"].split(";"); self.assertEqual(row["primary_playback_reference_id"], min(refs)); self.assertIn(row["translation_status"], {"available", "flagged", "missing"})
            self.assertEqual(row["translation_review_required"] == "true", row["translation_status"] != "available"); self.assertEqual(row["collection_eligible"], "true")
        self.assertEqual(sum(int(r["reference_count"]) for r in t), 128); self.assertEqual(sum(1 for r in t if int(r["reference_count"]) > 1), 13)
    def test_02_valid_import_preserves_bytes_and_logs(self):
        b = self.inbox / "b1"; b.mkdir(); synth_wav(b / "S001_W001.wav", 1); synth_wav(b / "S001_W002.wav", 2); synth_wav(b / "S001_W003.wav", 3)
        r = run("import_learner_audio.py", self.root, "--source", str(b), "--enrol", "--session", "CS01", "--date", "2026-10-20")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr); self.assertIn("'imported': 3", r.stdout)
        src = (b / "S001_W001.wav").read_bytes(); dst = self.root / "raw" / "learner" / "S001" / "S001_W001.wav"
        self.assertEqual(dst.read_bytes(), src); self.assertEqual(dst.stat().st_mode & 0o222, 0); self.assertEqual((b / "S001_W001.wav").read_bytes(), src)
        log = {l["recording_id"]: l for l in self.log()}; self.assertEqual(log["S001_W001"]["status"], "imported"); self.assertEqual(log["S001_W001"]["sha256"], __import__("common").sha256_file(dst))
        self.assertEqual(log["S001_W001"]["readable"], "true"); self.assertEqual(log["S001_W001"]["source_filename"], "S001_W001.wav"); self.assertNotIn(str(b), json.dumps(log))
        m = self.manifest()["S001_W001"]; self.assertEqual(m["reference_recording_id"], "REF_001"); self.assertEqual(m["collection_session_id"], "CS01"); self.assertEqual(m["recording_date"], "2026-10-20"); self.assertEqual(m["included_in_experiment"], "false")
        _, parts = read_csv(self.root / "metadata" / "participants.csv"); self.assertTrue(any(p["speaker_id"] == "S001" and p["role"] == "learner" for p in parts))
        aq = {a["file_path"]: a for a in read_csv(self.root / "metadata" / "audio_quality.csv")[1]}; self.assertEqual(aq["raw/learner/S001/S001_W001.wav"]["sample_rate_hz"], "16000")
        sums = (self.root / "checksums" / "SHA256SUMS_raw_v0.2.txt").read_text(); self.assertIn("raw/learner/S001/S001_W001.wav", sums); self.assertIn(log["S001_W001"]["sha256"], sums)
    def test_03_missing_items_reported(self):
        _, st = read_csv(self.root / "metadata" / "learner_collection_status.csv"); s = {x["speaker_id"]: x for x in st}["S001"]
        self.assertEqual(s["expected_items"], "112"); self.assertEqual(s["primary_present"], "3"); self.assertEqual(s["missing_items_count"], "109"); self.assertIn("W004", s["missing_items"].split(";")); self.assertNotIn("W001", s["missing_items"].split(";"))
    def test_04_malformed_and_unknown_ids_rejected(self):
        b = self.inbox / "b2"; b.mkdir()
        for n in ("X001_W001.wav", "s001_w004.wav", "S001_W1.wav", "S001_W999.wav", "S001_W005_T01.wav", "S001_W005.txt", "S002_W001.wav"): synth_wav(b / n, 9)
        r = run("import_learner_audio.py", self.root, "--source", str(b)); self.assertEqual(r.returncode, 1)
        log = {l["source_filename"]: l for l in self.log() if l["import_batch_id"] == max(x["import_batch_id"] for x in self.log())}
        self.assertIn("malformed_id", log["X001_W001.wav"]["reason"]); self.assertIn("case", log["s001_w004.wav"]["reason"]); self.assertIn("malformed_id", log["S001_W1.wav"]["reason"])
        self.assertIn("unknown_word_id", log["S001_W999.wav"]["reason"]); self.assertIn("T01", log["S001_W005_T01.wav"]["reason"]); self.assertIn("unsupported_format", log["S001_W005.txt"]["reason"])
        self.assertIn("speaker_not_enrolled", log["S002_W001.wav"]["reason"]); self.assertFalse((self.root / "raw" / "learner" / "S002").exists()); self.assertFalse(any((self.root / "raw" / "learner").rglob("X001*")))
    def test_05_duplicate_primary_and_no_overwrite(self):
        b = self.inbox / "b3"; b.mkdir(); synth_wav(b / "S001_W006.wav", 6); synth_wav(b / "S001_W006.flac" if False else b / "S001_W006.m4a", 7)
        r = run("import_learner_audio.py", self.root, "--source", str(b)); self.assertEqual(r.returncode, 1); self.assertIn("duplicate_in_batch", r.stdout); self.assertFalse(any((self.root / "raw" / "learner" / "S001").glob("S001_W006*")))
        b4 = self.inbox / "b4"; b4.mkdir(); synth_wav(b4 / "S001_W001.wav", 999)  # different bytes, same id
        before = (self.root / "raw" / "learner" / "S001" / "S001_W001.wav").read_bytes(); r = run("import_learner_audio.py", self.root, "--source", str(b4)); self.assertEqual(r.returncode, 1); self.assertIn("conflict_existing_file_differs", r.stdout)
        self.assertEqual((self.root / "raw" / "learner" / "S001" / "S001_W001.wav").read_bytes(), before)
        b5 = self.inbox / "b5"; b5.mkdir(); shutil.copy(self.inbox / "b1" / "S001_W001.wav", b5 / "S001_W001.wav"); r = run("import_learner_audio.py", self.root, "--source", str(b5)); self.assertEqual(r.returncode, 0); self.assertIn("already_imported", r.stdout)
    def test_06_retake_rules(self):
        b = self.inbox / "b6"; b.mkdir(); synth_wav(b / "S001_W007_T02.wav", 72)
        r = run("import_learner_audio.py", self.root, "--source", str(b)); self.assertEqual(r.returncode, 1); self.assertIn("retake_without_prior_take", r.stdout)
        synth_wav(b / "S001_W007.wav", 71); r = run("import_learner_audio.py", self.root, "--source", str(b)); self.assertEqual(r.returncode, 0, r.stdout); self.assertIn("'imported': 2", r.stdout); self.assertIn("no exclusion row yet", r.stdout)
        self.assertTrue((self.root / "raw" / "learner" / "S001" / "S001_W007.wav").exists() and (self.root / "raw" / "learner" / "S001" / "S001_W007_T02.wav").exists())
        m = self.manifest(); self.assertEqual(m["S001_W007_T02"]["take_number"], "2"); self.assertEqual(m["S001_W007"]["take_number"], "1")
        chk = run("check_dataset.py", self.root, "--no-report"); self.assertIn("superseded by take 2 but has no exclusion row", chk.stdout)
        eh, exc = read_csv(self.root / "manifests" / "exclusions.csv"); exc.append({"exclusion_id": "EX0001", "recording_id": "S001_W007", "speaker_id": "S001", "word_id": "W007", "reason_code": "CORRUPT", "reason_detail": "recorder stopped early (fixture)", "stage": "collection", "recollection_attempted": "true", "recollection_recording_id": "S001_W007_T02", "decided_by": "RESEARCHER", "decision_date": "2026-10-20", "dataset_version": m["S001_W007"]["dataset_version"]})
        write_csv(self.root / "manifests" / "exclusions.csv", eh, exc); run("build_manifest.py", self.root, check=True); mh, man = read_csv(self.root / "manifests" / "manifest.csv")
        for x in man:
            if x["recording_id"] == "S001_W007": x["exclusion_id"] = "EX0001"; x["included_in_experiment"] = "false"
        write_csv(self.root / "manifests" / "manifest.csv", mh, man); chk = run("check_dataset.py", self.root, "--no-report"); self.assertNotIn("superseded by take", chk.stdout)
        _, st = read_csv(self.root / "metadata" / "learner_collection_status.csv") if run("learner_collection_status.py", self.root, check=True) is None else read_csv(self.root / "metadata" / "learner_collection_status.csv")
        s = {x["speaker_id"]: x for x in st}["S001"]; self.assertEqual(s["retakes"], "1"); self.assertEqual(s["excluded"], "1"); self.assertEqual(s["active_ratable"], "4")
    def test_07_corrupt_file_imported_flagged_not_dropped(self):
        b = self.inbox / "b7"; b.mkdir(); (b / "S001_W008.wav").write_bytes(b"RIFF\x00\x00\x00\x00WAVEjunkjunkjunk" + os.urandom(64))
        r = run("import_learner_audio.py", self.root, "--source", str(b)); self.assertEqual(r.returncode, 0, r.stdout); self.assertIn("unreadable", r.stdout)
        self.assertTrue((self.root / "raw" / "learner" / "S001" / "S001_W008.wav").exists()); m = self.manifest()["S001_W008"]; self.assertEqual(m["readable"], "false")
        chk = run("check_dataset.py", self.root, "--no-report"); self.assertIn("unreadable but not excluded", chk.stdout)
        _, st = read_csv(self.root / "metadata" / "learner_collection_status.csv"); self.assertEqual({x["speaker_id"]: x for x in st}["S001"]["unreadable"], "1")
    def test_08_dry_run_writes_nothing(self):
        b = self.inbox / "b8"; b.mkdir(); synth_wav(b / "S001_W009.wav", 90); n = len(self.log())
        r = run("import_learner_audio.py", self.root, "--source", str(b), "--dry-run"); self.assertEqual(r.returncode, 0); self.assertIn("would_import", r.stdout); self.assertFalse((self.root / "raw" / "learner" / "S001" / "S001_W009.wav").exists()); self.assertEqual(len(self.log()), n)

class Rating(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(); cls.root = Fixture.build(cls.tmp); b = Path(cls.tmp) / "inbox"; b.mkdir(); cls.items = [f"W{i:03d}" for i in range(1, 16)]
        for s in ("S001", "S002"):
            for w in cls.items: synth_wav(b / f"{s}_{w}.wav", hash((s, w)) % 1000)
        run("import_learner_audio.py", cls.root, "--source", str(b), "--enrol", check=True)
    @classmethod
    def tearDownClass(cls): shutil.rmtree(cls.tmp, ignore_errors=True)
    def pkg(self, pid): return self.root / "validation" / "rating_packages" / pid
    def fill(self, pid, fn):
        oh, rows = read_csv(self.pkg(pid) / "rating_order.csv")
        for r in rows: fn(r)
        write_csv(self.pkg(pid) / "rating_order.csv", oh, rows)
    def test_01_package_deterministic_and_blind(self):
        r = run("rating_tool.py", self.root, "package", "--pass", "1", "--validator", "V01", "--seed", "7", check=True); pid = "RP1-V01-v0.2-seed7"
        oh, rows = read_csv(self.pkg(pid) / "rating_order.csv"); self.assertEqual(len(rows), 30); info = json.loads((self.pkg(pid) / "package.json").read_text())
        for h in oh: self.assertFalse(any(t in h.lower() for t in ("dtw", "hmm", "cosine", "score", "similarity", "distance", "predict", "threshold")), h)
        self.assertFalse(info["algorithm_fields_present"]); self.assertEqual(info["seed"], 7); self.assertTrue(all(r["human_rating"] == "" for r in rows))
        for r in rows: self.assertEqual(r["reference_recording_id"], "REF_" + {"W001": "001"}.get(r["word_id"], r["reference_recording_id"][4:]))
        ids = [r["recording_id"] for r in rows]; self.assertNotEqual(ids, sorted(ids)); self.assertEqual(set(ids), {f"{s}_{w}" for s in ("S001", "S002") for w in self.items})
        tmp2 = tempfile.mkdtemp(); root2 = Fixture.build(tmp2); b = Path(tmp2) / "inbox"; b.mkdir()
        for s in ("S001", "S002"):
            for w in self.items: synth_wav(b / f"{s}_{w}.wav", 1)
        run("import_learner_audio.py", root2, "--source", str(b), "--enrol", check=True); run("rating_tool.py", root2, "package", "--pass", "1", "--validator", "V01", "--seed", "7", check=True)
        self.assertEqual([r["recording_id"] for r in read_csv(root2 / "validation" / "rating_packages" / pid / "rating_order.csv")[1]], ids)
        run("rating_tool.py", root2, "package", "--pass", "1", "--validator", "V01", "--seed", "8", check=True)
        self.assertNotEqual([r["recording_id"] for r in read_csv(root2 / "validation" / "rating_packages" / "RP1-V01-v0.2-seed8" / "rating_order.csv")[1]], ids); shutil.rmtree(tmp2, ignore_errors=True)
        r = run("rating_tool.py", self.root, "package", "--pass", "1", "--validator", "V01", "--seed", "7"); self.assertNotEqual(r.returncode, 0); self.assertIn("immutable", r.stdout + r.stderr)
    def test_02_ingest_rejections(self):
        pid = "RP1-V01-v0.2-seed7"; good = lambda r: r.update(human_rating="4", validation_status="rated", blind_confirmed="true", rating_date="2026-11-01")
        cases = {"6": lambda r: (good(r), r.update(human_rating="6")), "text": lambda r: (good(r), r.update(human_rating="good")), "2.5": lambda r: (good(r), r.update(human_rating="2.5")),
                 "unratable-no-reason": lambda r: (good(r), r.update(human_rating="", validation_status="unratable")), "wrong-ref": lambda r: (good(r), r.update(reference_recording_id="REF_128")),
                 "wrong-item": lambda r: (good(r), r.update(word_id="W002")), "not-blind": lambda r: (good(r), r.update(blind_confirmed="false")), "bad-date": lambda r: (good(r), r.update(rating_date="01/11/2026"))}
        for name, fn in cases.items():
            def apply(r, fn=fn):
                if r["sequence"] == "1": fn(r)
            self.fill(pid, apply); r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid)), "--dry-run"); self.assertEqual(r.returncode, 1, name); self.assertIn("REJECTED", r.stdout, name)
            self.assertEqual(len(read_csv(self.root / "validation" / "ratings.csv")[1]), 0, name)
        self.fill(pid, lambda r: r.update(human_rating="", validation_status="", unratable_reason="", blind_confirmed="", rating_date="", reference_recording_id=r["reference_recording_id"] if r["sequence"] != "1" else r["reference_recording_id"]))
        oh, rows = read_csv(self.pkg(pid) / "rating_order.csv"); t = {x["word_id"]: x for x in read_csv(self.root / "metadata" / "learner_targets.csv")[1]}
        for r in rows: r["word_id"] = r["recording_id"].split("_")[1]; r["reference_recording_id"] = t[r["word_id"]]["primary_playback_reference_id"]
        write_csv(self.pkg(pid) / "rating_order.csv", oh, rows)
    def test_03_ingest_valid_partial_then_freeze_refused_then_complete(self):
        pid = "RP1-V01-v0.2-seed7"
        def partial(r):
            if int(r["sequence"]) <= 20: r.update(human_rating=str(1 + int(r["sequence"]) % 5), validation_status="rated", blind_confirmed="true", rating_date="2026-11-01")
        self.fill(pid, partial); r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid)), check=True); self.assertIn("ingested 20", r.stdout)
        rat = read_csv(self.root / "validation" / "ratings.csv")[1]; self.assertEqual(len(rat), 20); self.assertEqual(rat[0]["rating_id"], "RT000001"); self.assertTrue(all(x["rating_pass"] == "1" for x in rat))
        self.assertEqual(sum(1 for m in read_csv(self.root / "manifests" / "manifest.csv")[1] if m["included_in_experiment"] == "true" and m["recording_type"] == "learner"), 20)
        r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid))); self.assertEqual(r.returncode, 1); self.assertIn("duplicate rating rejected", r.stdout)   # same 20 again
        r = run("rating_tool.py", self.root, "freeze", "--pass", "1", "--allow-fewer-learners"); self.assertEqual(r.returncode, 1); self.assertIn("without a pass-1 decision", r.stdout); self.assertFalse((self.root / "validation" / "ratings_freeze_v0.2_pass1.json").exists())
        r = run("rating_tool.py", self.root, "freeze", "--pass", "1"); self.assertIn("design minimum", r.stdout)
        def rest(r):
            if int(r["sequence"]) > 20:
                if int(r["sequence"]) == 30: r.update(human_rating="", validation_status="unratable", unratable_reason="background speech (fixture)", blind_confirmed="true", rating_date="2026-11-02")
                else: r.update(human_rating="3", validation_status="rated", blind_confirmed="true", rating_date="2026-11-02")
        self.fill(pid, rest); r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid))); self.assertEqual(r.returncode, 1); self.assertIn("duplicate", r.stdout)   # first 20 still filled -> duplicates
        self.fill(pid, lambda r: r.update(human_rating="", validation_status="", unratable_reason="", blind_confirmed="", rating_date="") if int(r["sequence"]) <= 20 else None)
        r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid)), check=True); self.assertIn("ingested 10", r.stdout)
        exc = read_csv(self.root / "manifests" / "exclusions.csv")[1]; self.assertEqual(len(exc), 1); self.assertEqual(exc[0]["reason_code"], "UNRATABLE"); self.assertEqual(exc[0]["decided_by"], "V01")
        self.assertEqual(run("rating_tool.py", self.root, "validate").returncode, 0)
        r = run("rating_tool.py", self.root, "freeze", "--pass", "1", "--allow-fewer-learners", check=True); fz = json.loads((self.root / "validation" / "ratings_freeze_v0.2_pass1.json").read_text())
        self.assertEqual(fz["n_rows"], 30); self.assertEqual(fz["n_rated"], 29); self.assertEqual(fz["n_unratable"], 1); self.assertEqual(fz["ratings_sha256"], __import__("common").sha256_file(self.root / "validation" / "ratings.csv"))
        self.assertEqual((self.root / "validation" / "ratings.csv").stat().st_mode & 0o222, 0); self.assertIn("PP001", fz["configs"])
        r = run("rating_tool.py", self.root, "ingest", str(self.pkg(pid))); self.assertEqual(r.returncode, 1)   # frozen: nothing more can be appended (all pending anyway)
        chk = run("check_dataset.py", self.root, "--no-report"); self.assertIn("ratings pass 1:frozen", chk.stdout); self.assertNotIn("| ERROR |", chk.stdout.split("| Status | Check |")[1] if "| Status | Check |" in chk.stdout else "")
    def test_04_pass2_sampling_deterministic_and_hidden(self):
        r = run("rating_tool.py", self.root, "package", "--pass", "2", "--validator", "V01", "--seed", "99", check=True); pid = "RP2-V01-v0.2-seed99"; info = json.loads((self.pkg(pid) / "package.json").read_text())
        self.assertEqual(info["n_recordings"], 3); self.assertEqual(len(info["sampled_recording_ids"]), 3); self.assertAlmostEqual(info["fraction"], 0.10)
        oh, rows = read_csv(self.pkg(pid) / "rating_order.csv"); self.assertTrue(all(r["human_rating"] == "" for r in rows)); self.assertFalse(any("pass1" in h or "previous" in h for h in oh))
        rat1 = {x["recording_id"] for x in read_csv(self.root / "validation" / "ratings.csv")[1] if x["validation_status"] == "rated"}; self.assertTrue(set(info["sampled_recording_ids"]) <= rat1)
        pool = sorted(rat1); exp = sorted(random.Random(99).sample(pool, 3)); self.assertEqual(info["sampled_recording_ids"], exp)
        self.fill(pid, lambda r: r.update(human_rating="5", validation_status="rated", blind_confirmed="true", rating_date="2026-11-10")); run("rating_tool.py", self.root, "ingest", str(self.pkg(pid)), check=True)
        r2 = read_csv(self.root / "validation" / "ratings_pass2.csv")[1]; self.assertEqual(len(r2), 3); self.assertTrue(all(x["rating_pass"] == "2" for x in r2))
        self.assertEqual(len(read_csv(self.root / "validation" / "ratings.csv")[1]), 30)   # pass 1 untouched
        rh, rows2 = read_csv(self.root / "validation" / "ratings_pass2.csv"); rows2.append(dict(rows2[0], rating_id="RT000099", recording_id="S002_W015")); write_csv(self.root / "validation" / "ratings_pass2.csv", rh, rows2)
        r = run("rating_tool.py", self.root, "validate", "--pass", "2"); self.assertIn("not in any pass-2 sample" if "S002_W015" not in info["sampled_recording_ids"] else "duplicate", r.stdout)
        write_csv(self.root / "validation" / "ratings_pass2.csv", rh, rows2[:-1]); self.assertEqual(run("rating_tool.py", self.root, "validate", "--pass", "2").returncode, 0)
        self.assertEqual(run("rating_tool.py", self.root, "freeze", "--pass", "2").returncode, 0)
    def test_05_loader_contract(self):
        sys.path.insert(0, str(self.root)); import importlib; di = importlib.import_module("pipeline.dataset_interface")
        d = di.load_experiment_inputs(self.root, require_frozen=True, require_frozen_pp=False)
        self.assertEqual(len(d["targets"]), 112); self.assertEqual(len(d["references"]), 128); self.assertEqual(len(d["learner_included"]), 29); self.assertEqual(len(d["learner_excluded"]), 1)
        self.assertEqual(len(d["ratings_pass1"]), 30); self.assertEqual(len(d["ratings_pass2"]), 3); self.assertEqual(d["ratings_freeze"]["n_rows"], 30); self.assertEqual(len(d["reference_relationships"]["W025"]["reference_recording_ids"]), 2)
        with self.assertRaises(di.DatasetNotFrozen): di.load_experiment_inputs(self.root, require_frozen=True, require_frozen_pp=True)   # PP001 is still a candidate
        p = self.root / "validation" / "ratings_freeze_v0.2_pass1.json"; bak = p.read_text(); p.unlink()
        with self.assertRaises(di.DatasetNotFrozen): di.load_experiment_inputs(self.root, require_frozen=True, require_frozen_pp=False)
        p.write_text(bak)

if __name__ == "__main__": unittest.main(verbosity=2)
