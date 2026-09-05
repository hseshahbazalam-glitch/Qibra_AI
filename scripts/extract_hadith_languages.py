#!/usr/bin/env python3
"""
scripts/extract_hadith_languages.py — Phase B extraction (owner decision
Option A + bundle, 2026-09-05) — REV. 2 after the owner's device test-run
exposed the fractional-hadithnumber problem.

Normalizes four new hadith-api language editions (ben/tur/ind/fra) into
this repo's per-book JSON shape.

ALIGNMENT RULE #1 (the whole point of this script): dataset records are
joined to OUR shipped records ONLY by the (hadithnumber, arabicnumber)
pair — never by array position/idx. Our counts differ from the dataset's
(bukhari 7,589 vs 7,563 canonicalized; tirmidhi 3,998 vs 3,956; malik
1,889 vs 1,858), so position-joins would misattribute text — the one
thing this repo may never do.

FRACTIONAL NUMBERS (Rev. 2 — a REAL join bug this fix removes): sunnah.com
numbering reuses one number across chapters with fractional sub-numbers
(bukhari 402 and 402.2 are DIFFERENT texts: the second is a cross-chapter
citation 'as above'; tirmidhi's 3604.x is a ten-hadith bundle). Rev. 1
keyed pairs on the loader's leading-digit floor — 402.2 collapsed onto 402
— which misattributed the parent's translation to citation records and
made 132 real fractional dataset texts (fra-bukhari 402.2 carries its own
translation!) colliders that first-wins discarded. THIS version keys on
the EXACT normalized number strings (402 != 402.2; '446.0' == 446), the
same normalization the Dart runtime applies (HadithDatabaseService
.numberKey/pairKey are the mirror of canon_num below — pinned by
test/hadith_multilang_test.dart). Fractional records join only to their
own dataset record: real translation when present (Fra), honest 'no text'
fallback when the dataset's fractional slot is empty (Ben 402.2 — which
is exactly right, since the citation has nothing to translate).

One record is emitted per BASE record (1:1 mirror, base order preserved)
— duplicate pairs in our base (same exact numbers, e.g. the 26 bukhari
collisions that are not fractional) share the one language text, matching
the runtime pair map's first-wins semantics. Unmatched or empty dataset
texts are DROPPED (no record -> hasX false in Dart), never guessed.

Sources: fawazahmed0/hadith-api, branch `1`, editions/<lang>-<book>.json
(fetched via the GitHub blobs API on 2026-09-05). License truth lives in
docs/CONTENT_LICENSE_MANIFEST.md: repo-level The Unlicense, translator
licensing UNKNOWN. Output is compact JSON; sizes are shrunk where honest
(no per-language grades — the dataset grades live only in ara-* editions).

A full-table mismatch report is printed: it belongs in the Phase B
report, not silently dropped.
"""
import json
import os
import re
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


def canon_num(v):
    """Exact fractional-aware number key. Mirrors Dart
    HadithDatabaseService.numberKey: ints bare, trailing '.0'/'00'
    stripped, strings trimmed. 402 -> '402'; 402.2 -> '402.2';
    '446.00' -> '446'; None -> ''."""
    if v is None or isinstance(v, bool):
        return ""
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if v == int(v):
            return str(int(v))
        s = repr(v)
    else:
        s = str(v).strip()
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    return s


def norm_pair(h, a):
    ch = canon_num(h)
    if ch in ("", "0"):
        return None  # unjoinable on both sides; surfaces as dataset-unmatched
    ca = canon_num(a)
    return (ch, ca if ca not in ("", "0") else ch)


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
                report.append((book, prefix, "NO-SOURCE", len(base_records),
                               len(base_keys), 0, 0, 0, 0, 0, 0))
                if os.path.exists(out):
                    os.remove(out)
                continue
            recs = load_json(src).get("hadiths") or []
            lang_map = {}
            empty = 0
            dup_lang = 0
            frac_texted = 0
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
                if "." in k[0]:
                    frac_texted += 1
            # 1:1 mirror: one language record per BASE record whose exact
            # pair matched (base order; references/hadithnumbers copied
            # from the base record itself — never from the dataset).
            out_records = []
            for br in base_records:
                k = norm_pair(br.get("hadithnumber"), br.get("arabicnumber"))
                hit = lang_map.get(k) if k is not None else None
                if hit is None:
                    continue
                out_records.append({
                    "hadithnumber": br.get("hadithnumber"),
                    "arabicnumber": br.get("arabicnumber"),
                    "text": hit["text"],
                    "reference": br.get("reference"),
                })
            matched = len(out_records)
            unmatched_dataset = len(set(lang_map) - set(base_keys))
            with open(out, "w", encoding="utf-8") as f:
                json.dump(
                    {
                        "metadata": {
                            "name": base["metadata"].get("name", book),
                            "sections": base["metadata"].get("sections", {}),
                        },
                        "hadiths": out_records,
                    },
                    f, ensure_ascii=False, separators=(",", ":"),
                )
            report.append((book, prefix, "OK", len(base_records), len(base_keys),
                           len(recs), matched, unmatched_dataset, empty,
                           dup_lang, frac_texted))
    w = max(len(f"{b}/{l}") for b, l, *_ in report) if report else 10
    print(f"{'book/lang'.ljust(w)} | status | oursRaw | oursKeys | dataset | "
          f"matched | unmatched(ds) | empty | dupds | fracText")
    for row in report:
        b, l, status, oraw, okeys, dsn, matched, um, empty, dupl, frac = row
        print(f"{(b + '/' + l).ljust(w)} | {status:8s} | {oraw:7d} | {okeys:8d} | "
              f"{dsn:7d} | {matched:7d} | {um:11d} | {empty:5d} | {dupl:5d} | {frac:8d}")


if __name__ == "__main__":
    main()
