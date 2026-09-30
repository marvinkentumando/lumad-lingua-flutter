"""WAV I/O for the research pipeline. Reads PCM WAV via the standard library (no external decoder), returns float64.

Decoding contract (PP 'decoding'): PCM signed 16-bit little-endian samples are mapped to float by x / 32768.0,
giving the range [-1.0, 32767/32768]. 8-bit unsigned and 24/32-bit PCM are also handled deterministically.
Lossy inputs (m4a/AAC, mp3) are NOT decoded here: they require an external decoder whose version must be pinned
when learner recordings exist (see PP001 'decoding_lossy' status).
"""
import hashlib, struct, wave
import numpy as np

def read_wav(path):
    """Return (samples float64 shape (n, channels), sample_rate, info dict). Raises on non-PCM WAV."""
    with wave.open(str(path), "rb") as w:
        ch, sw, sr, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if sw == 2: x = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
    elif sw == 1: x = (np.frombuffer(raw, dtype=np.uint8).astype(np.float64) - 128.0) / 128.0
    elif sw == 3:
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
        x = ((b[:, 0].astype(np.int32)) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16))
        x = np.where(x >= 1 << 23, x - (1 << 24), x).astype(np.float64) / float(1 << 23)
    elif sw == 4: x = np.frombuffer(raw, dtype="<i4").astype(np.float64) / float(1 << 31)
    else: raise ValueError(f"unsupported sample width {sw}")
    x = x.reshape(-1, ch)
    return x, sr, {"channels": ch, "sample_width_bytes": sw, "sample_rate": sr, "frames": n, "bit_depth": 8 * sw}

def write_wav_pcm16(path, x, sr):
    """Write mono/multichannel float samples as PCM16 LE WAV deterministically (round-half-to-even, clip to int16).
    Returns (n_clipped_samples, peak_before_clip)."""
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1: x = x[:, None]
    peak = float(np.max(np.abs(x))) if x.size else 0.0
    y = np.rint(x * 32768.0)
    n_clip = int(np.sum((y > 32767) | (y < -32768)))
    y = np.clip(y, -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(x.shape[1]); w.setsampwidth(2); w.setframerate(int(sr)); w.writeframes(y.tobytes())
    return n_clip, peak

def sha256_bytes(b): return hashlib.sha256(b).hexdigest()
def sha256_file(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for blk in iter(lambda: f.read(chunk), b""): h.update(blk)
    return h.hexdigest()
def sha256_array(a):
    a = np.ascontiguousarray(a)
    return hashlib.sha256(str(a.dtype).encode() + str(a.shape).encode() + a.tobytes()).hexdigest()
