"""Render the "Motivatsiyami yoki intizom?" Instagram Reel (1080x1920, 30 fps).

    python3 build_reel.py                 # with native Uzbek voice if reachable
    python3 build_reel.py --no-voice      # music + on-screen text only
    python3 build_reel.py --voice uz-UZ-MadinaNeural

The voiceover uses Microsoft's native Uzbek neural voices through `edge-tts`
(uz-UZ-SardorNeural / uz-UZ-MadinaNeural), so there is no foreign accent.
Subtitles are timed to the voice's word boundaries.
"""
import argparse
import asyncio
import json
import math
import os
import re
import subprocess
import sys

from PIL import Image

import reel_audio
from reel_gfx import (AMBER, BLACK, DIM, GREEN, H, INK, MED, RED, SEMI, TEAL, VIOLET, W,
                      WHITE, XBOLD, Background, Frame, circle, ease_back, ease_in_out,
                      ease_out, glow, gradient_circle, icon, lerp, lerp_col, prog,
                      radar_img, rrect, text_width)

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
FPS = 30

# Each token is "display" or "display|spoken" (spoken text drives the voice);
# a lone "/" marks a subtitle phrase break.
SEGMENTS = [
    dict(id="hook", dur=4.0, rate="+12%", text=(
        "Dushanba kuni hayotingizni / o‘zgartirishga qaror qilasiz, / "
        "juma kuni esa yana / eski odatlarga qaytasizmi?")),
    dict(id="relate", dur=8.0, rate="+4%", text=(
        "Muammo faqat motivatsiyada emas. / "
        "Maqsad, intizom va o‘zini boshqarish / ham katta rol o‘ynaydi.")),
    dict(id="interest", dur=10.0, rate="+4%", text=(
        "Kelajak Testi botida / 28|yigirma_sakkiz ta savol orqali / o‘z salohiyatingizni / "
        "9|to‘qqiz ta yo‘nalishda / baholashingiz mumkin.")),
    dict(id="value", dur=9.0, rate="+4%", text=(
        "Test bepul, / natijangiz va sertifikatingiz ham bepul. / "
        "Batafsil hisobot esa / atigi 1 990|bir_ming_to‘qqiz_yuz_to‘qson so‘m.")),
    dict(id="cta", dur=7.0, rate="+8%", text=(
        "Kommentda yozing: / muvaffaqiyat uchun motivatsiya muhimmi / yoki intizom? / "
        "Testni yechish uchun / @kelajak_testi_bot|Kelajak_Testi_bot — / havola profilimda!")),
]

KEYWORDS = {"motivatsiyada", "motivatsiya", "intizom", "maqsad", "28", "9", "bepul",
            "1990", "som", "kelajaktestibot", "kelajak", "testi"}


def norm(s):
    s = s.replace("_", " ")
    return re.sub(r"[^\w]", "", s.lower().replace("‘", "").replace("ʻ", "").replace("'", ""))


def tokens(seg):
    out = []
    for raw in seg["text"].split(" "):
        if raw == "/":
            out[-1]["brk"] = True
            continue
        disp, _, spoken = raw.partition("|")
        spoken = (spoken or disp).replace("_", " ")
        out.append(dict(disp=disp, spoken=spoken, brk=False))
    return out


def tts_text(seg):
    return " ".join(t["spoken"] for t in tokens(seg)).replace("‘", "ʻ")


# ---------------------------------------------------------------- voice

async def _tts(text, voice, rate, path):
    import edge_tts
    proxy = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")
    comm = edge_tts.Communicate(text, voice, rate=rate, boundary="WordBoundary", proxy=proxy)
    words = []
    with open(path, "wb") as f:
        async for ch in comm.stream():
            if ch["type"] == "audio":
                f.write(ch["data"])
            elif ch["type"] == "WordBoundary":
                words.append((ch["text"], ch["offset"] / 1e7, ch["duration"] / 1e7))
    return words


def probe_dur(path):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "csv=p=0", path], capture_output=True, text=True)
    return float(r.stdout.strip())


def make_voice(voice):
    os.makedirs(os.path.join(OUT, "vo"), exist_ok=True)
    result = []
    for seg in SEGMENTS:
        path = os.path.join(OUT, "vo", seg["id"] + ".mp3")
        words = asyncio.run(_tts(tts_text(seg), voice, seg["rate"], path))
        if not os.path.getsize(path):
            raise RuntimeError("empty TTS audio")
        result.append(dict(path=path, words=words, dur=probe_dur(path)))
    return result


def align(toks, words):
    """Map display tokens onto TTS word boundaries; None if they don't line up."""
    times, wi = [], 0
    for tk in toks:
        target = norm(tk["spoken"])
        if not target:
            times.append(None)
            continue
        acc, t0, t1 = "", None, None
        while wi < len(words) and len(acc) < len(target):
            w, off, d = words[wi]
            wi += 1
            if not norm(w):
                continue
            acc += norm(w)
            t0 = off if t0 is None else t0
            t1 = off + d
        if acc != target:
            return None
        times.append((t0, t1))
    return times


# ---------------------------------------------------------------- timeline

class Timeline:
    def __init__(self, vo):
        self.segs = []
        t = 0.0
        for i, seg in enumerate(SEGMENTS):
            toks = tokens(seg)
            if vo:
                v = vo[i]
                length = max(seg["dur"], v["dur"] + 0.55)
                rel = align(toks, v["words"])
                if rel is None:
                    rel = self._even(toks, 0.05, v["dur"] - 0.1)
            else:
                length = max(seg["dur"], 0.27 * len(toks) + 0.7)
                rel = self._even(toks, 0.15, length - 0.55)
            words, last = [], (0.0, 0.0)
            for tk, tm in zip(toks, rel):
                tm = tm or (last[1], last[1])
                last = tm
                words.append(dict(disp=tk["disp"], t0=t + tm[0], t1=t + tm[1],
                                  key=norm(tk["disp"]) in KEYWORDS, brk=tk["brk"]))
            self.segs.append(dict(id=seg["id"], start=t, end=t + length, words=words))
            t += length
        self.total = t

    @staticmethod
    def _even(toks, a, b):
        w = [len(tk["disp"]) + 3 for tk in toks]
        tot = sum(w)
        out, c = [], a
        for x in w:
            d = (b - a) * x / tot
            out.append((c, c + d * 0.9))
            c += d
        return out

    def wt(self, sid, key):
        seg = next(s for s in self.segs if s["id"] == sid)
        k = norm(key)
        for w in seg["words"]:
            if norm(w["disp"]).startswith(k):
                return w["t0"]
        raise KeyError(key)


# ---------------------------------------------------------------- subtitles

SUB_FONT, SUB_SIZE, SUB_LH = XBOLD, 66, 82
SUB_CX, SUB_CY, SUB_MAXW = 525, 1335, 800


def _fits(words, space):
    """Lay words into at most two lines of SUB_MAXW; None if they don't fit."""
    lines, w = [[]], 0.0
    for wd in words:
        ww = text_width(wd["disp"], SUB_FONT, SUB_SIZE)
        if w and w + space + ww > SUB_MAXW:
            lines.append([])
            w = 0.0
        lines[-1].append(wd)
        w += (space if w else 0) + ww
    return lines if len(lines) <= 2 else None


def build_chunks(tl):
    """Split each segment at its "/" phrase breaks, then into balanced 2-line chunks."""
    chunks = []
    space = text_width(" ", SUB_FONT, SUB_SIZE) * 1.3
    for seg in tl.segs:
        clauses, cur = [], []
        for w in seg["words"]:
            cur.append(w)
            if w["brk"]:
                clauses.append(cur)
                cur = []
        if cur:
            clauses.append(cur)
        groups = []
        for cl in clauses:
            n = 1
            while True:
                size = math.ceil(len(cl) / n)
                parts = [cl[i:i + size] for i in range(0, len(cl), size)]
                laid = [_fits(pt, space) for pt in parts]
                if all(laid):
                    groups += laid
                    break
                n += 1
        for gi, g in enumerate(groups):
            first = g[0][0]["t0"]
            nxt = groups[gi + 1][0][0]["t0"] if gi + 1 < len(groups) else seg["end"] - 0.12
            layout = []
            y0 = SUB_CY - (len(g) - 1) * SUB_LH / 2
            for li, ln in enumerate(g):
                widths = [text_width(w["disp"], SUB_FONT, SUB_SIZE) for w in ln]
                tw = sum(widths) + space * (len(ln) - 1)
                x = SUB_CX - tw / 2
                for w, ww in zip(ln, widths):
                    layout.append((w, x + ww / 2, y0 + li * SUB_LH))
                    x += ww + space
            chunks.append(dict(t0=first - 0.08, t1=nxt - 0.02, layout=layout))
    return chunks


def draw_subs(fr, t, chunks):
    for ch in chunks:
        if not (ch["t0"] <= t < ch["t1"]):
            continue
        out = prog(t, ch["t1"] - 0.12, 0.12)
        for w, x, y in ch["layout"]:
            p = prog(t, w["t0"] - 0.06, 0.16)
            if p <= 0:
                continue
            active = w["t0"] - 0.02 <= t < max(w["t1"], w["t0"] + 0.22) + 0.04
            col = AMBER if active else (TEAL if w["key"] else WHITE)
            sc = lerp(0.86, 1.0, ease_out(p))
            fr.text(w["disp"], SUB_FONT, SUB_SIZE, col, x, y + (1 - ease_out(p)) * 14,
                    alpha=min(1, p * 2) * (1 - out), scale=sc)


# ---------------------------------------------------------------- scenes

POPS, DINGS = [], []


def appear(t, t0, d=0.45):
    p = prog(t, t0, d)
    return p, ease_out(p), ease_back(p)


def card(fr, cx, cy, w, h, alpha, fill=(255, 255, 255, 20), outline=(255, 255, 255, 40),
         r=34, glow_col=None, glow_k=0.0):
    if glow_col and glow_k > 0:
        fr.blit(glow(w, h, r, glow_col, 26, 0.9), cx, cy, alpha * glow_k)
    fr.blit(rrect(w, h, r, fill, outline, 2), cx, cy, alpha)


def scene_hook(fr, t, tl, a):
    s = tl.segs[0]
    tD = s["start"]
    tJ = tl.wt("hook", "juma")
    days = ["Du", "Se", "Ch", "Pa", "Ju", "Sh", "Ya"]
    bw, gap, y = 112, 14, 455
    x0 = W / 2 - (7 * bw + 6 * gap) / 2 + bw / 2
    f = ease_in_out(prog(t, tJ - 0.8, 0.8))
    hi = 4 * f
    hcol = lerp_col(GREEN, RED, f)
    for i, dname in enumerate(days):
        p, e, b = appear(t, tD + 0.05 + i * 0.045, 0.4)
        cx = x0 + i * (bw + gap)
        fr.blit(rrect(bw, bw, 28, (255, 255, 255, 16), (255, 255, 255, 46), 2),
                cx, y + (1 - e) * 40, a * p)
    # moving highlight
    p, e, b = appear(t, tD + 0.15, 0.35)
    hx = x0 + hi * (bw + gap)
    fr.blit(glow(bw, bw, 28, hcol, 22, 0.9), hx, y, a * p * 0.9)
    fr.blit(rrect(bw, bw, 28, hcol + (255,)), hx, y, a * p, scale=lerp(0.6, 1, b))
    for i, dname in enumerate(days):
        p2, e2, _ = appear(t, tD + 0.05 + i * 0.045, 0.4)
        cx = x0 + i * (bw + gap)
        on = abs(hi - i) < 0.5
        fr.text(dname, XBOLD, 40, INK if on else DIM, cx, y + (1 - e2) * 40, a * p2,
                shadow=0 if on else 0.4)

    # big day word
    flip = tJ - 0.35
    if t < flip + 0.12:
        p, e, b = appear(t, tD, 0.4)
        out = prog(t, flip - 0.05, 0.17)
        fr.text("DUSHANBA", BLACK, 148, WHITE, W / 2, 700, a * p * (1 - out),
                scale=lerp(1.35, 1.0, ease_out(p)) * (1 - 0.15 * out))
        fr.text("“Yangi hayot boshlayman!”", SEMI, 42, GREEN, W / 2, 815,
                a * prog(t, tD + 0.35, 0.3) * (1 - out))
    if t >= flip:
        p, e, b = appear(t, flip, 0.35)
        shake = math.sin(t * 70) * 10 * (1 - prog(t, flip, 0.35))
        fr.text("JUMA", BLACK, 170, WHITE, W / 2 + shake, 700, a * p, scale=lerp(1.4, 1, e))
        fr.text("…yana eski odatlar?", SEMI, 42, RED, W / 2, 815, a * prog(t, flip + 0.25, 0.3))

    # motivation energy bar
    p, e, b = appear(t, tD + 0.3, 0.4)
    val = lerp(1.0, 0.12, ease_in_out(prog(t, tJ - 0.8, 1.1)))
    bcol = lerp_col(GREEN, AMBER, clamp01(1 - val) * 1.6) if val > 0.5 else \
        lerp_col(AMBER, RED, clamp01((0.5 - val) / 0.38))
    by = 960 + (1 - e) * 30
    fr.text("Motivatsiya", SEMI, 36, DIM, 130, by - 52, a * p, anchor="l")
    fr.text(f"{int(round(val * 100))}%", XBOLD, 44, bcol, 950, by - 52, a * p, anchor="r")
    fr.blit(rrect(820, 36, 18, (255, 255, 255, 22)), W / 2, by, a * p)
    fw = max(36, int(820 * val))
    fr.blit(rrect(fw, 36, 18, bcol + (255,)), 130, by, a * p, anchor="l")


def clamp01(x):
    return 0.0 if x < 0 else 1.0 if x > 1 else x


def scene_relate(fr, t, tl, a):
    t1 = tl.wt("relate", "muammo")
    t2 = tl.wt("relate", "emas")
    p, e, b = appear(t, t1 - 0.05)
    fr.text("Faqat motivatsiya", BLACK, 82, WHITE, W / 2 - 10, 415 + (1 - e) * 30, a * p)
    p, e, b = appear(t, t2 - 0.05)
    fr.text("yetarli emas", BLACK, 82, AMBER, W / 2 - 10, 510 + (1 - e) * 30, a * p,
            scale=lerp(0.7, 1, b))
    items = [
        ("maqsad", "target", VIOLET, "Maqsad", "Qayerga borayotganingizni bilish"),
        ("intizom", "calendar", TEAL, "Intizom", "Kayfiyat bo‘lmasa ham, har kuni"),
        ("o‘zini", "compass", AMBER, "O‘zini boshqarish", "Hissiyot va vaqtni nazorat qilish"),
    ]
    tk = tl.wt("relate", "katta")
    pulse = math.sin(prog(t, tk, 0.9) * math.pi)
    for i, (key, ic, col, title, desc) in enumerate(items):
        t0 = tl.wt("relate", key)
        p, e, b = appear(t, t0 - 0.08, 0.5)
        cy = 670 + i * 170
        cx = 530 + (1 - e) * 80
        card(fr, cx, cy, 840, 148, a * p, glow_col=col, glow_k=0.35 + 0.65 * pulse)
        fr.blit(rrect(96, 96, 26, col + (50,), col + (150,), 2), cx - 420 + 26 + 48, cy,
                a * p, scale=lerp(0.5, 1, b))
        fr.blit(icon(ic, 56, col), cx - 420 + 26 + 48, cy, a * p, scale=lerp(0.5, 1, b))
        fr.text(title, XBOLD, 50, WHITE, cx - 420 + 150, cy - 22, a * p, anchor="l")
        fr.text(desc, MED, 30, DIM, cx - 420 + 150, cy + 30, a * p, anchor="l")


RADAR = [0.82, 0.62, 0.9, 0.55, 0.76, 0.68, 0.88, 0.58, 0.8]


def scene_interest(fr, t, tl, a):
    tk = tl.wt("interest", "kelajak")
    p, e, b = appear(t, tk - 0.1)
    cy = 420 + (1 - e) * 40
    card(fr, 530, cy, 840, 150, a * p, glow_col=VIOLET, glow_k=0.5)
    fr.blit(gradient_circle(104, VIOLET, TEAL), 530 - 420 + 30 + 52, cy, a * p,
            scale=lerp(0.4, 1, b))
    fr.text("KT", BLACK, 42, WHITE, 530 - 420 + 30 + 52, cy, a * p, scale=lerp(0.4, 1, b))
    fr.text("Kelajak Testi", XBOLD, 50, WHITE, 530 - 420 + 160, cy - 22, a * p, anchor="l")
    fr.text("@kelajak_testi_bot", SEMI, 32, TEAL, 530 - 420 + 160, cy + 28, a * p, anchor="l")
    fr.blit(rrect(96, 44, 22, GREEN + (40,), GREEN + (160,), 2), 880, cy, a * p)
    fr.text("BOT", XBOLD, 24, GREEN, 880, cy, a * p, shadow=0, tracking=2)

    stats = [("28", 28, "savol", AMBER, 312), ("9", 9, "yo‘nalish", TEAL, 748)]
    for key, n, label, col, cx in stats:
        t0 = tl.wt("interest", key)
        p, e, b = appear(t, t0 - 0.08)
        cy = 640 + (1 - e) * 40
        card(fr, cx, cy, 420, 190, a * p, glow_col=col, glow_k=0.35)
        val = int(round(n * ease_out(prog(t, t0 - 0.08, 0.6))))
        fr.text(str(val), BLACK, 112, col, cx, cy - 22, a * p, scale=lerp(0.6, 1, b))
        fr.text(label, SEMI, 36, DIM, cx, cy + 58, a * p)

    tr = tl.wt("interest", "salohiyat")
    p, e, b = appear(t, tr - 0.1, 0.5)
    if p > 0:
        vals = [v * ease_out(prog(t, tr + i * 0.07, 0.8)) for i, v in enumerate(RADAR)]
        breathe = 1 + 0.03 * math.sin((t - tr) * 2.4)
        vals = [min(1, v * breathe) for v in vals]
        tb = tl.wt("interest", "baholash")
        gk = math.sin(prog(t, tb, 1.0) * math.pi)
        fr.blit(glow(300, 300, 150, TEAL, 60, 0.6), 530, 965, a * p * (0.3 + 0.7 * gk))
        fr.blit(radar_img(tuple(vals), 380, TEAL + (70,), TEAL + (255,), AMBER + (255,)),
                530, 965, a * p, scale=lerp(0.7, 1, b))


def scene_value(fr, t, tl, a):
    rows = [("test", "Test"), ("natija", "Natija"), ("sertifikat", "Sertifikat")]
    for i, (key, label) in enumerate(rows):
        t0 = tl.wt("value", key)
        p, e, b = appear(t, t0 - 0.08, 0.45)
        cy = 420 + i * 132
        cx = 530 - (1 - e) * 80
        card(fr, cx, cy, 840, 112, a * p, r=30)
        fr.blit(icon("check", 60, GREEN), cx - 420 + 28 + 30, cy, a * p, scale=lerp(0.3, 1, b))
        fr.text(label, XBOLD, 48, WHITE, cx - 420 + 112, cy, a * p, anchor="l")
        fr.blit(rrect(190, 62, 31, GREEN + (255,)), cx + 420 - 26 - 95, cy, a * p,
                scale=lerp(0.4, 1, b))
        fr.text("BEPUL", BLACK, 32, INK, cx + 420 - 26 - 95, cy, a * p, scale=lerp(0.4, 1, b),
                shadow=0, tracking=2)

    tb = tl.wt("value", "batafsil")
    tp = tl.wt("value", "1 990")
    p, e, b = appear(t, tb - 0.1, 0.5)
    cy = 925 + (1 - e) * 50
    shine = prog(t, tp + 0.15, 0.7)
    card(fr, 530, cy, 840, 250, a * p, fill=(255, 200, 61, 26), outline=AMBER + (170,),
         glow_col=AMBER, glow_k=0.45 + 0.55 * math.sin(shine * math.pi))
    fr.text("Batafsil hisobot", XBOLD, 44, WHITE, 530, cy - 72, a * p)
    p2, e2, b2 = appear(t, tp - 0.1, 0.45)
    wa, wp = text_width("atigi", SEMI, 38), text_width("1 990 so‘m", BLACK, 104)
    x0 = 530 - (wa + 22 + wp) / 2
    fr.text("atigi", SEMI, 38, DIM, x0 - 10, cy + 44, a * p2, anchor="l")
    fr.text("1 990 so‘m", BLACK, 104, AMBER, x0 + wa + 22 + wp / 2, cy + 34, a * p2,
            scale=lerp(0.6, 1, b2))


def scene_cta(fr, t, tl, a):
    s = tl.segs[4]
    t0 = s["start"]
    p, e, b = appear(t, t0 + 0.02, 0.4)
    cy = 400 + (1 - e) * 30
    fr.blit(rrect(560, 92, 46, (255, 255, 255, 26), (255, 255, 255, 60), 2), W / 2, cy, a * p)
    fr.blit(icon("chat", 50, AMBER), W / 2 - 280 + 58, cy, a * p)
    fr.text("Kommentda yozing", XBOLD, 42, WHITE, W / 2 - 280 + 102, cy, a * p, anchor="l")

    tm = tl.wt("cta", "muvaffaqiyat")
    p, e, b = appear(t, tm - 0.1, 0.4)
    fr.text("Muvaffaqiyat uchun nima muhim?", XBOLD, 48, WHITE, W / 2, 520 + (1 - e) * 24,
            a * p)

    sides = [("motivatsiya", "MOTIVATSIYA", VIOLET, "bolt", 318),
             ("intizom", "INTIZOM", TEAL, "calendar", 742)]
    for key, label, col, ic, cx in sides:
        tk = tl.wt("cta", key)
        p, e, b = appear(t, tk - 0.12, 0.45)
        cy = 700
        lit = 0.5 + 0.5 * math.sin((t - tk) * 4 + (0 if cx < 500 else math.pi))
        card(fr, cx, cy, 404, 210, a * p, fill=col + (60,), outline=col + (220,),
             glow_col=col, glow_k=0.3 + 0.5 * lit * prog(t, tk + 0.3, 0.3))
        fr.blit(icon(ic, 64, WHITE), cx, cy - 42, a * p, scale=lerp(0.5, 1, b))
        fr.text(label, BLACK, 46 if len(label) > 8 else 54, WHITE, cx, cy + 50, a * p,
                scale=lerp(0.6, 1, b))
    tv = tl.wt("cta", "intizom")
    p, e, b = appear(t, tv + 0.05, 0.35)
    fr.blit(circle(96, WHITE + (255,)), 530, 700, a * p, scale=lerp(0.2, 1, b))
    fr.text("VS", BLACK, 38, INK, 530, 700, a * p, scale=lerp(0.2, 1, b), shadow=0)

    th = tl.wt("cta", "@kelajak")
    p, e, b = appear(t, th - 0.1, 0.45)
    pulse = 1 + 0.035 * math.sin((t - th) * 6) * prog(t, th + 0.5, 0.3)
    cy = 935
    fr.blit(glow(760, 116, 58, AMBER, 30, 0.8), 530, cy, a * p * 0.8)
    fr.blit(rrect(760, 116, 58, AMBER + (255,)), 530, cy, a * p, scale=lerp(0.5, 1, b) * pulse)
    fr.text("@kelajak_testi_bot", BLACK, 54, INK, 530, cy, a * p,
            scale=lerp(0.5, 1, b) * pulse, shadow=0)
    tl_ = tl.wt("cta", "havola")
    p, e, b = appear(t, tl_ - 0.1, 0.4)
    bob = math.sin((t - tl_) * 5) * 6
    fr.blit(icon("arrow_up", 40, AMBER), 530 - 190, 1060 + bob, a * p)
    fr.text("Havola profilimda", XBOLD, 40, WHITE, 530 - 150, 1060, a * p, anchor="l")


SCENES = {"hook": scene_hook, "relate": scene_relate, "interest": scene_interest,
          "value": scene_value, "cta": scene_cta}
TINTS = {"hook": (VIOLET, RED), "relate": (VIOLET, TEAL), "interest": (TEAL, VIOLET),
         "value": (GREEN, TEAL), "cta": (AMBER, VIOLET)}


def brand(fr, t):
    a = prog(t, 0.2, 0.5) * 0.9
    fr.blit(rrect(320, 58, 29, (255, 255, 255, 20), (255, 255, 255, 50), 2), W / 2, 252, a)
    fr.blit(circle(14, AMBER + (255,)), W / 2 - 122, 252, a)
    fr.text("KELAJAK TESTI", SEMI, 24, WHITE, W / 2 + 14, 252, a, tracking=4, shadow=0)


def collect_sfx(tl):
    """Pop on every element entrance, ding when the price lands."""
    pops = [tl.wt("relate", k) for k in ("maqsad", "intizom", "o‘zini")]
    pops += [tl.wt("interest", k) for k in ("kelajak", "28", "9", "salohiyat")]
    pops += [tl.wt("value", k) for k in ("test", "natija", "sertifikat", "batafsil")]
    pops += [tl.wt("cta", k) for k in ("motivatsiya", "intizom", "@kelajak")]
    dings = [tl.wt("value", "1 990"), tl.wt("hook", "juma") - 0.35]
    return [p - 0.06 for p in pops], dings


def render_frame(t, tl, bg, chunks):
    idx = next((i for i, s in enumerate(tl.segs) if t < s["end"]), len(tl.segs) - 1)
    seg = tl.segs[idx]
    c1, c2 = TINTS[seg["id"]]
    if seg["id"] == "hook":
        f = prog(t, tl.wt("hook", "juma") - 0.8, 0.9)
        c1, c2 = lerp_col(VIOLET, (150, 40, 90), f), lerp_col(GREEN, RED, f)
    if idx > 0:
        pc1, pc2 = TINTS[tl.segs[idx - 1]["id"]]
        f = ease_in_out(prog(t, seg["start"], 0.6))
        c1, c2 = lerp_col(pc1, c1, f), lerp_col(pc2, c2, f)
    fr = Frame(bg.render(t, c1, c2))
    fade_in = 1 if idx == 0 else ease_out(prog(t, seg["start"], 0.2))
    fade_out = 1 if idx == len(tl.segs) - 1 else 1 - prog(t, seg["end"] - 0.22, 0.22)
    SCENES[seg["id"]](fr, t, tl, fade_in * fade_out)
    brand(fr, t)
    draw_subs(fr, t, chunks)
    # quick white flash on the hook's first frames
    if t < 0.12:
        fl = Image.new("RGBA", (W, H), (255, 255, 255, int(200 * (1 - t / 0.12))))
        fr.im.alpha_composite(fl)
    return fr.im.convert("RGB")


MASTER = "loudnorm=I=-14:TP=-1.5:LRA=11,alimiter=limit=0.82:level=disabled"


def mux(video, music, vo, tl, final):
    """Mix music (ducked under the voice, if any), master to -14 LUFS, mux with video."""
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", video, "-i", music]
    if vo:
        parts, labels = [], []
        for i, (v, s) in enumerate(zip(vo, tl.segs)):
            cmd += ["-i", v["path"]]
            ms = int(s["start"] * 1000)
            parts.append(f"[{i + 2}:a]aresample=48000,adelay={ms}|{ms},apad[v{i}]")
            labels.append(f"[v{i}]")
        fc = ";".join(parts) + ";" + "".join(labels) + \
            f"amix=inputs={len(vo)}:normalize=0:duration=longest,atrim=0:{tl.total:.3f}," \
            "volume=1.6,asplit=2[vo][sc];" \
            "[1:a]volume=0.55[m];[m][sc]sidechaincompress=threshold=0.02:ratio=6:attack=15:" \
            f"release=350[duck];[duck][vo]amix=inputs=2:normalize=0,{MASTER}[a]"
        cmd += ["-filter_complex", fc, "-map", "0:v", "-map", "[a]"]
    else:
        cmd += ["-map", "0:v", "-map", "1:a", "-af", MASTER]
    cmd += ["-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-shortest",
            "-movflags", "+faststart", final]
    subprocess.run(cmd, check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default="uz-UZ-SardorNeural")
    ap.add_argument("--no-voice", action="store_true")
    ap.add_argument("--preview", action="store_true", help="write still frames only")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)

    vo = None
    if not args.no_voice:
        try:
            vo = make_voice(args.voice)
            print(f"voice: {args.voice} OK")
        except Exception as ex:  # network blocked, edge-tts missing, ...
            print(f"voice unavailable ({type(ex).__name__}: {ex}); building without voiceover",
                  file=sys.stderr)
    tl = Timeline(vo)
    chunks = build_chunks(tl)
    bg = Background()
    print(f"duration {tl.total:.2f}s; segments:",
          ", ".join(f"{s['id']} {s['start']:.1f}-{s['end']:.1f}" for s in tl.segs))
    with open(os.path.join(OUT, "timeline.json"), "w") as f:
        json.dump(dict(total=tl.total, voice=args.voice if vo else None, segments=tl.segs), f,
                  ensure_ascii=False, indent=1)

    if args.preview:
        for s in tl.segs:
            for k, tt in enumerate((s["start"] + 0.6, (s["start"] + s["end"]) / 2, s["end"] - 0.3)):
                render_frame(tt, tl, bg, chunks).save(os.path.join(OUT, f"prev_{s['id']}_{k}.png"))
        return

    nframes = int(math.ceil(tl.total * FPS))
    silent = os.path.join(OUT, "_video.mp4")
    enc = subprocess.Popen(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
         "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "slow",
         "-crf", "17", "-pix_fmt", "yuv420p", "-profile:v", "high", "-movflags", "+faststart",
         silent], stdin=subprocess.PIPE)
    for i in range(nframes):
        enc.stdin.write(render_frame(i / FPS, tl, bg, chunks).tobytes())
        if i % 60 == 0:
            print(f"  frame {i}/{nframes}", flush=True)
    enc.stdin.close()
    enc.wait()

    pops, dings = collect_sfx(tl)
    music = os.path.join(OUT, "_music.wav")
    reel_audio.write_wav(music, reel_audio.build(tl.total, [s["start"] for s in tl.segs],
                                                 pops, dings))
    final = os.path.join(OUT, "reel.mp4")
    mux(silent, music, vo, tl, final)
    # version with no audio at all, for adding Instagram audio / your own voice in-app
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", silent, "-c", "copy", "-an",
                    os.path.join(OUT, "reel_no_audio.mp4")], check=True)
    os.remove(silent)
    print("wrote", final)


if __name__ == "__main__":
    main()
