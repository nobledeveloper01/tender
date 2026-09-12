#!/usr/bin/env python3
"""Draw the Tender mark: the app icon and docs/mark.png.

The same shape `Tender/Brand/Mark.swift` draws at runtime — a banknote, its
portrait window, and three pulses (short, short, long) — so the icon on the
home screen, the mark on the splash and the one above the README title are
one drawing. The colours are the palette's: `ready` on the dark `surface`,
read out of Palette.swift rather than copied, so a palette change cannot
leave the icon behind.

    make brandmark        writes the files
    make splash-check     fails if they are stale
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    print("Pillow is needed: python3 -m pip install --user Pillow", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
PALETTE = ROOT / "Tender" / "Design" / "Palette.swift"
ICON = ROOT / "Tender" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"
MARK = ROOT / "docs" / "mark.png"


def dark_palette() -> dict[str, tuple[int, int, int]]:
    src = PALETTE.read_text()
    start = src.index("static let dark = Palette(")
    body = src[start:src.index("\n    )", start)]
    out = {}
    for name, hexv in re.findall(r"(\w+): Color\(hex: 0x([0-9A-Fa-f]{6})\)", body):
        out[name] = tuple(int(hexv[i:i + 2], 16) for i in (0, 2, 4))
    return out


def draw(size: int, ground: tuple[int, int, int] | None, ink: tuple[int, int, int]) -> Image.Image:
    # Supersample for clean edges, then downscale.
    s = size * 4
    img = Image.new("RGBA", (s, s), (*ground, 255) if ground else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = h = s
    stroke = max(2, int(w * 0.045))
    note = (w * 0.08, h * 0.26, w * 0.92, h * 0.74)
    d.rounded_rectangle(note, radius=int(w * 0.07), outline=ink, width=stroke)
    r = h * 0.11
    cx, cy = w * 0.30, h * 0.50
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=ink)
    x0, y, gap = w * 0.50, h * 0.50, w * 0.09
    for i, k in enumerate((0.12, 0.12, 0.22)):
        bh = h * k
        x = x0 + i * gap
        d.rounded_rectangle((x, y - bh / 2, x + stroke, y + bh / 2), radius=stroke // 2, fill=ink)
    return img.resize((size, size), Image.LANCZOS)


def main() -> int:
    p = dark_palette()
    ink, ground = p["ready"], p["surface"]
    ICON.parent.mkdir(parents=True, exist_ok=True)
    draw(1024, ground, ink).convert("RGB").save(ICON)      # App Store icons carry no alpha
    MARK.parent.mkdir(parents=True, exist_ok=True)
    draw(256, None, ink).save(MARK)
    print(f"\033[0;32m✓\033[0m drew the mark: {ICON.relative_to(ROOT)} and {MARK.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
