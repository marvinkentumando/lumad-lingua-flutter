#!/usr/bin/env python3
"""Read-only technical probe of every raw recording -> metadata/audio_quality.csv.
Never modifies audio. Uses ffprobe when available, else mutagen (pure Python), else a minimal
WAV header parser. Unreadable files are recorded with readable=false, never skipped or deleted.
"""
import argparse, datetime as dt, json, shutil, subprocess, struct, sys
from pathlib import Path
from common import ROOT, read_csv, write_csv, sha256_file, rel, RE_REF, RE_LEARNER

HEADER = ["recording_id","file_path","container","codec","sample_rate_hz","channels","bit_depth","duration_sec",
          "bitrate_kbps","file_size_bytes","readable","probe_tool","probe_tool_version","probe_date","sha256","probe_notes"]

def probe_ffprobe(path):
    exe = shutil.which("ffprobe")
    if not exe: return None
    ver = subprocess.run([exe, "-version"], capture_output=True, text=True).stdout.split("\n")[0].split(" ")[2] if True else ""
    r = subprocess.run([exe, "-v", "error", "-print_format", "json", "-show_format", "-show_streams", str(path)], capture_output=True, text=True)
    if r.returncode != 0: return {"readable": False, "probe_tool": "ffprobe", "probe_tool_version": ver, "probe_notes": r.stderr.strip()[:200]}
    d = json.loads(r.stdout); a = next((s for s in d.get("streams", []) if s.get("codec_type") == "audio"), {})
    f = d.get("format", {})
    return {"readable": bool(a), "container": f.get("format_name", ""), "codec": a.get("codec_name", ""),
            "sample_rate_hz": a.get("sample_rate", ""), "channels": a.get("channels", ""),
            "bit_depth": a.get("bits_per_raw_sample") or a.get("bits_per_sample") or "",
            "duration_sec": f.get("duration", ""), "bitrate_kbps": round(int(f["bit_rate"]) / 1000, 1) if f.get("bit_rate") else "",
            "probe_tool": "ffprobe", "probe_tool_version": ver, "probe_notes": "" if a else "no audio stream"}

def probe_mutagen(path):
    try:
        import mutagen
    except ImportError:
        return None
    try:
        m = mutagen.File(str(path))
    except Exception as e:
        return {"readable": False, "probe_tool": "mutagen", "probe_tool_version": mutagen.version_string, "probe_notes": f"{type(e).__name__}: {e}"[:200]}
    if m is None or m.info is None:
        return {"readable": False, "probe_tool": "mutagen", "probe_tool_version": mutagen.version_string, "probe_notes": "format not recognised"}
    info = m.info; codec = getattr(info, "codec", "") or getattr(info, "codec_description", "") or type(info).__name__
    if type(m).__name__.lower() == "wave": codec = "pcm"
    return {"readable": True, "container": type(m).__name__.lower(), "codec": str(codec),
            "sample_rate_hz": getattr(info, "sample_rate", ""), "channels": getattr(info, "channels", ""),
            "bit_depth": getattr(info, "bits_per_sample", "") or "", "duration_sec": round(getattr(info, "length", 0.0), 3),
            "bitrate_kbps": round(getattr(info, "bitrate", 0) / 1000, 1) if getattr(info, "bitrate", 0) else "",
            "probe_tool": "mutagen", "probe_tool_version": mutagen.version_string, "probe_notes": ""}

def probe_wav(path):
    try:
        with open(path, "rb") as f:
            riff, _, wave = struct.unpack("<4sI4s", f.read(12))
            if riff != b"RIFF" or wave != b"WAVE": return None
            fmt = None; data_len = None
            while True:
                h = f.read(8)
                if len(h) < 8: break
                cid, clen = struct.unpack("<4sI", h)
                if cid == b"fmt ": fmt = struct.unpack("<HHIIHH", f.read(16)); f.seek(clen - 16, 1)
                elif cid == b"data": data_len = clen; f.seek(clen, 1)
                else: f.seek(clen, 1)
        if not fmt: return {"readable": False, "probe_tool": "wav_header", "probe_notes": "no fmt chunk"}
        _, ch, sr, _, _, bits = fmt
        dur = data_len / (sr * ch * bits / 8) if data_len and sr and ch and bits else ""
        return {"readable": True, "container": "wav", "codec": "pcm", "sample_rate_hz": sr, "channels": ch, "bit_depth": bits,
                "duration_sec": round(dur, 3) if dur else "", "bitrate_kbps": round(sr * ch * bits / 1000, 1), "probe_tool": "wav_header", "probe_tool_version": "1", "probe_notes": ""}
    except Exception as e:
        return {"readable": False, "probe_tool": "wav_header", "probe_notes": str(e)[:200]}

def probe(path):
    for fn in (probe_ffprobe, probe_mutagen, probe_wav):
        r = fn(path)
        if r is not None: return r
    return {"readable": False, "probe_tool": "none", "probe_tool_version": "", "probe_notes": "no probe backend available (install ffprobe or mutagen)"}

def recording_id_for(path):
    stem = path.stem
    return stem if (RE_REF.match(stem) or RE_LEARNER.match(stem)) else ""

def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("--root", default=str(ROOT)); a = p.parse_args()
    root = Path(a.root); files = sorted(x for x in (root / "raw").rglob("*") if x.is_file() and x.name != ".gitkeep" and x.suffix.lower() != ".md")
    today = dt.date.today().isoformat(); rows = []
    for fpath in files:
        r = {k: "" for k in HEADER}; r.update({"recording_id": recording_id_for(fpath), "file_path": rel(fpath, root),
             "file_size_bytes": fpath.stat().st_size, "sha256": sha256_file(fpath), "probe_date": today})
        r.update({k: v for k, v in probe(fpath).items() if k in HEADER}); r["readable"] = str(bool(r["readable"])).lower()
        if not r["recording_id"]: r["probe_notes"] = (r["probe_notes"] + "; filename does not follow id scheme").strip("; ")
        rows.append(r)
    write_csv(root / "metadata" / "audio_quality.csv", HEADER, rows)
    tools = sorted({r["probe_tool"] for r in rows}) or ["(no files)"]
    print(f"probed {len(rows)} raw files with {', '.join(tools)} -> metadata/audio_quality.csv; unreadable: {sum(1 for r in rows if r['readable']=='false')}")

if __name__ == "__main__": main()
