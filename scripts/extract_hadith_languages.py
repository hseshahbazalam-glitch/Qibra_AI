#!/usr/bin/env python3
"""
scripts/extract_hadith_languages.py — Phase B extraction (owner decision
Option A + bundle, 2026-09-05).

Normalizes four new hadith-api language editions (ben/tur/ind/fra) into
this repo's per-book JSON shape.

ALIGNMENT RULE #1 (the whole point of this script): dataset records are
joined to OUR shipped records ONLY by the (hadithnumber, arabicnumber)
pair — never by array position/idx. Our counts differ from the dataset's
(bukhari 7,589 vs 7,563; tirmidhi 3,998 vs 3,956; malik 1,889 vs 1,858),
so position-joins would misattribute text — the one thing this repo may
never do. Unmatched hadiths simply have NO record in the language file,
which the Dart loader turns into hasX=false -> honest "unavailable in
this language". Empty dataset texts are dropped by the same rule.

Sources: fawazahmed0/hadith-api, branch `1`, editions/<lang>-<book>.json
(the dataset's OWN pretty editions; downloaded via the GitHub blobs API
on 2026-09-05 — see docs/CONTENT_LICENSE_MANIFEST.md for the license
truth: repo-level Unlicense, translator licensing UNKNOWN — which is
why manifest rows stay UNKNOWN and attribution stays as the dataset's).

Output records keep the base-file order and are written COMPACT (no
pretty indentation; identical text bytes) to shrink bundle size where
honest. Per book × language a mismatch report is printed — it belongs in
the Phase B report, not silently dropped.
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_DIR = os.environ.get("HADITH_SRC", os.path.expanduser("~/hadith-lang-src"))
BOOKS = ["bukhari", "muslim", "abudawud", "nasai", "tirmidhi", "ibnmajah", "malik"]
LANGS = {  # output file-name -> dataset edition prefix
    "bengali": "ben",
    "turkish": "tur",
    "indonesian": "ind",
    "french": "fra",
}


def canon(v):
    """Mirror of the shipped Dart loader's _parseHadithNumber (leading-digit
    int; null/0 -> 0). Using the exact same semantics on both sides is what
    makes the Python join and the runtime pair-join agree by construction
    (e.g. Muslim's fractional-string arabicnumbers '3033.02' -> 3033)."""
    if v is None or isinstance(v, bool):
        return 0
    if isinstance(v, (int, float)):
        return int(v)
    s = str(v).strip()
    if not s:
        return 0
    import re

    m = re.match(r"^(\d+)", s)
    if m:
        return int(m.group(1))
    try:
        return int(s)
    except ValueError:
        return 0


def norm_pair(h, a):
    hi = canon(h)
    if hi == 0:
        return None  # unjoinable record -> shows up in the report as dataset-unmatched
    ai = canon(a)
    return (hi, ai if ai != 0 else hi)


def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main():
    if not os.path.isdir(SRC_DIR):
        sys.exit(f"missing source dir {SRC_DIR}")
    report = []
    for book in BOOKS:
        base_path = os.path.join(ROOT, "assets/data/hadith", book, "english.json")
        base = load_json(base_path)
        base_records = base["hadiths"]
        base_keys = {}
        dup_base = 0
        for r in base_records:
            k = norm_pair(r.get("hadithnumber"), r.get("arabicnumber"))
            if k is None:
                continue
            if k in base_keys:
                dup_base += 1
                continue
            base_keys[k] = r
        for file_name, prefix in LANGS.items():
            src = os.path.join(SRC_DIR, f"{prefix}-{book}.json")
            out = os.path.join(ROOT, "assets/data/hadith", book, f"{file_name}.json")
            if not os.path.exists(src):
                report.append(
                    (book, prefix, "NO-SOURCE", len(base_records), len(base_keys),
                     0, 0, 0, 0, 0, 0)
                )
                if os.path.exists(out):
                    os.remove(out)
                continue
            data = load_json(src)
            recs = data.get("hadiths") or []
            lang_map = {}
            empty = 0
            dup_lang = 0
            for r in recs:
                k = norm_pair(r.get("hadithnumber"), r.get("arabicnumber"))
                if k is None:
                    continue
                text = (r.get("text") or "").strip()
                if not text:
                    empty += 1
                    continue
                if k in lang_map:
                    dup_lang += 1
                    continue
                lang_map[k] = r
            out_records = []
            for k, base_r in base_keys.items():
                hit = lang_map.get(k)
                if hit is None:
                    continue
                out_records.append(
                    {
                        "hadithnumber": base_r.get("hadithnumber"),
                        "arabicnumber": base_r.get("arabicnumber"),
                        "text": hit["text"],
                        "reference": base_r.get("reference"),
                    }
                )
            matched = len(out_records)
            unmatched_dataset = len(lang_map) - matched
            with open(out, "w", encoding="utf-8") as f:
                json.dump(
                    {
                        "metadata": {"name": base["metadata"].get("name", book),
                                     "sections": base["metadata"].get("sections", {})},
                        "hadiths": out_records,
                    },
                    f,
                    ensure_ascii=False,
                    separators=(",", ":"),
                )
            report.append(
                (book, prefix, "OK", len(base_records), len(base_keys), len(recs),
                 matched, unmatched_dataset, empty, dup_lang, dup_base)
            )
    w = max(len(f"{b}/{l}") for b, l, *_ in report) if report else 10
    print(f"{'book/lang'.ljust(w)} | status | oursRaw | oursKeys | dataset | matched | unmatched(ds) | empty | dupds | dupours")
    for row in report:
        b, l, status, oraw, okeys, dsn, matched, um, empty, dupl, dupo = row
        print(f"{(b + '/' + l).ljust(w)} | {status:8s} | {oraw:7d} | {okeys:8d} | {dsn:7d} | "
              f"{matched:7d} | {um:11d} | {empty:5d} | {dupl:5d} | {dupo:5d}")


if __name__ == "__main__":
    main()
