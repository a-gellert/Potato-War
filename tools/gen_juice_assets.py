#!/usr/bin/env python3
"""Generate the lightweight juice/readability sprites used by Potato War.

The assets are intentionally soft, flat and heavily outlined to match the game's
cartoon/midcore look. They are rendered at 4x and downsampled for clean edges.

Usage:
    python tools/gen_juice_assets.py
"""

from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "main", "assets")
FX = os.path.join(ASSETS, "fx")
os.makedirs(FX, exist_ok=True)

SS = 4  # supersampling factor


def save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print("wrote", os.path.relpath(path, ROOT))


def rgba(color: tuple[int, int, int], a: int = 255) -> tuple[int, int, int, int]:
    return (color[0], color[1], color[2], a)


def smoothstep(e0: float, e1: float, x: float) -> float:
    if e0 == e1:
        return 0.0 if x < e0 else 1.0
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def radial_glow(size: int, inner: float = 0.0, outer: float = 0.5, peak: int = 255) -> Image.Image:
    """White radial glow on a transparent canvas."""
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = img.load()
    cx = cy = (size - 1) * 0.5
    max_r = size * 0.5
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / max_r
            a = int(peak * (1.0 - smoothstep(inner, outer, d)))
            if a > 0:
                px[x, y] = (255, 255, 255, a)
    return img


def ring(size: int, width: int, color=(255, 255, 255, 255), notches: int = 0, diamond: bool = False) -> Image.Image:
    """Soft outlined ring with optional notches / diamond silhouette."""
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = s * 0.14
    box = (pad, pad, s - pad, s - pad)
    w = max(2, width * SS)
    if diamond:
        cx = cy = s * 0.5
        r = (s - pad * 2) * 0.5
        pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
        d.line(pts + [pts[0]], fill=color, width=w, joint="curve")
    else:
        d.ellipse(box, outline=color, width=w)
    if notches:
        cx = cy = s * 0.5
        r = (s - pad * 2) * 0.5
        for i in range(notches):
            a = (math.tau / notches) * i - math.pi * 0.5
            x0 = cx + math.cos(a) * (r - w * 1.6)
            y0 = cy + math.sin(a) * (r - w * 1.6)
            x1 = cx + math.cos(a) * (r + w * 1.2)
            y1 = cy + math.sin(a) * (r + w * 1.2)
            d.line((x0, y0, x1, y1), fill=color, width=max(2, w // 2))
    img = img.filter(ImageFilter.GaussianBlur(SS * 0.55))
    return img.resize((size, size), Image.LANCZOS)


def soft_clouds(width: int, height: int) -> Image.Image:
    s = SS
    img = Image.new("RGBA", (width * s, height * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    random.seed(7)
    for band, (cy, alpha, scale) in enumerate([
        (height * 0.30, 70, 1.0),
        (height * 0.55, 50, 1.35),
        (height * 0.75, 35, 1.7),
    ]):
        total = int(width / 110)
        for i in range(total):
            cx = (i + 0.5) * (width / total) + random.uniform(-45, 45)
            rw = random.uniform(55, 120) * scale
            rh = random.uniform(16, 30) * scale
            a = int(alpha * random.uniform(0.7, 1.0))
            d.ellipse((cx - rw, cy - rh, cx + rw, cy + rh), fill=(255, 255, 255, a))
            for _ in range(3):
                ox = random.uniform(-rw * 0.55, rw * 0.55)
                oy = random.uniform(-rh * 0.9, rh * 0.35)
                rr = random.uniform(12, 30) * scale
                d.ellipse((cx + ox - rr, cy + oy - rr, cx + ox + rr, cy + oy + rr),
                          fill=(255, 255, 255, int(a * 0.8)))
    img = img.filter(ImageFilter.GaussianBlur(SS * 1.4))
    return img.resize((width, height), Image.LANCZOS)


def ridge_layer(width: int, height: int, color, seed: int, base: float, amp: float, detail: int = 5) -> Image.Image:
    s = SS
    img = Image.new("RGBA", (width * s, height * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    random.seed(seed)

    def noise(x: float) -> float:
        return (math.sin(x * 1.7 + seed) * 0.5 + math.sin(x * 3.3 + seed * 0.7) * 0.3 + math.sin(x * 7.1) * 0.2)

    pts = []
    for i in range(width + 1):
        x = i / width
        y = base + noise(x * detail) * amp
        pts.append((i * s, y * s))
    pts += [(width * s, height * s), (0, height * s)]
    d.polygon(pts, fill=color)
    return img.resize((width, height), Image.LANCZOS)


def add_trees(img: Image.Image, width: int, height: int, ground_y: float, color, seed: int, count: int = 12) -> None:
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(seed)
    for _ in range(count):
        x = random.uniform(width * 0.03, width * 0.97) * s
        gy = ground_y * s + random.uniform(-6, 8) * s
        trunk_h = random.uniform(10, 24) * s
        trunk_w = max(1, int(random.uniform(1.2, 2.6) * s))
        d.rectangle((x - trunk_w, gy - trunk_h, x + trunk_w, gy), fill=color)
        r = random.uniform(8, 18) * s
        d.ellipse((x - r, gy - trunk_h - r * 1.1, x + r, gy - trunk_h + r * 0.7), fill=color)


def add_fence(img: Image.Image, width: int, height: int, ground_y: float, color, seed: int) -> None:
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(seed)
    y = ground_y * s
    for i in range(0, width, 22):
        x = i * s
        d.line((x, y, x, y - 7 * s), fill=color, width=max(1, s))
    d.line((0, y - 4 * s, width * s, y - 4 * s), fill=color, width=max(1, s))


def desert_ridge(width: int, height: int) -> Image.Image:
    img = ridge_layer(width, height, rgba((126, 70, 55), 145), 11, height * 0.52, height * 0.12, 4)
    img = Image.alpha_composite(img, ridge_layer(width, height, rgba((92, 46, 44), 165), 12, height * 0.66, height * 0.10, 6))
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(13)
    for _ in range(9):
        x = random.uniform(20, width - 30) * s
        gy = height * 0.66 * s + random.uniform(-4, 4) * s
        h = random.uniform(20, 42) * s
        d.rectangle((x - 2 * s, gy - h, x + 2 * s, gy), fill=rgba((72, 36, 34), 240))
        d.rectangle((x - 9 * s, gy - h * 0.65, x - 2 * s, gy - h * 0.55), fill=rgba((72, 36, 34), 240))
        d.rectangle((x + 2 * s, gy - h * 0.8, x + 9 * s, gy - h * 0.7), fill=rgba((72, 36, 34), 240))
    return img


def arctic_ridge(width: int, height: int) -> Image.Image:
    img = ridge_layer(width, height, rgba((112, 145, 180), 145), 21, height * 0.50, height * 0.16, 5)
    img = Image.alpha_composite(img, ridge_layer(width, height, rgba((72, 102, 140), 165), 22, height * 0.66, height * 0.12, 7))
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(23)
    for _ in range(14):
        x = random.uniform(10, width - 10) * s
        gy = height * 0.66 * s + random.uniform(-2, 4) * s
        h = random.uniform(16, 38) * s
        w = random.uniform(5, 12) * s
        d.polygon([(x, gy - h), (x + w, gy), (x - w, gy)], fill=rgba((188, 220, 240), 200))
    return img


def volcano_ridge(width: int, height: int) -> Image.Image:
    img = ridge_layer(width, height, rgba((58, 31, 40), 155), 31, height * 0.52, height * 0.15, 5)
    img = Image.alpha_composite(img, ridge_layer(width, height, rgba((34, 18, 24), 175), 32, height * 0.66, height * 0.11, 8))
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(33)
    for _ in range(10):
        x = random.uniform(0, width) * s
        y = random.uniform(height * 0.58, height * 0.74) * s
        pts = [(x, y)]
        for k in range(1, 5):
            pts.append((x + k * random.uniform(4, 12) * s, y + random.uniform(-6, 6) * s))
        d.line(pts, fill=rgba((255, 122, 36), 220), width=max(1, int(1.5 * s)))
    return img


def alien_ridge(width: int, height: int) -> Image.Image:
    img = ridge_layer(width, height, rgba((71, 40, 102), 145), 41, height * 0.54, height * 0.14, 4)
    img = Image.alpha_composite(img, ridge_layer(width, height, rgba((42, 22, 64), 165), 42, height * 0.68, height * 0.10, 6))
    s = SS
    d = ImageDraw.Draw(img)
    random.seed(43)
    for _ in range(12):
        x = random.uniform(0, width) * s
        y = random.uniform(height * 0.55, height * 0.72) * s
        r = random.uniform(4, 10) * s
        d.polygon([(x, y - r), (x + r * 0.6, y), (x, y + r), (x - r * 0.6, y)], fill=rgba((63, 224, 208), 210))
    return img


def icon_canvas(size: int = 64) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def finish_icon(img: Image.Image, size: int = 64, alpha: float = 1.0) -> Image.Image:
    if alpha != 1.0:
        a = img.getchannel("A").point(lambda v: int(v * alpha))
        img.putalpha(a)
    return img.resize((size, size), Image.LANCZOS)


def outline_text(d: ImageDraw.ImageDraw, xy, text, fill, outline=(20, 16, 22, 255), width=2):
    x, y = xy
    for ox in range(-width, width + 1):
        for oy in range(-width, width + 1):
            if ox or oy:
                d.text((x + ox, y + oy), text, fill=outline)
    d.text((x, y), text, fill=fill)


def status_burn(size=64):
    img, d = icon_canvas(size)
    s = size * SS
    cx = s * 0.5
    pts = [
        (cx, s * 0.12), (s * 0.68, s * 0.40), (s * 0.60, s * 0.62),
        (s * 0.78, s * 0.55), (s * 0.72, s * 0.84),
        (s * 0.50, s * 0.94), (s * 0.25, s * 0.82),
        (s * 0.30, s * 0.58), (s * 0.18, s * 0.48),
        (s * 0.36, s * 0.36), (s * 0.44, s * 0.56), (s * 0.56, s * 0.34),
    ]
    d.polygon(pts, fill=(255, 118, 28, 255))
    d.line(pts + [pts[0]], fill=(48, 20, 12, 255), width=3 * SS)
    inner = [(cx, s * 0.32), (s * 0.60, s * 0.52), (s * 0.56, s * 0.74), (s * 0.46, s * 0.62), (s * 0.40, s * 0.76), (s * 0.32, s * 0.58)]
    d.polygon(inner, fill=(255, 226, 92, 255))
    return finish_icon(img)


def status_poison(size=64):
    img, d = icon_canvas(size)
    s = size * SS
    d.polygon([(s * 0.5, s * 0.08), (s * 0.82, s * 0.56), (s * 0.72, s * 0.86),
               (s * 0.5, s * 0.94), (s * 0.28, s * 0.86), (s * 0.18, s * 0.56)],
              fill=(96, 210, 74, 255))
    d.line([(s * 0.5, s * 0.08), (s * 0.82, s * 0.56), (s * 0.72, s * 0.86),
            (s * 0.5, s * 0.94), (s * 0.28, s * 0.86), (s * 0.18, s * 0.56), (s * 0.5, s * 0.08)],
           fill=(24, 42, 22, 255), width=3 * SS)
    d.ellipse((s * 0.34, s * 0.38, s * 0.46, s * 0.50), fill=(24, 42, 22, 255))
    d.ellipse((s * 0.54, s * 0.38, s * 0.66, s * 0.50), fill=(24, 42, 22, 255))
    d.arc((s * 0.36, s * 0.50, s * 0.64, s * 0.72), 20, 160, fill=(24, 42, 22, 255), width=3 * SS)
    return finish_icon(img)


def status_glue(size=64):
    img, d = icon_canvas(size)
    s = size * SS
    d.polygon([(s * 0.5, s * 0.10), (s * 0.80, s * 0.50), (s * 0.74, s * 0.84),
               (s * 0.50, s * 0.94), (s * 0.26, s * 0.84), (s * 0.20, s * 0.50)],
              fill=(246, 196, 54, 255))
    d.line([(s * 0.5, s * 0.10), (s * 0.80, s * 0.50), (s * 0.74, s * 0.84),
            (s * 0.50, s * 0.94), (s * 0.26, s * 0.84), (s * 0.20, s * 0.50), (s * 0.5, s * 0.10)],
           fill=(70, 42, 12, 255), width=3 * SS)
    d.ellipse((s * 0.38, s * 0.44, s * 0.46, s * 0.52), fill=(255, 245, 190, 255))
    return finish_icon(img)


def status_stun(size=64):
    img, d = icon_canvas(size)
    s = size * SS
    cx = cy = s * 0.5
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = (s * 0.42) if i % 2 == 0 else (s * 0.18)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(pts, fill=(104, 190, 255, 255))
    d.line(pts + [pts[0]], fill=(18, 34, 64, 255), width=3 * SS)
    d.ellipse((s * 0.34, s * 0.34, s * 0.44, s * 0.44), fill=(255, 255, 255, 255))
    d.ellipse((s * 0.54, s * 0.34, s * 0.64, s * 0.44), fill=(255, 255, 255, 255))
    return finish_icon(img)


def team_badge(size=64, blue=True):
    img, d = icon_canvas(size)
    s = size * SS
    fill = (76, 162, 255, 255) if blue else (255, 92, 82, 255)
    dark = (18, 34, 64, 255) if blue else (64, 16, 18, 255)
    pts = [(s * 0.5, s * 0.06), (s * 0.88, s * 0.22), (s * 0.82, s * 0.66),
           (s * 0.5, s * 0.94), (s * 0.18, s * 0.66), (s * 0.12, s * 0.22)]
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=dark, width=3 * SS)
    if blue:
        # star
        star = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = (s * 0.24) if i % 2 == 0 else (s * 0.10)
            star.append((s * 0.5 + math.cos(a) * r, s * 0.48 + math.sin(a) * r))
        d.polygon(star, fill=(255, 244, 190, 255))
    else:
        # skull
        d.ellipse((s * 0.30, s * 0.28, s * 0.70, s * 0.68), fill=(255, 236, 220, 255))
        d.rectangle((s * 0.38, s * 0.58, s * 0.62, s * 0.72), fill=(255, 236, 220, 255))
        d.ellipse((s * 0.38, s * 0.42, s * 0.46, s * 0.50), fill=dark)
        d.ellipse((s * 0.54, s * 0.42, s * 0.62, s * 0.50), fill=dark)
        for k in range(3):
            x = s * 0.42 + k * s * 0.08
            d.line((x, s * 0.60, x, s * 0.68), fill=dark, width=2 * SS)
    return finish_icon(img)


def main() -> None:
    # ---- fighters ----
    save(radial_glow(256, 0.0, 0.55, peak=150), os.path.join(FX, "unit_glow.png"))
    save(radial_glow(64, 0.0, 0.60, peak=235), os.path.join(FX, "aim_glow.png"))
    save(ring(192, 5, (255, 255, 255, 230), notches=4), os.path.join(FX, "team_ring_blue.png"))
    save(ring(192, 5, (255, 255, 255, 230), notches=4, diamond=True), os.path.join(FX, "team_ring_red.png"))
    save(radius := ring(256, 5, (255, 255, 255, 235), notches=8), os.path.join(FX, "impact_ring.png"))
    save(team_badge(64, True), os.path.join(FX, "team_blue.png"))
    save(team_badge(64, False), os.path.join(FX, "team_red.png"))
    save(status_burn(), os.path.join(FX, "status_burn.png"))
    save(status_poison(), os.path.join(FX, "status_poison.png"))
    save(status_glue(), os.path.join(FX, "status_glue.png"))
    save(status_stun(), os.path.join(FX, "status_stun.png"))

    # ---- parallax / atmosphere ----
    save(soft_clouds(1024, 256), os.path.join(ASSETS, "bg_clouds.png"))
    save(ridge_layer(1024, 256, rgba((44, 48, 62), 150), 3, 256 * 0.58, 256 * 0.13, 5),
         os.path.join(ASSETS, "bg_distant.png"))

    grass = ridge_layer(1024, 256, rgba((44, 84, 54), 145), 51, 256 * 0.54, 256 * 0.13, 5)
    grass = Image.alpha_composite(grass, ridge_layer(1024, 256, rgba((28, 56, 36), 165), 52, 256 * 0.68, 256 * 0.10, 7))
    # barn + trees + fence on the mid layer
    s = SS
    gd = ImageDraw.Draw(grass)
    barn_x, barn_y = 250 * s, 256 * 0.68 * s
    gd.rectangle((barn_x, barn_y - 34 * s, barn_x + 48 * s, barn_y), fill=rgba((22, 42, 28), 245))
    gd.polygon([(barn_x - 6 * s, barn_y - 34 * s), (barn_x + 24 * s, barn_y - 52 * s), (barn_x + 54 * s, barn_y - 34 * s)],
               fill=rgba((18, 34, 24), 245))
    add_trees(grass, 1024, 256, 256 * 0.68, rgba((20, 40, 26), 235), 53, 14)
    add_fence(grass, 1024, 256, 256 * 0.70, rgba((22, 44, 30), 220), 54)
    save(grass, os.path.join(ASSETS, "bg_islands_grass.png"))

    save(desert_ridge(1024, 256), os.path.join(ASSETS, "bg_islands_desert.png"))
    save(arctic_ridge(1024, 256), os.path.join(ASSETS, "bg_islands_arctic.png"))
    save(volcano_ridge(1024, 256), os.path.join(ASSETS, "bg_islands_volcano.png"))
    save(alien_ridge(1024, 256), os.path.join(ASSETS, "bg_islands_alien.png"))


if __name__ == "__main__":
    main()
