#!/usr/bin/env python3
"""Generate LGTM OS's default wallpaper: a soft aurora gradient, as a PNG.
Pure standard library, so it runs inside makepkg. Usage: make-wallpaper.py OUT [W H]"""
import math, struct, sys, zlib

out = sys.argv[1]
W, H = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (1920, 1080)
# (x, y, radius, rgb) glow blobs over a deep blue base
blobs = [(0.15, 0.20, 0.55, (64, 170, 220)), (0.85, 0.25, 0.50, (150, 100, 230)),
         (0.55, 0.95, 0.60, (30, 190, 160)), (0.40, 0.45, 0.35, (90, 120, 230))]
base = (14, 20, 40)
rows = []
for j in range(H):
    y = j / H
    row = bytearray(b"\0")
    for i in range(W):
        x = i / W
        r, g, b = base
        for bx, by, rad, (cr, cg, cb) in blobs:
            d = ((x - bx) * 1.6) ** 2 + (y - by) ** 2
            w = math.exp(-d / (rad * rad * 0.35)) * 0.75
            r += (cr - r) * w; g += (cg - g) * w; b += (cb - b) * w
        n = ((i * 7 + j * 13) % 5 - 2) * 0.6           # light dither against banding
        row += bytes((min(255, max(0, int(r + n))), min(255, max(0, int(g + n))),
                      min(255, max(0, int(b + n)))))
    rows.append(bytes(row))

def chunk(t, d):
    c = struct.pack(">I", len(d)) + t + d
    return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
open(out, "wb").write(png)
