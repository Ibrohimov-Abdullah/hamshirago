"""Drawing helpers shared by the reel renderer and the cover generator."""
import functools
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1080, 1920

FONT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts", "")
BLACK = FONT_DIR + "InterDisplay-Black.otf"
XBOLD = FONT_DIR + "InterDisplay-ExtraBold.otf"
BOLD = FONT_DIR + "InterDisplay-Bold.otf"
SEMI = FONT_DIR + "Inter-SemiBold.otf"
MED = FONT_DIR + "Inter-Medium.otf"

BG0 = (8, 10, 30)
BG1 = (30, 18, 78)
VIOLET = (124, 92, 255)
TEAL = (34, 211, 238)
AMBER = (255, 200, 61)
WHITE = (255, 255, 255)
DIM = (160, 168, 205)
RED = (255, 84, 104)
GREEN = (52, 211, 153)
INK = (14, 14, 32)


# ---------------------------------------------------------------- easing

def clamp(x, a=0.0, b=1.0):
    return a if x < a else b if x > b else x


def prog(t, t0, d):
    return clamp((t - t0) / d) if d > 0 else float(t >= t0)


def ease_out(x):
    x = clamp(x)
    return 1 - (1 - x) ** 3


def ease_in_out(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def ease_back(x, s=1.9):
    x = clamp(x)
    return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2


def lerp(a, b, f):
    return a + (b - a) * f


def lerp_col(c1, c2, f):
    return tuple(int(round(lerp(a, b, f))) for a, b in zip(c1, c2))


# ---------------------------------------------------------------- text

@functools.lru_cache(maxsize=None)
def font(path, size):
    return ImageFont.truetype(path, size)


def text_width(text, path, size, tracking=0):
    f = font(path, size)
    if tracking:
        return sum(f.getlength(c) for c in text) + tracking * (len(text) - 1)
    return f.getlength(text)


@functools.lru_cache(maxsize=8192)
def text_img(text, path, size, color, shadow=0.55, tracking=0):
    """RGBA image of `text`; the image centre sits on the middle of the cap height."""
    f = font(path, size)
    asc, desc = f.getmetrics()
    cap = -f.getbbox("H", anchor="ls")[1]
    tw = text_width(text, path, size, tracking)
    pad = int(size * 0.3) + 6
    w = int(math.ceil(tw)) + 2 * pad
    base = pad + asc
    h = int(2 * (base - cap / 2))
    h = max(h, base + desc + pad // 2)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    if tracking:
        x = pad
        for c in text:
            d.text((x, base), c, font=f, fill=255, anchor="ls")
            x += f.getlength(c) + tracking
    else:
        d.text((pad, base), text, font=f, fill=255, anchor="ls")
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if shadow:
        off = max(2, int(size * 0.05))
        sm = Image.new("L", (w, h), 0)
        sm.paste(mask, (0, off))
        sm = sm.filter(ImageFilter.GaussianBlur(max(2, size * 0.07)))
        sm = sm.point(lambda v: int(v * shadow))
        sl = Image.new("RGBA", (w, h), (4, 4, 18, 0))
        sl.putalpha(sm)
        out.alpha_composite(sl)
    cl = Image.new("RGBA", (w, h), tuple(color[:3]) + (0,))
    cl.putalpha(mask)
    out.alpha_composite(cl)
    if len(color) == 4 and color[3] < 255:
        out.putalpha(out.getchannel("A").point(lambda v: v * color[3] // 255))
    return out


# ---------------------------------------------------------------- shapes

SS = 3  # supersampling for anti-aliased shapes


@functools.lru_cache(maxsize=2048)
def rrect(w, h, r, fill, outline=None, ow=0):
    im = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], r * SS, fill=fill,
                        outline=outline, width=ow * SS)
    return im.resize((w, h), Image.LANCZOS)


@functools.lru_cache(maxsize=512)
def glow(w, h, r, color, blur, strength=1.0):
    pad = int(blur * 3)
    im = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), tuple(color[:3]) + (0,))
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([pad, pad, pad + w, pad + h], r, fill=int(255 * strength))
    im.putalpha(m.filter(ImageFilter.GaussianBlur(blur)))
    return im


@functools.lru_cache(maxsize=256)
def circle(d, fill, outline=None, ow=0):
    im = Image.new("RGBA", (d * SS, d * SS), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse([0, 0, d * SS - 1, d * SS - 1], fill=fill,
                               outline=outline, width=ow * SS)
    return im.resize((d, d), Image.LANCZOS)


@functools.lru_cache(maxsize=64)
def gradient_circle(d, c1, c2):
    g = np.linspace(0, 1, d)[None, :] * 0.6 + np.linspace(0, 1, d)[:, None] * 0.4
    arr = np.zeros((d, d, 4), np.uint8)
    for i in range(3):
        arr[..., i] = (c1[i] * (1 - g) + c2[i] * g).astype(np.uint8)
    arr[..., 3] = 255
    im = Image.fromarray(arr, "RGBA")
    m = circle(d, (255, 255, 255, 255)).getchannel("A")
    im.putalpha(m)
    return im


def _canvas(s):
    im = Image.new("RGBA", (s * 4, s * 4), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im), 4


def _done(im, s):
    return im.resize((s, s), Image.LANCZOS)


@functools.lru_cache(maxsize=64)
def icon(kind, s, color):
    """Small line icons drawn at 4x and downsampled."""
    im, d, k = _canvas(s)
    S = s * k
    lw = max(2, int(S * 0.085))
    c = tuple(color[:3]) + (255,)
    if kind == "target":
        for f in (0.46, 0.30, 0.14):
            r = S * f
            d.ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], outline=c, width=lw)
        r = S * 0.05
        d.ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], fill=c)
    elif kind == "calendar":
        m = S * 0.1
        d.rounded_rectangle([m, S * 0.18, S - m, S - m], S * 0.12, outline=c, width=lw)
        d.line([m, S * 0.38, S - m, S * 0.38], fill=c, width=lw)
        for x in (0.33, 0.67):
            d.line([S * x, S * 0.08, S * x, S * 0.26], fill=c, width=lw)
        d.line([(S * 0.33, S * 0.64), (S * 0.46, S * 0.77), (S * 0.69, S * 0.52)],
               fill=c, width=lw, joint="curve")
    elif kind == "compass":
        r = S * 0.44
        d.ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], outline=c, width=lw)
        cx = cy = S / 2
        d.polygon([(cx + S * 0.16, cy - S * 0.16), (cx + S * 0.06, cy + S * 0.06),
                   (cx - S * 0.16, cy + S * 0.16), (cx - S * 0.06, cy - S * 0.06)], fill=c)
    elif kind == "check":
        d.ellipse([0, 0, S - 1, S - 1], fill=c)
        d.line([(S * 0.28, S * 0.52), (S * 0.44, S * 0.67), (S * 0.73, S * 0.36)],
               fill=INK + (255,), width=int(lw * 1.2), joint="curve")
    elif kind == "chat":
        m = S * 0.08
        d.rounded_rectangle([m, m, S - m, S * 0.74], S * 0.18, outline=c, width=lw)
        d.polygon([(S * 0.28, S * 0.70), (S * 0.28, S * 0.92), (S * 0.50, S * 0.72)], fill=c)
        for x in (0.33, 0.5, 0.67):
            r = S * 0.05
            d.ellipse([S * x - r, S * 0.41 - r, S * x + r, S * 0.41 + r], fill=c)
    elif kind == "bolt":
        d.polygon([(S * 0.58, S * 0.04), (S * 0.18, S * 0.56), (S * 0.46, S * 0.56),
                   (S * 0.38, S * 0.96), (S * 0.82, S * 0.40), (S * 0.53, S * 0.40)], fill=c)
    elif kind == "arrow_up":
        d.line([(S * 0.5, S * 0.88), (S * 0.5, S * 0.16)], fill=c, width=lw)
        d.line([(S * 0.22, S * 0.42), (S * 0.5, S * 0.14), (S * 0.78, S * 0.42)],
               fill=c, width=lw, joint="curve")
    return _done(im, s)


# ---------------------------------------------------------------- frame

class Frame:
    def __init__(self, im):
        self.im = im

    def blit(self, src, cx, cy, alpha=1.0, scale=1.0, anchor="c"):
        if alpha <= 0.004 or scale <= 0.01:
            return
        if abs(scale - 1.0) > 0.002:
            src = src.resize((max(1, int(src.width * scale)), max(1, int(src.height * scale))),
                             Image.BILINEAR)
        if alpha < 0.996:
            src = src.copy()
            src.putalpha(src.getchannel("A").point(lambda v, a=alpha: int(v * a)))
        if anchor == "c":
            x, y = cx - src.width / 2, cy - src.height / 2
        elif anchor == "l":
            x, y = cx, cy - src.height / 2
        else:
            x, y = cx - src.width, cy - src.height / 2
        x, y = int(round(x)), int(round(y))
        sx, sy = max(0, -x), max(0, -y)
        ex, ey = min(src.width, W - x), min(src.height, H - y)
        if ex <= sx or ey <= sy:
            return
        if sx or sy or ex < src.width or ey < src.height:
            src = src.crop((sx, sy, ex, ey))
        self.im.alpha_composite(src, dest=(x + sx, y + sy))

    def text(self, text, path, size, color, cx, cy, alpha=1.0, scale=1.0, anchor="c",
             tracking=0, shadow=0.55):
        self.blit(text_img(text, path, size, tuple(color), shadow, tracking), cx, cy,
                  alpha, scale, anchor)


# ---------------------------------------------------------------- background

class Background:
    SW, SH = 135, 240  # glow field is computed small and upscaled

    def __init__(self, seed=7):
        y = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
        x = np.linspace(0, 1, W, dtype=np.float32)[None, :, None]
        g = np.clip(y * 0.75 + x * 0.25, 0, 1)
        c0 = np.array(BG0, np.float32)
        c1 = np.array(BG1, np.float32)
        self.base = (c0 * (1 - g) + c1 * g * 0.85)
        # vignette
        vx = (np.linspace(-1, 1, W, dtype=np.float32)[None, :]) ** 2
        vy = (np.linspace(-1, 1, H, dtype=np.float32)[:, None]) ** 2
        self.base *= (1 - 0.35 * np.clip(vx * 0.6 + vy * 0.5, 0, 1))[..., None]
        sy, sx = np.mgrid[0:self.SH, 0:self.SW].astype(np.float32)
        self.sx, self.sy = sx / self.SW, sy / self.SH
        rnd = random.Random(seed)
        self.particles = [(rnd.random(), rnd.random(), rnd.uniform(1.5, 4.2),
                           rnd.uniform(0.012, 0.035), rnd.uniform(0.12, 0.4),
                           rnd.uniform(0, 6.28)) for _ in range(46)]

    def _blob(self, cx, cy, r, color, k):
        d2 = ((self.sx - cx) * 0.5625) ** 2 + (self.sy - cy) ** 2
        f = np.exp(-d2 / (2 * r * r))[..., None] * k
        return f * np.array(color, np.float32)

    def render(self, t, c1, c2, k1=0.55, k2=0.45):
        a = self._blob(0.25 + 0.12 * math.sin(t * 0.35), 0.26 + 0.06 * math.cos(t * 0.27),
                       0.22, c1, k1)
        a += self._blob(0.78 + 0.10 * math.cos(t * 0.31), 0.70 + 0.07 * math.sin(t * 0.23),
                        0.24, c2, k2)
        small = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGB")
        big = np.asarray(small.resize((W, H), Image.BILINEAR), np.float32)
        arr = np.clip(self.base + big * 0.55, 0, 255).astype(np.uint8)
        im = Image.fromarray(arr, "RGB").convert("RGBA")
        d = ImageDraw.Draw(im)
        for px, py, r, sp, al, ph in self.particles:
            y = ((py - t * sp) % 1.0) * H
            x = px * W + 14 * math.sin(t * 0.6 + ph)
            a8 = int(255 * al * (0.6 + 0.4 * math.sin(t * 1.3 + ph)))
            d.ellipse([x - r, y - r, x + r, y + r], fill=(200, 210, 255, a8))
        return im


# ---------------------------------------------------------------- radar

def radar_img(values, size, fill, line, dot, grid_alpha=60):
    S = size * 2
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    n = len(values)
    cx = cy = S / 2
    R = S * 0.46

    def pt(i, r):
        a = -math.pi / 2 + 2 * math.pi * i / n
        return cx + r * math.cos(a), cy + r * math.sin(a)

    for ring in (0.25, 0.5, 0.75, 1.0):
        d.polygon([pt(i, R * ring) for i in range(n)], outline=(255, 255, 255, grid_alpha),
                  width=2)
    for i in range(n):
        d.line([pt(i, 0), pt(i, R)], fill=(255, 255, 255, grid_alpha // 2), width=2)
    poly = [pt(i, R * max(0.02, v)) for i, v in enumerate(values)]
    d.polygon(poly, fill=fill)
    d.line(poly + [poly[0]], fill=line, width=6, joint="curve")
    for x, y in poly:
        d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=dot)
    return im.resize((size, size), Image.LANCZOS)
