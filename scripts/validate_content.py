#!/usr/bin/env python3
"""Validate bundled Quran/Hadith JSON without rewriting files."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))

from app.content.integrity import (  # noqa: E402
    EXPECTED_AYAHS,
    EXPECTED_SURAHS,
    quran_dir,
    scan_hadith,
    validate_arabic,
    validate_cloud_translation,
    validate_manifest,
    validate_tanzil_translation,
)


def main() -> int:
    print(f"canonical surahs={EXPECTED_SURAHS} ayahs={EXPECTED_AYAHS}")
    arabic = validate_arabic()
    print(
        "arabic",
        json.dumps(
            {k: arabic[k] for k in ("ok", "surahs", "ayahs", "bom_ayahs", "empty_text", "issues")},
            ensure_ascii=False,
        ),
    )
    en_path = quran_dir() / "translation_en.json"
    english = validate_cloud_translation(en_path)
    print("english", json.dumps({k: english[k] for k in ("ok", "surahs", "ayahs", "empty_text")}))
    for path in sorted(quran_dir().glob("translation_ur_*.json")):
        ur = validate_tanzil_translation(path)
        print(path.name, json.dumps({k: ur[k] for k in ("ok", "rows", "empty_text", "duplicate_pairs")}))
    hadith = scan_hadith()
    missing = [h["path"] for h in hadith if not h["exists"]]
    print("hadith_files", len(hadith), "missing", missing)
    print("hadith_empty_sum", sum(h["empty_text"] for h in hadith if h["exists"]))
    man = validate_manifest()
    print("manifest", json.dumps({k: man[k] for k in ("ok", "source_count", "has_verified", "issues")}))
    if not arabic["ok"]:
        print("FAIL arabic integrity")
        return 1
    if not english["ok"]:
        print("FAIL english integrity")
        return 1
    if not man["ok"]:
        print("FAIL manifest")
        return 1
    print("OK 114/6236; licenses not VERIFIED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
