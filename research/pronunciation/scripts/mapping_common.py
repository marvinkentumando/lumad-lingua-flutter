"""Shared text-normalisation and evidence helpers for vocabulary mapping. Normalisation is used ONLY for candidate
discovery; authoritative text is always copied verbatim from the source record."""
import re, unicodedata

AUTHORITATIVE = {"DICTIONARY_HEADWORD_EXACT", "DICTIONARY_HEADWORD_ALTFORM", "DICTIONARY_EXAMPLE_EXACT", "DICTIONARY_FINDER_EXACT",
                 "EXACT_TERM_UNIQUE", "EXACT_EXAMPLE_SENTENCE_UNIQUE", "EXACT_LESSON_ITEM_UNIQUE", "HUMAN_CONFIRMED"}
CANDIDATE = {"MULTIPLE_TAKE_CANDIDATE", "DICTIONARY_ORTHOGRAPHIC_VARIANT", "DICTIONARY_ROOT_CANDIDATE", "VOICE_SUBMISSION_TRANSCRIPT_CANDIDATE",
             "NORMALIZED_TEXT_CANDIDATE", "SPELLING_VARIANT_CANDIDATE", "MULTIPLE_CANDIDATES", "PARTIAL_TOKEN_CANDIDATE", "NO_PROJECT_MATCH", "EXCLUDED_BY_REVIEW"}
CATEGORIES = AUTHORITATIVE | CANDIDATE
DECISIONS = {"CONFIRM_TEXT_NEW_ITEM", "CONFIRM_CANDIDATE", "SAME_AS", "SPLIT", "EXCLUDE", "DEFER"}

def norm(s):
    """NFKC, casefold, trim, collapse whitespace. Letters are never altered."""
    s = unicodedata.normalize("NFKC", s or "").casefold().strip(); return re.sub(r"\s+", " ", s)

def sent_norm(s):
    """norm + strip a leading list number ('1. ') and trailing sentence punctuation. For sentence comparison only."""
    s = norm(s); s = re.sub(r"^\d+[\.\)]\s*", "", s); return re.sub(r'[\.\!\?,;:"“”]+$', "", s).strip()

def punct_norm(s):
    """norm + punctuation/hyphen -> space (candidate discovery only)."""
    return re.sub(r"\s+", " ", re.sub(r"[\-_.,;:!?'\"“”‘’()]+", " ", norm(s))).strip()

def strip_take_suffix(stem):
    m = re.match(r"^(.*?)\s*\((\d+)\)\s*$", stem); return (m.group(1).strip(), m.group(2)) if m else (stem.strip(), "")
