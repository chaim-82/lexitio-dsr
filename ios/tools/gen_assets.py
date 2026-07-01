#!/usr/bin/env python3
"""Generate the Assets.xcassets contents for AskLexi.

Pure-stdlib: writes brand color sets, an accent color, and a 1024x1024
placeholder app icon (pine-green field, warm-gold "L" monogram) as a PNG.

Run from the ios/ directory:  python3 tools/gen_assets.py
Re-runnable and idempotent. The final production icon is an open item
(see SHIP_CHECKLIST.md); this exists so the project builds and looks intentional.
"""
import json
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "AskLexi", "Resources", "Assets.xcassets")

# --- Brand palette (light, dark). Documented approximations of the asklexi.legal
# --- pine / gold / cream identity; the live CSS was unreachable at scaffold time
# --- (org egress policy), so verify these against the site before launch.
COLORS = {
    "BrandPrimary":         ("1F4739", "2C5D4B"),  # pine green
    "BrandAccent":          ("C9A227", "D8B441"),  # warm gold
    "BrandSurface":         ("FAF5EA", "17130E"),  # cream / warm dark
    "BrandSurfaceElevated": ("FFFDF7", "211B14"),  # card
    "BrandTextPrimary":     ("1C2620", "F2ECDF"),
    "BrandTextSecondary":   ("5A6660", "B9B0A0"),
    "BrandStroke":          ("E4DCC9", "352E24"),
    "BrandDanger":          ("A8321F", "E07A5F"),
}


def hexcomp(h):
    return {
        "red":   f"0x{h[0:2]}",
        "green": f"0x{h[2:4]}",
        "blue":  f"0x{h[4:6]}",
        "alpha": "1.000",
    }


def color_set(light, dark):
    def entry(appearances, hexval):
        d = {"idiom": "universal", "color": {"color-space": "srgb", "components": hexcomp(hexval)}}
        if appearances:
            d["appearances"] = appearances
        return d
    return {
        "colors": [
            entry(None, light),
            entry([{"appearance": "luminosity", "value": "dark"}], dark),
        ],
        "info": {"author": "xcode", "version": 1},
    }


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")


def png_chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data +
            struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


def make_icon(path, size=1024):
    """Solid pine field with a centered gold serif-ish 'L' block monogram."""
    bg = (0x1F, 0x47, 0x39)
    fg = (0xC9, 0xA2, 0x27)
    px = bytearray()
    # Monogram geometry: a vertical stem + a horizontal foot, inset from center.
    stem_x0, stem_x1 = int(size * 0.38), int(size * 0.48)
    top, bottom = int(size * 0.28), int(size * 0.72)
    foot_x1 = int(size * 0.64)
    bar_thick = bottom - int(size * 0.63)  # foot height
    foot_y0 = bottom - bar_thick
    for y in range(size):
        px.append(0)  # PNG filter type 0 for each scanline
        for x in range(size):
            in_stem = stem_x0 <= x < stem_x1 and top <= y < bottom
            in_foot = stem_x0 <= x < foot_x1 and foot_y0 <= y < bottom
            r, g, b = fg if (in_stem or in_foot) else bg
            px += bytes((r, g, b))
    raw = zlib.compress(bytes(px), 9)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)  # 8-bit RGB
    png = (b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", ihdr) +
           png_chunk(b"IDAT", raw) + png_chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def main():
    write_json(os.path.join(ASSETS, "Contents.json"),
               {"info": {"author": "xcode", "version": 1}})

    for name, (light, dark) in COLORS.items():
        write_json(os.path.join(ASSETS, f"{name}.colorset", "Contents.json"),
                   color_set(light, dark))

    icon_dir = os.path.join(ASSETS, "AppIcon.appiconset")
    make_icon(os.path.join(icon_dir, "AppIcon-1024.png"))
    write_json(os.path.join(icon_dir, "Contents.json"), {
        "images": [{"idiom": "universal", "platform": "ios",
                    "size": "1024x1024", "filename": "AppIcon-1024.png"}],
        "info": {"author": "xcode", "version": 1},
    })
    print("Assets generated at", ASSETS)


if __name__ == "__main__":
    main()
