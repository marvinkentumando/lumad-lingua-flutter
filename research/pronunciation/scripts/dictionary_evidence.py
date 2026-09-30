"""Svelmoe & Svelmoe (1990) Mansaka Dictionary as an evidence source (two OCR transcriptions, flattened by
inventory in staging/dictionary/svelmoe1990_{entries,examples,finder}.csv).

Dictionary-supported (authoritative) lookups: exact headword, exact alternate form listed in a multi-form headword
("madayaw, madyaw"), exact example sentence, exact finder form. Candidate-only lookups: the systematic 1990-orthography
correspondence u -> o (filename 'upat' vs headword 'opat'), r <-> l, and affix-stripped roots for inflected forms.
Normalisation is used only for lookup; returned text is verbatim from the transcription.
"""
import csv, itertools, re
from collections import defaultdict
from pathlib import Path
from mapping_common import norm, sent_norm, punct_norm

PREFIXES = ["yaga", "naga", "maga", "paga", "yag", "nag", "mag", "pag", "yang", "nang", "mang", "pang", "ya", "na", "ma", "ka", "ga", "pa", "i", "a"]
SUFFIXES = ["an", "on", "un", "a", "i", "ay"]
FUNCTION_WORDS = {"na", "yang", "sang", "ng", "da", "ko", "mo", "ako", "kaw", "kita", "kamo", "ta", "mayo", "ra", "pa", "di", "kanmo", "kanak"}

class Dictionary:
    def __init__(self, root):
        d = Path(root) / "staging" / "dictionary"; self.available = (d / "svelmoe1990_entries.csv").exists()
        self.entries = list(csv.DictReader(open(d / "svelmoe1990_entries.csv", encoding="utf-8"))) if self.available else []
        self.examples = list(csv.DictReader(open(d / "svelmoe1990_examples.csv", encoding="utf-8"))) if self.available else []
        self.finder = list(csv.DictReader(open(d / "svelmoe1990_finder.csv", encoding="utf-8"))) if self.available else []
        self.hw = defaultdict(list); self.alt = defaultdict(list); self.ex = defaultdict(list); self.fi = defaultdict(list)
        for e in self.entries:
            h = norm(e["headword"]); self.hw[h].append(e)
            for part in re.split(r"\s*,\s*", h):
                if part and part != h and re.match(r"^[a-z\-]+$", part): self.alt[part].append(e)
        for x in self.examples: self.ex[sent_norm(x["mansaka"])].append(x)
        for f in self.finder:
            for m in re.split(r"[;,]", f["mansaka"]):
                if m.strip(): self.fi[norm(m)].append(f)

    # ---------- helpers ----------
    @staticmethod
    def uo_variants(w):
        idx = [i for i, c in enumerate(w) if c == "u"]; out = set()
        for n in range(1, len(idx) + 1):
            for comb in itertools.combinations(idx, n):
                s = list(w)
                for i in comb: s[i] = "o"
                out.add("".join(s))
        return out
    @staticmethod
    def roots(w):
        """Candidate roots in preference order: verbal prefix stripped (longest prefix first), infix removed, suffix
        stripped, prefix+suffix. Order matters: the first dictionary hit is shown as the primary candidate."""
        out = []
        for p in sorted(PREFIXES, key=len, reverse=True):
            if w.startswith(p) and len(w) - len(p) >= 3: out.append(w[len(p):])
        m = re.match(r"^([^aeiou])(y|in|um)(.+)$", w)
        if m: out.append(m.group(1) + m.group(3))
        for s in SUFFIXES:
            if w.endswith(s) and len(w) - len(s) >= 3: out.append(w[:-len(s)])
        for p in sorted(PREFIXES, key=len, reverse=True):
            for s in SUFFIXES:
                if w.startswith(p) and w.endswith(s) and len(w) - len(p) - len(s) >= 3: out.append(w[len(p):-len(s)])
        seen = set(); return [r for r in out if not (r in seen or seen.add(r))]
    def entry_summary(self, entries):
        """Verbatim fields from a set of entry rows (both transcriptions): headword string, ids, pos, definitions, page, homonyms."""
        heads = sorted({e["headword"] for e in entries}, key=lambda h: (not re.match(r"^[A-Za-z\-, ]+$", h), h != h.lower(), h))
        defs = []
        for e in sorted(entries, key=lambda e: (e["homonym"], e["sense"], e["dict_file"])):
            d = e["definition"].strip()
            if d and d not in [x[2] for x in defs]: defs.append((e["homonym"], e["pos"], d))
        return {"headword": heads[0], "all_headword_strings": " | ".join(heads), "entry_ids": ";".join(sorted({e["entry_id"] for e in entries if e["entry_id"]})),
                "a_rows": ";".join(sorted({e["row"] for e in entries if e["dict_file"] == "A"})), "pos": "; ".join(sorted({e["pos"] for e in entries if e["pos"]})),
                "definition": " | ".join(f"{('hom.' + h + ' ') if h else ''}{(p + ' ') if p else ''}{d}" for h, p, d in defs)[:600],
                "book_page": ";".join(sorted({e["book_page"] for e in entries if e["book_page"]})), "homonym_count": len({e["homonym"] for e in entries if e["homonym"]}) or 1,
                "files": "".join(sorted({e["dict_file"] for e in entries}))}

    # ---------- lookup ----------
    def lookup(self, text):
        """Return dict(category, key, summary, rule, candidates, tokens) for a filename base text."""
        nb = norm(text); res = {"category": "", "key": "", "summary": {}, "rule": "", "candidates": [], "tokens": ""}
        if not self.available: return res
        if nb in self.hw: res.update(category="DICTIONARY_HEADWORD_EXACT", key=f"svelmoe:hw:{nb}", summary=self.entry_summary(self.hw[nb])); return res
        if nb in self.alt:
            s = self.entry_summary(self.alt[nb]); res.update(category="DICTIONARY_HEADWORD_ALTFORM", key=f"svelmoe:hw:{norm(s['headword'])}", summary=s); return res
        if nb in self.ex:
            xs = self.ex[nb]; x = sorted(xs, key=lambda q: q["dict_file"])[0]
            res.update(category="DICTIONARY_EXAMPLE_EXACT", key=f"svelmoe:ex:{nb}", summary={"headword": x["headword"], "mansaka": x["mansaka"], "english": " | ".join(sorted({q["english"] for q in xs})), "entry_ids": ";".join(sorted({q["entry_id"] for q in xs if q["entry_id"]})),
                                                                                            "book_page": ";".join(sorted({q["book_page"] for q in xs if q["book_page"]})), "files": "".join(sorted({q["dict_file"] for q in xs}))}); return res
        if nb in self.fi:
            fs = self.fi[nb]; res.update(category="DICTIONARY_FINDER_EXACT", key=f"svelmoe:finder:{nb}", summary={"headword": text.strip(), "english": " | ".join(sorted({f["english"] for f in fs})), "pdf_page": ";".join(sorted({f["pdf_page"] for f in fs})), "files": "A"}); return res
        # ---- candidates ----
        if " " not in nb:
            for v in sorted(self.uo_variants(nb)):
                if v in self.hw: res.update(category="DICTIONARY_ORTHOGRAPHIC_VARIANT", rule="u->o", candidates=[{"form": v, **self.entry_summary(self.hw[v])}]); return res
                if v in self.fi: res.update(category="DICTIONARY_ORTHOGRAPHIC_VARIANT", rule="u->o (finder)", candidates=[{"form": v, "headword": v, "definition": " | ".join(sorted({f["english"] for f in self.fi[v]}))}]); return res
            for v in {nb.replace("r", "l"), nb.replace("l", "r")} - {nb}:
                if v in self.hw: res.update(category="SPELLING_VARIANT_CANDIDATE", rule="r<->l", candidates=[{"form": v, **self.entry_summary(self.hw[v])}]); return res
            cands = []; order = []
            for r0 in self.roots(nb): order += [r0] + sorted(self.uo_variants(r0))
            for r in dict.fromkeys(order):
                if r in self.hw:
                    c = {"form": r, **self.entry_summary(self.hw[r])}
                    if r in self.fi: c["definition"] = (c["definition"] + " | finder: " + "; ".join(sorted({f["english"] for f in self.fi[r]})))[:600]
                    cands.append(c)
                elif r in self.fi: cands.append({"form": r, "headword": r, "definition": "finder: " + " | ".join(sorted({f["english"] for f in self.fi[r]}))})
            if cands: res.update(category="DICTIONARY_ROOT_CANDIDATE", rule="affix-stripped root", candidates=cands[:3]); return res
        else:
            glosses = []
            for t in punct_norm(nb).split():
                forms = [t] + sorted(self.uo_variants(t)); h = next((f for f in forms if f in self.hw), None); fi = next((f for f in forms if f in self.fi), None)
                if t in FUNCTION_WORDS and not h: glosses.append(f"{t}=(function word)"); continue
                glosses.append(f"{t}={self.entry_summary(self.hw[h])['definition'][:40]!r}" + (f" [via {h}]" if h != t else "") if h else (f"{t}~{fi}:{'; '.join(sorted({f['english'] for f in self.fi[fi]}))[:30]}" if fi else f"{t}=?"))
            res["tokens"] = " | ".join(glosses)
            if any("=?" not in g and "(function word)" not in g for g in glosses): res.update(category="PARTIAL_TOKEN_CANDIDATE", rule="token glosses")
        return res
