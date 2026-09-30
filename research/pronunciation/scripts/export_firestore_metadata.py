#!/usr/bin/env python3
"""Read-only export of Firestore collections (words, voice_submissions, lessons) via the public REST API.
Reads are permitted by the project's Firestore rules (allow read: if true). Uses the public Firebase web
client key from FIREBASE_WEB_API_KEY or parsed from the Flutter repo's lib/firebase_options.dart; never prints it.
Writes staging/firestore_export/<collection>.json with personal-name fields stripped (--keep-pii to retain).
"""
import argparse, json, os, re
from pathlib import Path
import requests
from common import ROOT, die

PII_FIELDS = {"contributorName", "contributorId", "validatorId", "validatorFeedback", "speakerName", "photoURL", "email"}

def unwrap(v):
    for k in ("stringValue","doubleValue","booleanValue","timestampValue","referenceValue","geoPointValue"):
        if k in v: return v[k]
    if "integerValue" in v: return int(v["integerValue"])
    if "nullValue" in v: return None
    if "mapValue" in v: return {k: unwrap(x) for k, x in (v["mapValue"].get("fields") or {}).items()}
    if "arrayValue" in v: return [unwrap(x) for x in (v["arrayValue"].get("values") or [])]
    return v

def api_key(a):
    k = os.environ.get("FIREBASE_WEB_API_KEY")
    if k: return k
    src = Path(a.firebase_options)
    if not src.exists(): die("no FIREBASE_WEB_API_KEY and firebase_options.dart not found")
    m = re.search(r"static const FirebaseOptions web = FirebaseOptions\(\s*apiKey: '([^']+)'", src.read_text())
    if not m: die("could not parse web apiKey from firebase_options.dart")
    return m.group(1)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", default="lumadlingua")
    p.add_argument("--collections", default="words,voice_submissions,lessons")
    p.add_argument("--firebase-options", default=str(ROOT.parent / "lumad-lingua-flutter" / "lib" / "firebase_options.dart"))
    p.add_argument("--keep-pii", action="store_true")
    a = p.parse_args(); key = api_key(a)
    base = f"https://firestore.googleapis.com/v1/projects/{a.project}/databases/(default)/documents"
    out_dir = ROOT / "staging" / "firestore_export"; out_dir.mkdir(parents=True, exist_ok=True)
    for coll in a.collections.split(","):
        docs, tok = [], None
        while True:
            params = {"key": key, "pageSize": 300, **({"pageToken": tok} if tok else {})}
            r = requests.get(f"{base}/{coll}", params=params, timeout=60)
            if not r.ok: die(f"{coll}: HTTP {r.status_code} {r.text[:200]}")
            d = r.json()
            for doc in d.get("documents", []):
                row = {"_id": doc["name"].split("/")[-1], "_updateTime": doc.get("updateTime")}
                for k, v in doc.get("fields", {}).items():
                    if a.keep_pii or k not in PII_FIELDS: row[k] = unwrap(v)
                docs.append(row)
            tok = d.get("nextPageToken")
            if not tok: break
        (out_dir / f"{coll}.json").write_text(json.dumps(docs, indent=1, ensure_ascii=False))
        with_audio = sum(1 for x in docs if isinstance(x.get("audioUrl"), str) and x["audioUrl"])
        print(f"{coll}: {len(docs)} documents exported ({with_audio} with audioUrl) -> staging/firestore_export/{coll}.json")

if __name__ == "__main__": main()
