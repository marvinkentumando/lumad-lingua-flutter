"""Shared helpers for the LUMAD LINGUA pronunciation dataset tooling. Stdlib only."""
import csv, hashlib, os, re, sys
from pathlib import Path

ROOT = Path(os.environ.get("LLP_DATASET_ROOT", Path(__file__).resolve().parent.parent))
RE_WORD = re.compile(r"^W\d{3}$")
RE_SPK = re.compile(r"^[RS]\d{3}$")
RE_REF = re.compile(r"^REF_\d{3}$")            # physical reference recording id (independent of vocabulary item id)
MAPPING_STATUS = {"mapped", "unresolved"}
MAPPING_EVIDENCE = {"firestore_exact_term", "project_record_exact", "validator_confirmed", "researcher_confirmed"}
RE_LEARNER = re.compile(r"^(S\d{3})_(W\d{3})(?:_T(\d{2}))?$")
REASON_CODES = {"CORRUPT","EMPTY","TOO_SHORT","CLIPPED","NOISE","WRONG_ITEM",
                "MULTIPLE_ATTEMPTS_IN_ONE_FILE","DUPLICATE","UNRATABLE","CONSENT_WITHDRAWN","OTHER"}
STAGES = {"collection","quality_probe","validation","preprocessing","experiment"}

def corpus(root=ROOT):
    """Corpus contract from config/corpus.yaml (expected reference count etc.)."""
    import yaml
    p = root / "config" / "corpus.yaml"
    return yaml.safe_load(p.read_text()) if p.exists() else {}

def version(root=ROOT):
    p = root / "VERSION"
    return p.read_text().strip() if p.exists() else ""

def read_csv(path):
    path = Path(path)
    if not path.exists():
        return [], []
    with path.open(newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        return list(r.fieldnames or []), list(r)

def write_csv(path, header, rows):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=header, extrasaction="ignore")
        w.writeheader()
        for row in rows:
            w.writerow(row)

def sha256_file(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(chunk), b""):
            h.update(b)
    return h.hexdigest()

def rel(path, root=ROOT):
    return Path(path).resolve().relative_to(root.resolve()).as_posix()

def truthy(v):
    return str(v).strip().lower() in {"true","1","yes","y"}

def die(msg, code=2):
    print(f"ERROR: {msg}", file=sys.stderr); sys.exit(code)
