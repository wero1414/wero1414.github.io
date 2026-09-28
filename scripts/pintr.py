#!/usr/bin/env python3
"""Turn a photo into a single-line plotter-style SVG portrait with PINTR.

Usage: scripts/pintr.py INPUT OUTPUT.svg [--size 1080] [--crop LEFT TOP SIDE]
       [--lines 6000] [--contrast 50] [--definition 50] [--stroke 1.5] [--seed 1]
       [--color '#e8e8ee'] [--invert]

--invert flips the tones first. PINTR puts lines where the photo is dark; on a
dark page with light strokes that turns hair and clothes bright and faces
empty, so for a dark background you usually want --invert.

Pillow crops and resizes the photo (transparent areas become white, as in the
PINTR web app), dumps raw RGBA, and scripts/pintr/run.ts draws the lines with
the vendored PINTR core under Node (needs Node >= 22.6 for type stripping).
"""
import argparse
import os
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--size", type=int, default=1080)
    ap.add_argument("--crop", type=float, nargs=3, metavar=("LEFT", "TOP", "SIDE"))
    ap.add_argument("--invert", action="store_true")
    for name, default in (("lines", "6000"), ("contrast", "50"), ("definition", "50"), ("stroke", "1.5"), ("seed", "1"), ("color", "#e8e8ee")):
        ap.add_argument(f"--{name}", default=default)
    a = ap.parse_args()

    im = Image.open(a.input).convert("RGBA")
    w, h = im.size
    if a.crop:
        left, top, side = int(a.crop[0] * w), int(a.crop[1] * h), int(a.crop[2] * w)
        im = im.crop((left, top, left + side, top + side))
    # Transparent areas must end up white (no lines): white when drawing as-is,
    # black before inverting.
    fill = (0, 0, 0, 255) if a.invert else (255, 255, 255, 255)
    im = Image.alpha_composite(Image.new("RGBA", im.size, fill), im)
    if a.invert:
        from PIL import ImageOps
        im = ImageOps.invert(im.convert("RGB")).convert("RGBA")
    ratio = min(1.0, a.size / max(im.size))
    im = im.resize((max(1, round(im.width * ratio)), max(1, round(im.height * ratio))), Image.LANCZOS)

    with tempfile.NamedTemporaryFile(suffix=".rgba", delete=False) as tmp:
        tmp.write(im.tobytes())
        raw = tmp.name
    try:
        cmd = ["node", "--experimental-strip-types", "--no-warnings", os.path.join(HERE, "pintr", "run.ts"),
               raw, str(im.width), str(im.height), a.output,
               "--lines", a.lines, "--contrast", a.contrast, "--definition", a.definition,
               "--stroke", a.stroke, "--seed", a.seed, "--color", a.color]
        return subprocess.call(cmd)
    finally:
        os.unlink(raw)


if __name__ == "__main__":
    sys.exit(main())
