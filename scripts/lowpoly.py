#!/usr/bin/env python3
"""Turn a photo into a low-poly grayscale portrait.

Usage: scripts/lowpoly.py INPUT OUTPUT [--size 800] [--points 900] [--seed 1]
       [--crop LEFT TOP SIDE]   fractions of the input width/height, e.g. 0.33 0.07 0.45

The photo is composited onto the site's dark background (transparent PNGs
work best), center-cropped to a square, converted to grayscale, and covered
with Delaunay triangles. Points are sampled more densely where the image has
edges, so faces keep their shape while flat areas stay coarse. Each triangle
is filled with the mean gray of the pixels it covers.

Needs Pillow, numpy and scipy.
"""
import argparse
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps
from scipy.spatial import Delaunay

BG = (14, 15, 20)  # --bg in assets/css/main.css (dark)


def load_square(path, size, crop=None):
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, BG + (255,))
    im = Image.alpha_composite(bg, im).convert("L")
    im = ImageOps.autocontrast(im, cutoff=1)
    w, h = im.size
    if crop:
        left, top, side = int(crop[0] * w), int(crop[1] * h), int(crop[2] * w)
    else:
        side = min(w, h)
        # Portraits: keep the top of the frame (head) rather than the exact center.
        top = 0 if h > w else (h - side) // 2
        left = (w - side) // 2
    im = im.crop((left, top, left + side, top + side))
    return im.resize((size, size), Image.LANCZOS)


def sample_points(gray, n, rng):
    edges = np.asarray(gray.filter(ImageFilter.FIND_EDGES), dtype=np.float64)
    edges = np.asarray(Image.fromarray(edges.astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), dtype=np.float64)
    weight = edges + edges.mean() * 0.15 + 1.0
    weight /= weight.sum()
    size = gray.size[0]
    idx = rng.choice(size * size, size=n, replace=False, p=weight.ravel())
    ys, xs = np.divmod(idx, size)
    pts = np.column_stack([xs, ys]).astype(np.float64)
    border = np.linspace(0, size - 1, 12)
    frame = [(x, 0) for x in border] + [(x, size - 1) for x in border] + [(0, y) for y in border] + [(size - 1, y) for y in border]
    return np.vstack([pts, np.array(frame, dtype=np.float64)])


def render(gray, pts, size):
    arr = np.asarray(gray, dtype=np.float64)
    tri = Delaunay(pts)
    out = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(out)
    mask_img = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask_img)
    for simplex in tri.simplices:
        poly = [tuple(pts[i]) for i in simplex]
        mask_draw.rectangle((0, 0, size, size), fill=0)
        mask_draw.polygon(poly, fill=255)
        m = np.asarray(mask_img, dtype=bool)
        if not m.any():
            continue
        shade = int(round(arr[m].mean()))
        draw.polygon(poly, fill=shade, outline=shade)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--size", type=int, default=800)
    ap.add_argument("--points", type=int, default=900)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--crop", type=float, nargs=3, metavar=("LEFT", "TOP", "SIDE"))
    a = ap.parse_args()
    rng = np.random.default_rng(a.seed)
    gray = load_square(a.input, a.size, a.crop)
    pts = sample_points(gray, a.points, rng)
    out = render(gray, pts, a.size)
    out.save(a.output, quality=88, optimize=True)
    print(f"wrote {a.output} ({a.size}x{a.size}, {len(pts)} points)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
