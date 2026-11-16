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
    HADITH_COLLECTIONS,
    HADITH_LANGS,
    hadith_coverage_matrix,
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
    # ── HR-2.1: the two-edition coverage matrix ──────────────────────────────
    # Printed from the shipped files with the loader's own join rule, so this
    # table IS the number the reader gets. Rows with NEITHER edition are shown
    # even though they are 0.6% of the corpus: a coverage claim that hides its
    # own ceiling is the thing the owner asked to be replaced.
    matrix = hadith_coverage_matrix()
    totals = matrix["totals"]
    print(
        "hadith_matrix",
        json.dumps(
            {
                "books": totals["books"],
                "editions": totals["editions"],
                "files": f'{totals["files"]}/{len(HADITH_COLLECTIONS) * len(HADITH_LANGS)}',
                "bytes": totals["bytes"],
                "mb": round(totals["bytes"] / 1024 / 1024, 2),
                "rows": totals["rows"],
                "boot_decodes": len(HADITH_COLLECTIONS) * len(HADITH_LANGS),
                "coverage": totals["coverage"],
                "rows_with_neither_edition": totals["neither"],
                "urdu_rows_off_spine": totals["off_spine"],
            },
            ensure_ascii=False,
        ),
    )
    print(
        f'{"book":<10} {"rows":>6} '
        + " ".join(f"{lang + ' non-blank':>18}" for lang in HADITH_LANGS)
        + f' {"NEITHER":>8} {"keys collide":>13} {"frac N.2":>10}'
    )
    for book in matrix["books"]:
        cov = book["coverage"]
        cells = " ".join(
            f'{cov.get(lang, {}).get("non_blank", 0):>8} '
            f'({cov.get(lang, {}).get("percent", 0.0):>5.1f}%)'
            for lang in HADITH_LANGS
        )
        print(
            f'{book["book"]:<10} {book["rows"]:>6} {cells} '
            f'{book["neither"]:>8} {book["spine_collisions"]:>13} '
            f'{book["fractional_rows"]:>10}'
        )
    print("hadith_matrix_issues", json.dumps(matrix["issues"], ensure_ascii=False))
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
    if not matrix["ok"]:
        # A hadith book whose spine cannot be keyed, whose reference keys are
        # broken, or whose edition file is gone: all three mean the reader gets
        # a silently shorter book, which is exactly what HR-2.1 was to measure.
        print("FAIL hadith coverage matrix", json.dumps(matrix["issues"]))
        return 1
    print("OK 114/6236; licenses not VERIFIED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
