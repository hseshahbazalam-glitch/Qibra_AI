#!/usr/bin/env python3
"""
scripts/make_faded_tile.py — perf pass item 3 (owner 2026-09-05).

Pre-bakes the PatternBackdrop wash into the tile asset so the widget can
drop its full-screen Opacity wrapper (per-frame saveLayer: the classic
Impeller/Vulkan artifact source AND a jank suspect on the owner's device).

What it does, deterministically and with the plain stdlib only (no Pillow):
  1. Decodes the source palette/RGBA PNG (8-bit; filter types 0-4).
  2. Box-averages it down to --size (a repeating pattern unit does not
     need 768px; 256 keeps ~2x logical sizing on most phones).
  3. Multiplies the alpha channel by --alpha (default 0.05 — the exact
     value the old Opacity clamp applied per frame; per-pixel alpha of a
     constant 0.05 composites IDENTICALLY to Opacity(0.05) over any
     background, which is the whole trick).
  4. Writes an RGBA-8 PNG (no filter, zlib-9) at the output path.

Usage:
  python3 scripts/make_faded_tile.py \
      [--src assets/images/hero/pattern_tile.png] \
      [--out assets/images/hero/pattern_tile_faded.png] \
      [--alpha 0.05] [--size 256]

The committed output is reproducible: re-running this script on the
source regenerates the faded tile byte-for-byte.
"""
import argparse
import pathlib
import struct
import zlib


def read_png(path: pathlib.Path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    i, idat, w, h, bd, ct, plte, trns = 8, b"", None, None, None, None, None, None
    while i < len(data):
        ln = struct.unpack(">I", data[i:i + 4])[0]
        typ = data[i + 4:i + 8]
        body = data[i + 8:i + 8 + ln]
        if typ == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", body[:10])
        elif typ == b"PLTE":
            plte = body
        elif typ == b"tRNS":
            trns = body
        elif typ == b"IDAT":
            idat += body
        i += 12 + ln
    assert bd == 8, f"bit depth {bd} unsupported (expect 8)"
    assert ct in (2, 3, 6), f"color type {ct} unsupported (expect RGB/palette/RGBA)"
    return w, h, ct, plte, trns, zlib.decompress(idat)


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else (b if pb <= pc else c)


def unfilter(raw, w, h, bpp, ct, plte):
    """Expand filter-encoded IDAT into a per-pixel RGBA byte array."""
    stride = w * bpp
    out = bytearray(w * h * 4)
    prev = bytearray(stride)
    pos = 0
    for y in range(h):
        f = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1:
                line[x] = (line[x] + a) & 0xFF
            elif f == 2:
                line[x] = (line[x] + b) & 0xFF
            elif f == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 0xFF
            elif f == 4:
                line[x] = (line[x] + paeth(a, b, c)) & 0xFF
            elif f != 0:
                raise ValueError(f"filter {f} unsupported")
        # emit RGBA
        o = y * w * 4
        if ct == 6:
            out[o:o + w * 4] = line
        elif ct == 2:
            for x in range(w):
                out[o + x * 4: o + x * 4 + 3] = line[x * 3:x * 3 + 3]
                out[o + x * 4 + 3] = 255
        else:  # palette
            for x in range(w):
                p = line[x]
                out[o + x * 4: o + x * 4 + 3] = plte[p * 3:p * 3 + 3]
                out[o + x * 4 + 3] = 255
        prev = line
    return out


def main():
    ap = argparse.ArgumentParser()
    root = pathlib.Path(__file__).resolve().parent.parent
    ap.add_argument("--src", default=str(root / "assets/images/hero/pattern_tile.png"))
    ap.add_argument("--out", default=str(root / "assets/images/hero/pattern_tile_faded.png"))
    ap.add_argument("--alpha", type=float, default=0.05)
    ap.add_argument("--size", type=int, default=256)
    args = ap.parse_args()
    assert 0.04 <= args.alpha <= 0.06, "keep the owner's 4-6% band"

    w, h, ct, plte, trns, raw = read_png(pathlib.Path(args.src))
    bpp = {2: 3, 3: 1, 6: 4}[ct]
    rgba = unfilter(raw, w, h, bpp, ct, plte)
    if ct == 3 and trns:
        raise SystemExit("tRNS palette tiles not supported by this tool")

    # box-average downscale
    n = args.size
    if w % n or h % n:
        raise SystemExit(f"source {w}x{h} not divisible by {n}")
    bx, by = w // n, h // n
    small = bytearray(n * n * 4)
    for sy in range(n):
        for sx in range(n):
            acc = [0, 0, 0, 0]
            for yy in range(by):
                row = ((sy * by + yy) * w + sx * bx) * 4
                for xx in range(bx):
                    o = row + xx * 4
                    for ch in range(4):
                        acc[ch] += rgba[o + ch]
            cnt = bx * by
            o = (sy * n + sx) * 4
            # average, then BAKE alpha: the widget's old per-frame
            # Opacity(a) becomes pixel alpha — constant multiply over a
            # fully opaque source composites identically.
            small[o + 0] = acc[0] // cnt
            small[o + 1] = acc[1] // cnt
            small[o + 2] = acc[2] // cnt
            small[o + 3] = round((acc[3] / cnt) * args.alpha)

    baked_alpha = round(args.alpha * 255)

    def chunk(typ, body):
        c = struct.pack(">I", len(body)) + typ + body
        return c + struct.pack(">I", zlib.crc32(typ + body) & 0xFFFFFFFF)

    # --- quantized indexed encoding when the source was a palette tile ---
    # Box-averaging only creates new colors at pattern EDGES; snapping each
    # averaged color to the NEAREST original palette entry is imperceptible
    # at 5% alpha and lets the output ride the palette (index rows deflate
    # ~10x better than per-pixel RGBA). Alpha lives in tRNS (uniform).
    encoded = None
    if ct == 3 and plte and len(plte) // 3 <= 256:
        pal = [(plte[p * 3], plte[p * 3 + 1], plte[p * 3 + 2])
               for p in range(len(plte) // 3)]
        cache = {}
        idx_rows = bytearray()
        for y in range(n):
            idx_rows.append(0)  # filter: none
            base = y * n * 4
            for x in range(n):
                c = (small[base + x * 4], small[base + x * 4 + 1],
                     small[base + x * 4 + 2])
                j = cache.get(c)
                if j is None:
                    j = min(range(len(pal)),
                            key=lambda k: (pal[k][0] - c[0]) ** 2
                                        + (pal[k][1] - c[1]) ** 2
                                        + (pal[k][2] - c[2]) ** 2)
                    cache[c] = j
                idx_rows.append(j)
        encoded = (chunk(b"IHDR", struct.pack(">IIBBBBB", n, n, 8, 3, 0, 0, 0))
                   + chunk(b"PLTE", plte[:len(pal) * 3])
                   + chunk(b"tRNS", bytes([baked_alpha]) * len(pal))
                   + chunk(b"IDAT", zlib.compress(bytes(idx_rows), 9)))

    if encoded is None:  # RGBA fallback for non-palette sources
        rows = b"".join(
            b"\x00" + bytes(small[y * n * 4:(y + 1) * n * 4]) for y in range(n))
        encoded = (chunk(b"IHDR", struct.pack(">IIBBBBB", n, n, 8, 6, 0, 0, 0))
                   + chunk(b"IDAT", zlib.compress(rows, 9)))

    png = b"\x89PNG\r\n\x1a\n" + encoded + chunk(b"IEND", b"")
    enc = "palette-indexed + tRNS alpha" if encoded.find(b"tRNS") >= 0 else "RGBA"
    out = pathlib.Path(args.out)
    out.write_bytes(png)
    w2, h2, ct2, _, _, _ = read_png(out)
    assert (w2, h2) == (n, n) and ct2 in (3, 6), "self-verification failed"
    print(f"wrote {out} — {out.stat().st_size} bytes, {n}x{n}, {enc}")
    print(f"alpha baked to x{args.alpha} (old PatternBackdrop Opacity) — "
          f"widget can now paint it with zero saveLayer")


if __name__ == "__main__":
    main()
