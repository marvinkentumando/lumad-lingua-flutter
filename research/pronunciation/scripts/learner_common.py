"""Shared helpers for learner collection, rating and freeze tooling (stdlib only)."""
import datetime as dt, re
from collections import defaultdict
from pathlib import Path
from common import read_csv, truthy, RE_LEARNER, sha256_file, version

RATING_HEADER = ["rating_id","recording_id","word_id","speaker_id","reference_recording_id","validator_code","rating_pass","human_rating","validation_status",
                 "unratable_reason","blind_confirmed","rating_date","rating_protocol_version","dataset_version","notes"]
EXCL_HEADER = ["exclusion_id","recording_id","speaker_id","word_id","reason_code","reason_detail","stage","recollection_attempted","recollection_recording_id","decided_by","decision_date","dataset_version"]
RE_RATING = re.compile(r"^[1-5]$"); RE_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$"); RE_RID = re.compile(r"^RT\d{6}$")
# Column names that must never appear in a validator-facing package (blindness guard).
FORBIDDEN_TERMS = ("dtw", "hmm", "cosine", "score", "similarity", "distance", "predict", "threshold", "algorithm", "excellent", "needs_improvement", "tier")

def vtag(ver): return "v" + ver.split("_v")[-1] if "_v" in ver else ver
def ratings_path(root, rating_pass): return root / "validation" / ("ratings.csv" if int(rating_pass) == 1 else f"ratings_pass{int(rating_pass)}.csv")
def freeze_path(root, rating_pass): return root / "validation" / f"ratings_freeze_{vtag(version(root))}_pass{int(rating_pass)}.json"
def iso_date_ok(s):
    if not RE_DATE.match(s or ""): return False
    try: dt.date.fromisoformat(s); return True
    except ValueError: return False

def learner_rows(manifest): return [m for m in manifest if m.get("recording_type") == "learner"]

def active_takes(manifest, exclusions):
    """For every (speaker_id, word_id) the take that is currently valid: the highest take that is readable and not excluded.
    Returns (active: {(spk, w): row}, problems: [str]). A lower take that is neither excluded nor the highest take is a problem
    (a retake exists without a documented failure of the previous take); an unreadable take without an exclusion row is reported too."""
    exc = {e["recording_id"]: e for e in exclusions}; by = defaultdict(list); active = {}; problems = []
    for m in learner_rows(manifest): by[(m["speaker_id"], m["word_id"])].append(m)
    for key, rows in by.items():
        rows.sort(key=lambda r: int(r.get("take_number") or 1)); top = rows[-1]
        for r in rows[:-1]:
            if r["recording_id"] not in exc: problems.append(f"{r['recording_id']}: superseded by take {top.get('take_number')} but has no exclusion row")
        for r in rows:
            if not truthy(r.get("readable")) and r["recording_id"] not in exc: problems.append(f"{r['recording_id']}: unreadable but not excluded")
        taken = [r for r in rows if r["recording_id"] not in exc and truthy(r.get("readable"))]
        if taken: active[key] = taken[-1]
        nums = [int(r.get("take_number") or 1) for r in rows]
        if nums[0] != 1: problems.append(f"{top['recording_id']}: no primary (unsuffixed) take exists for this item")
        for a, b in zip(nums, nums[1:]):
            if b != a + 1: problems.append(f"{key[0]}_{key[1]}: take numbers not consecutive ({nums})")
    return active, problems

def validate_ratings(root, rating_pass=1, rows=None, manifest=None, targets=None, validators=None, strict_pass2_sample=True):
    """Rule set for a ratings file (validation/ratings.csv for pass 1, ratings_pass2.csv for pass 2). Returns list of error strings."""
    root = Path(root); errs = []
    if rows is None: _, rows = read_csv(ratings_path(root, rating_pass))
    if manifest is None: _, manifest = read_csv(root / "manifests" / "manifest.csv")
    if targets is None: _, targets = read_csv(root / "metadata" / "learner_targets.csv")
    if validators is None: _, validators = read_csv(root / "metadata" / "validators.csv")
    mb = {m["recording_id"]: m for m in learner_rows(manifest)}; tb = {t["word_id"]: t for t in targets}; vcodes = {v["validator_code"] for v in validators}
    seen = set(); ids = set()
    for r in rows:
        rid = r.get("rating_id", ""); rec = r.get("recording_id", ""); tag = rid or rec
        if not RE_RID.match(rid): errs.append(f"{tag}: rating_id must be RTnnnnnn")
        if rid in ids: errs.append(f"{tag}: duplicate rating_id")
        ids.add(rid)
        if str(r.get("rating_pass", "")).strip() != str(rating_pass): errs.append(f"{tag}: rating_pass must be {rating_pass} in this file")
        m = mb.get(rec)
        if not m: errs.append(f"{tag}: recording_id {rec} is not a learner recording in the manifest"); continue
        if m["word_id"] != r.get("word_id") or m["speaker_id"] != r.get("speaker_id"): errs.append(f"{tag}: word_id/speaker_id do not match manifest ({m['word_id']}, {m['speaker_id']})")
        t = tb.get(m["word_id"])
        refs = set(t["reference_recording_ids"].split(";")) if t else set()
        if not r.get("reference_recording_id"): errs.append(f"{tag}: reference_recording_id required")
        elif r["reference_recording_id"] not in refs: errs.append(f"{tag}: reference {r['reference_recording_id']} does not belong to item {m['word_id']}")
        elif t and r["reference_recording_id"] != t.get("primary_playback_reference_id"): errs.append(f"{tag}: reference {r['reference_recording_id']} is not the item's primary playback reference {t.get('primary_playback_reference_id')}")
        if r.get("validator_code") not in vcodes: errs.append(f"{tag}: unknown validator_code '{r.get('validator_code')}'")
        st = r.get("validation_status", ""); hr = (r.get("human_rating") or "").strip()
        if st == "rated":
            if not RE_RATING.match(hr): errs.append(f"{tag}: human_rating '{hr}' is not an integer 1-5")
        elif st == "unratable":
            if hr: errs.append(f"{tag}: unratable rows must leave human_rating blank")
            if not (r.get("unratable_reason") or "").strip(): errs.append(f"{tag}: unratable requires unratable_reason")
        elif st == "pending":
            if hr: errs.append(f"{tag}: pending rows must leave human_rating blank")
        else: errs.append(f"{tag}: validation_status '{st}' not in rated/unratable/pending")
        if st != "pending" and not truthy(r.get("blind_confirmed")): errs.append(f"{tag}: blind_confirmed must be true")
        if st != "pending" and not iso_date_ok(r.get("rating_date", "")): errs.append(f"{tag}: rating_date must be YYYY-MM-DD")
        key = (rec, r.get("validator_code"), str(rating_pass))
        if key in seen: errs.append(f"{tag}: duplicate rating for {key}")
        seen.add(key)
    if int(rating_pass) == 2 and strict_pass2_sample and rows:
        sampled = set()
        for pj in sorted((root / "validation" / "rating_packages").glob("*/package.json")) if (root / "validation" / "rating_packages").exists() else []:
            import json; d = json.loads(pj.read_text())
            if int(d.get("rating_pass", 0)) == 2: sampled |= set(d.get("sampled_recording_ids", []))
        for r in rows:
            if r.get("recording_id") not in sampled: errs.append(f"{r.get('rating_id')}: pass-2 rating for {r.get('recording_id')} which is not in any pass-2 sample")
    return errs
