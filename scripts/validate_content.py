#!/usr/bin/env python3
"""Validate bundled Quran counts without rewriting JSON."""

from __future__ import annotations

import json
import sys
from pathlib import Path

EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236
AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
    6, 3, 5, 4, 5, 6,
]


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "assets" / "data" / "quran" / "quran_arabic.json"
    print(f"canonical surahs={EXPECTED_SURAHS} ayahs={EXPECTED_AYAHS}")
    if not path.exists():
        print("UNKNOWN: quran_arabic.json not present; skip live parse")
        return 0
    data = json.loads(path.read_text())
    payload = data.get("data", data)
    surahs = payload.get("surahs") if isinstance(payload, dict) else None
    if not isinstance(surahs, list):
        print("UNKNOWN: unexpected JSON shape; not rewriting")
        return 0
    counts = [len(s.get("ayahs") or []) for s in surahs]
    if len(counts) != EXPECTED_SURAHS:
        print(f"FAIL surah count {len(counts)}")
        return 1
    if sum(counts) != EXPECTED_AYAHS:
        print(f"FAIL ayah count {sum(counts)}")
        return 1
    print("OK 114/6236")
    return 0


if __name__ == "__main__":
    sys.exit(main())
