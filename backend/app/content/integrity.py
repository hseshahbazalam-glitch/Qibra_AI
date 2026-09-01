"""Validate bundled Quran/Hadith JSON without rewriting it.

License status is never inferred as VERIFIED. A VERIFIED row requires an
in-repo license file named in the sidecar manifest.
"""

from __future__ import annotations

import json
import unicodedata
from collections import Counter
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

ALLOWED_STATUSES = frozenset(
    {"VERIFIED", "REQUIRES_PERMISSION", "UNKNOWN", "DO_NOT_DISTRIBUTE"}
)

HADITH_COLLECTIONS = (
    "bukhari",
    "muslim",
    "abudawud",
    "nasai",
    "ibnmajah",
    "malik",
    "tirmidhi",
)
HADITH_LANGS = ("arabic", "english", "urdu")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def quran_dir() -> Path:
    return repo_root() / "assets" / "data" / "quran"


def hadith_dir() -> Path:
    return repo_root() / "assets" / "data" / "hadith"


def manifest_path() -> Path:
    return repo_root() / "assets" / "data" / "content_manifest.json"


def _rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root()).as_posix()
    except ValueError:
        return str(path)


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate_arabic(path: Path | None = None) -> dict:
    path = path or (quran_dir() / "quran_arabic.json")
    report: dict = {
        "path": _rel(path),
        "ok": False,
        "surahs": 0,
        "ayahs": 0,
        "empty_text": 0,
        "bom_ayahs": 0,
        "duplicate_global_numbers": 0,
        "ordering_ok": False,
        "edition": None,
        "issues": [],
    }
    if not path.exists():
        report["issues"].append("missing_file")
        return report
    data = load_json(path)
    payload = data.get("data", data) if isinstance(data, dict) else {}
    surahs = payload.get("surahs") if isinstance(payload, dict) else None
    if not isinstance(surahs, list):
        report["issues"].append("unexpected_shape")
        return report
    report["edition"] = payload.get("edition")
    report["surahs"] = len(surahs)
    numbers = [s.get("number") for s in surahs]
    report["ordering_ok"] = numbers == list(range(1, EXPECTED_SURAHS + 1))
    if not report["ordering_ok"]:
        report["issues"].append("surah_order")
    global_ids: list = []
    ayah_total = 0
    for idx, surah in enumerate(surahs, start=1):
        ayahs = surah.get("ayahs") or []
        ayah_total += len(ayahs)
        expected = AYAH_COUNTS[idx - 1] if idx <= len(AYAH_COUNTS) else None
        if expected is not None and len(ayahs) != expected:
            report["issues"].append(f"surah_{idx}_count_{len(ayahs)}_ne_{expected}")
        local = [a.get("numberInSurah") for a in ayahs]
        if local != list(range(1, len(ayahs) + 1)):
            report["issues"].append(f"surah_{idx}_numberInSurah")
        for ayah in ayahs:
            text = str(ayah.get("text") or "")
            if not text.strip():
                report["empty_text"] += 1
            if "\ufeff" in text[:2] or text.startswith("\ufeff"):
                report["bom_ayahs"] += 1
            global_ids.append(ayah.get("number"))
    report["ayahs"] = ayah_total
    dups = [k for k, v in Counter(global_ids).items() if v > 1]
    report["duplicate_global_numbers"] = len(dups)
    if report["surahs"] != EXPECTED_SURAHS:
        report["issues"].append("surah_count")
    if report["ayahs"] != EXPECTED_AYAHS:
        report["issues"].append("ayah_count")
    if report["empty_text"]:
        report["issues"].append("empty_text")
    if report["duplicate_global_numbers"]:
        report["issues"].append("duplicate_ids")
    # BOM is recorded but does not fail canonical 114/6236.
    report["ok"] = (
        report["surahs"] == EXPECTED_SURAHS
        and report["ayahs"] == EXPECTED_AYAHS
        and report["ordering_ok"]
        and report["empty_text"] == 0
        and report["duplicate_global_numbers"] == 0
        and not any(i.startswith("surah_") for i in report["issues"])
    )
    return report


def validate_cloud_translation(path: Path) -> dict:
    report = {
        "path": _rel(path),
        "ok": False,
        "surahs": 0,
        "ayahs": 0,
        "empty_text": 0,
        "edition": None,
        "issues": [],
    }
    if not path.exists():
        report["issues"].append("missing_file")
        return report
    data = load_json(path)
    payload = data.get("data", data) if isinstance(data, dict) else {}
    surahs = payload.get("surahs") if isinstance(payload, dict) else None
    if not isinstance(surahs, list):
        report["issues"].append("unexpected_shape")
        return report
    report["edition"] = payload.get("edition")
    report["surahs"] = len(surahs)
    total = 0
    empty = 0
    for surah in surahs:
        for ayah in surah.get("ayahs") or []:
            total += 1
            if not str(ayah.get("text") or "").strip():
                empty += 1
    report["ayahs"] = total
    report["empty_text"] = empty
    report["ok"] = (
        report["surahs"] == EXPECTED_SURAHS
        and report["ayahs"] == EXPECTED_AYAHS
        and empty == 0
    )
    if not report["ok"]:
        report["issues"].append("count_or_empty")
    return report


def validate_tanzil_translation(path: Path) -> dict:
    report = {
        "path": _rel(path),
        "ok": False,
        "rows": 0,
        "empty_text": 0,
        "duplicate_pairs": 0,
        "surahs": 0,
        "issues": [],
    }
    if not path.exists():
        report["issues"].append("missing_file")
        return report
    data = load_json(path)
    rows = data.get("quran") if isinstance(data, dict) else None
    if not isinstance(rows, list):
        report["issues"].append("unexpected_shape")
        return report
    report["rows"] = len(rows)
    pairs = []
    empty = 0
    by_surah: dict[int, list[int]] = {}
    for row in rows:
        chapter = int(row.get("chapter") or 0)
        verse = int(row.get("verse") or 0)
        pairs.append((chapter, verse))
        by_surah.setdefault(chapter, []).append(verse)
        if not str(row.get("text") or "").strip():
            empty += 1
    report["empty_text"] = empty
    report["duplicate_pairs"] = sum(1 for _, n in Counter(pairs).items() if n > 1)
    report["surahs"] = len(by_surah)
    shape_ok = True
    for idx, expected in enumerate(AYAH_COUNTS, start=1):
        got = sorted(by_surah.get(idx, []))
        if got != list(range(1, expected + 1)):
            shape_ok = False
            report["issues"].append(f"surah_{idx}_verses")
            break
    # Empty cells are integrity warnings, not rewritten. File can still be 6236 rows.
    report["ok"] = (
        report["rows"] == EXPECTED_AYAHS
        and report["surahs"] == EXPECTED_SURAHS
        and report["duplicate_pairs"] == 0
        and shape_ok
    )
    if empty:
        report["issues"].append("empty_text")
    return report


def validate_hadith_file(path: Path) -> dict:
    report = {
        "path": _rel(path),
        "ok": False,
        "exists": path.exists(),
        "name": None,
        "records": 0,
        "empty_text": 0,
        "duplicate_ids": 0,
        "missing_hadithnumber": 0,
        "issues": [],
    }
    if not path.exists():
        report["issues"].append("missing_file")
        return report
    data = load_json(path)
    meta = data.get("metadata") if isinstance(data, dict) else {}
    report["name"] = (meta or {}).get("name")
    hadiths = data.get("hadiths") if isinstance(data, dict) else None
    if not isinstance(hadiths, list):
        report["issues"].append("unexpected_shape")
        return report
    report["records"] = len(hadiths)
    ids = []
    for item in hadiths:
        hid = item.get("hadithnumber")
        if hid is None:
            report["missing_hadithnumber"] += 1
        else:
            ids.append(hid)
        if not str(item.get("text") or "").strip():
            report["empty_text"] += 1
    report["duplicate_ids"] = sum(1 for _, n in Counter(ids).items() if n > 1)
    report["ok"] = report["records"] > 0 and report["duplicate_ids"] == 0
    if report["duplicate_ids"]:
        report["issues"].append("duplicate_ids")
    if report["empty_text"]:
        report["issues"].append("empty_text")
    if report["missing_hadithnumber"]:
        report["issues"].append("missing_hadithnumber")
    return report


def scan_hadith() -> list[dict]:
    out = []
    root = hadith_dir()
    for coll in HADITH_COLLECTIONS:
        for lang in HADITH_LANGS:
            out.append(validate_hadith_file(root / coll / f"{lang}.json"))
    return out


def load_manifest() -> dict:
    path = manifest_path()
    if not path.exists():
        return {"sources": []}
    return load_json(path)


def validate_manifest(manifest: dict | None = None) -> dict:
    manifest = manifest if manifest is not None else load_manifest()
    sources = manifest.get("sources") or []
    issues = []
    verified_without_license = []
    for row in sources:
        status = row.get("status")
        if status not in ALLOWED_STATUSES:
            issues.append(f"bad_status:{row.get('id')}")
        if status == "VERIFIED":
            license_file = row.get("license_file") or ""
            if not license_file or not (repo_root() / license_file).exists():
                verified_without_license.append(row.get("id"))
                issues.append(f"verified_without_license_file:{row.get('id')}")
    return {
        "ok": not issues,
        "source_count": len(sources),
        "verified_without_license": verified_without_license,
        "issues": issues,
        "has_verified": any(r.get("status") == "VERIFIED" for r in sources),
    }


def nfc_diff_count(text: str) -> bool:
    return unicodedata.normalize("NFC", text) != text
