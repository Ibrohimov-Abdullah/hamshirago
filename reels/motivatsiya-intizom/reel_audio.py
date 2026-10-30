"""Original, royalty-free music bed + sound effects synthesised with numpy."""
import wave

import numpy as np

SR = 48000
BPM = 100
BEAT = 60 / BPM
BAR = BEAT * 4

# A minor: Am - F - C - G (one chord per bar)
CHORDS = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def env_ad(n, a, d):
    t = np.arange(n) / SR
    e = np.minimum(1, t / max(a, 1e-4)) * np.exp(-np.maximum(0, t - a) / d)
    return e


def place(buf, sig, t0, gain=1.0):
    i = int(t0 * SR)
    if i >= len(buf) or i + len(sig) <= 0:
        return
    j = min(len(buf), i + len(sig))
    s = max(0, -i)
    buf[max(0, i):j] += sig[s:s + j - max(0, i)] * gain


def lowpass(x, cutoff):
    """One-pole low-pass; `cutoff` may be a scalar or per-sample array (Hz)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, np.float64), x.shape)
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def pad_voice(freq, n, rng):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for det in (-0.18, 0.0, 0.21):
        f = freq * 2 ** (det / 12)
        ph = rng.uniform(0, 6.28)
        for h, amp in ((1, 1.0), (2, 0.35), (3, 0.16), (4, 0.07)):
            out += amp * np.sin(2 * np.pi * f * h * t + ph * h)
    return out / 5


def kick(gain=1.0):
    n = int(0.42 * SR)
    t = np.arange(n) / SR
    f = 46 + 110 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) * np.exp(-t * 7.5)
    s[:int(0.004 * SR)] *= np.linspace(0, 1, int(0.004 * SR))
    return s * gain


def clap(rng):
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    nz = rng.standard_normal(n)
    nz = nz - lowpass(nz, 900)          # high-pass-ish
    e = np.exp(-t * 22) + 0.6 * np.exp(-((t - 0.012) % 0.011) * 300) * (t < 0.035)
    return nz * e * 0.5


def hat(rng):
    n = int(0.06 * SR)
    nz = rng.standard_normal(n)
    nz = nz - lowpass(nz, 6000)
    return nz * np.exp(-np.arange(n) / SR * 70) * 0.35


def whoosh(rng, dur=0.7):
    n = int(dur * SR)
    t = np.linspace(0, 1, n)
    nz = rng.standard_normal(n)
    cut = 300 + 6500 * np.sin(np.pi * t) ** 2
    s = lowpass(nz, cut)
    s -= lowpass(s, 180)
    return s * np.sin(np.pi * t) ** 1.5 * 0.9


def impact(rng):
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    f = 38 + 70 * np.exp(-t * 9)
    boom = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 2.6)
    nz = lowpass(rng.standard_normal(n), 1800) * np.exp(-t * 9) * 0.6
    return boom + nz


def riser(rng, dur):
    n = int(dur * SR)
    t = np.linspace(0, 1, n)
    nz = lowpass(rng.standard_normal(n), 400 + 7000 * t ** 2)
    return nz * t ** 2.2 * 0.7


def pop(freq=880):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    f = freq * (1 + 0.5 * np.minimum(1, t / 0.03))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 45) * 0.55


def ding():
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    s = sum(a * np.sin(2 * np.pi * f * t) for f, a in ((1318.5, 1), (1975.5, 0.5), (2637, 0.25)))
    return s * np.exp(-t * 5) * 0.35


def build(total, seg_starts, pops=(), dings=(), seed=3):
    """Return a stereo float array (n, 2) for the whole reel."""
    rng = np.random.default_rng(seed)
    n = int(total * SR) + SR
    music = np.zeros(n)
    drums = np.zeros(n)
    fx = np.zeros(n)
    s1 = seg_starts[1] if len(seg_starts) > 1 else 4
    s2 = seg_starts[2] if len(seg_starts) > 2 else 12
    s3 = seg_starts[3] if len(seg_starts) > 3 else 22
    s4 = seg_starts[4] if len(seg_starts) > 4 else 31

    # --- pad: chord per bar, crossfaded
    nbars = int(total / BAR) + 2
    bn = int(BAR * SR)
    fade = int(0.35 * SR)
    for b in range(nbars):
        ch = CHORDS[b % 4]
        seg = np.zeros(bn + fade)
        for m in ch:
            seg += pad_voice(hz(m), bn + fade, rng)
        seg += 0.6 * pad_voice(hz(ch[0] - 12), bn + fade, rng)
        e = np.ones(bn + fade)
        e[:fade] = np.linspace(0, 1, fade)
        e[-fade:] = np.linspace(1, 0, fade)
        place(music, seg * e * 0.22, b * BAR)
    # hook is darker: low-pass the first section, open the filter afterwards
    cut = np.interp(np.arange(n) / SR, [0, s1 - 0.3, s1 + 0.1, total],
                    [700, 1100, 5200, 6000])
    music = lowpass(music, cut)

    # --- bass + arp
    for b in range(nbars):
        ch = CHORDS[b % 4]
        t0 = b * BAR
        if t0 >= s1 - 0.01:
            for off in (0, 1.5, 2.5):
                bl = int(BEAT * 1.2 * SR)
                tt = np.arange(bl) / SR
                f = hz(ch[0] - 24)
                s = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt))
                place(music, s * env_ad(bl, 0.005, 0.32) * 0.32, t0 + off * BEAT)
        if t0 >= s2 - 0.01:
            notes = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 24]
            for k in range(8):
                f = hz(notes[k % 4])
                ln = int(0.32 * SR)
                tt = np.arange(ln) / SR
                tri = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * tt))
                place(music, tri * env_ad(ln, 0.004, 0.11) * 0.075, t0 + k * BEAT / 2)

    # --- drums
    nbeats = int(total / BEAT) + 1
    for k in range(nbeats):
        tb = k * BEAT
        if tb < s1 - 0.01 or tb > total - 0.8:
            continue
        if k % 4 in (0, 2) or (tb >= s3 and k % 4 == 3 and k % 8 == 7):
            place(drums, kick(), tb, 0.85)
        if tb >= s2 - 0.01 and k % 4 in (1, 3):
            place(drums, clap(rng), tb, 0.55)
        if tb >= s3 - 0.01:
            place(drums, hat(rng), tb + BEAT / 2, 0.5)
            place(drums, hat(rng), tb, 0.25)
    # heartbeat in the hook
    for tb in np.arange(0.55, s1 - 0.2, 0.86):
        place(drums, kick(0.55), tb)
        place(drums, kick(0.35), tb + 0.2)

    # --- transitions + accents
    place(fx, impact(rng), 0.0, 0.75)
    for s in seg_starts[1:]:
        place(fx, whoosh(rng), s - 0.45, 0.45)
    place(fx, riser(rng, 1.4), s1 - 1.4, 0.35)
    place(fx, impact(rng), s4, 0.4)
    for tp in pops:
        place(fx, pop(), tp, 0.35)
    for td in dings:
        place(fx, ding(), td, 0.6)

    mix = music * 0.9 + drums * 0.55 + fx * 0.7
    # master fade out
    fo = int(1.4 * SR)
    end = int(total * SR)
    mix[end - fo:end] *= np.linspace(1, 0, fo)
    mix[end:] = 0
    mix = mix[:end]
    peak = np.max(np.abs(mix)) or 1
    mix = mix / peak * 0.7
    # gentle stereo width: delay the pad slightly on the right
    left = mix
    right = np.concatenate([np.zeros(240), mix[:-240]]) * 0.5 + mix * 0.5
    return np.stack([left, right], axis=1)


def write_wav(path, stereo):
    data = (np.clip(stereo, -1, 1) * 32000).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
