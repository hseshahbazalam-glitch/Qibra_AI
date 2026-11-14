#!/usr/bin/env python3
"""HOTFIX HR-2.2 — the Urdu join parity table, produced BEFORE any code change.

The owner's order for this hotfix is: measure the join first, ship it second. This
script is step one, and it is the file the § HR-2.2 report section is generated
from, so the table in the report and the table here cannot drift.

Three joins are run over the SHIPPED corpus, row by row (36,390 english spine rows):

  OLD      what ships today: `assembleHadithBook`'s `Map<int,String>` keyed by
           `_parseHadithNumber(hadithnumber)` — FLOORED, last write wins, a blank
           overwrites a real text. 52 shipped Urdu texts are destroyed this way.

  PUREPAIR what a naive "re-join on pairKey" would do: `pairTextIndex(urduRows)`
           keyed by `pairKey(hadithnumber, arabicnumber)` — exact, blanks skipped,
           FIRST record wins (the rule the four Phase-B languages already use).
           It recovers the 52, and it ALSO blanks 9 rows and re-attributes 28.

  SHIPPED  what HR-2.2 implements: keep the number-key text whenever it is
           non-blank, and consult the pair index ONLY to rescue a blank/missing
           hit. +52 recovered, 0 blanked, 0 re-attributed — by construction, and
           measured here rather than argued.

Why not PUREPAIR: two books do not share a numbering space with their English file
(measured below, `alignment`): malik's urdu carries 1,889 records against a 1,858-row
spine and agrees with the english row at the same index on 631 of 1,858 hadithnumbers,
muslim's on 0 of 7,563 (reference: 127). For those books a pair-key hit is not
evidence that the text belongs to the row — the number hit is what the reader has
been shown for the whole life of the feature. So the pair index is used as a rescue,
never as an override.

Every function mirrors its Dart twin BIT FOR BIT: `_hadith_number_key`/`_pair_key` ⇄
`HadithDatabaseService.numberKey`/`pairKey`, `_floor_number` ⇄ `_parseHadithNumber`,
`_pair_text_index` ⇄ `pairTextIndex`, `_number_map` ⇄ the `urduMap` loop and
`urdu_join_text` ⇄ `HadithDatabaseService.urduJoinText` — the helper step (b) of this
hotfix adds, which is why this file lands BEFORE the code it measures. The Dart-side twin of this
census is test/features/hadith/hadith_hotfix_hr22_pair_parity_test.dart: python and
Dart agreeing on the same 36,390 rows is the only reason the numbers below are
evidence rather than arithmetic.

Usage:
  python3 scripts/hr22_pairkey_parity.py          # human: summary + every row list
  python3 scripts/hr22_pairkey_parity.py --json   # machine-readable census
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HADITH = ROOT / "assets" / "data" / "hadith"
BOOKS = (
    "bukhari",
    "muslim",
    "abudawud",
    "nasai",
    "ibnmajah",
    "malik",
    "tirmidhi",
)


# ─── Dart mirrors ───────────────────────────────────────────────────────────


def _floor_number(value) -> int:
    """`HadithDatabaseService._parseHadithNumber` (display normalization)."""
    if value is None or isinstance(value, bool):
        return 0
    if isinstance(value, (int, float)):
        return int(value)  # Dart num.toInt() truncates toward zero
    s = str(value)
    m = re.match(r"^(\d+)", s)
    if m:
        return int(m.group(1))
    try:
        return int(s)
    except ValueError:
        return 0


def _hadith_number_key(value) -> str:
    """`HadithDatabaseService.numberKey` — exact, never floored."""
    if value is None or isinstance(value, bool):
        return ""
    if isinstance(value, int):
        s = str(value)
    elif isinstance(value, float):
        s = str(int(value)) if value == round(value) else repr(value)
    else:
        s = str(value).strip()
    if "." in s:
        s = re.sub(r"0+$", "", s)
        if s.endswith("."):
            s = s[:-1]
    return s


def _pair_key(hadith_number, arabic_number) -> str:
    """`HadithDatabaseService.pairKey`."""
    h = _hadith_number_key(hadith_number)
    a = _hadith_number_key(arabic_number)
    return f"{h}|{h}" if a in ("", "0") else f"{h}|{a}"


def _text_of(row) -> str:
    """Dart `map['text']?.toString() ?? ''`."""
    t = row.get("text")
    if t is None:
        return ""
    if isinstance(t, bool):
        return "true" if t else "false"
    if isinstance(t, float):
        return repr(t)
    return str(t)


def _number_map(rows) -> dict:
    """The OLD join: floored int key, last write wins, blanks overwrite."""
    out: dict[int, str] = {}
    for row in rows:
        if isinstance(row, dict):
            out[_floor_number(row.get("hadithnumber"))] = _text_of(row)
    return out


def _pair_text_index(rows) -> dict:
    """`pairTextIndex`: blank/whitespace texts skipped, first record wins."""
    out: dict[str, str] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        text = _text_of(row)
        if not text.strip():
            continue
        out.setdefault(
            _pair_key(row.get("hadithnumber"), row.get("arabicnumber")), text
        )
    return out


def _pair_ref_index(rows) -> dict:
    """Same walk as `_pair_text_index`, but keyed to the record's OWN reference.

    This exists for one purpose: the recovered rows must not merely be non-blank,
    each one has to be provably the Urdu of THIS hadith. `reference` is a third
    key the two files share and that neither join uses, so reference agreement is
    independent evidence that the pair rescue picked the right record.
    """
    out: dict[str, object] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        text = _text_of(row)
        if not text.strip():
            continue
        out.setdefault(
            _pair_key(row.get("hadithnumber"), row.get("arabicnumber")),
            row.get("reference"),
        )
    return out


def _urdu_join_text(by_number: str, by_pair: str) -> str:
    """`HadithDatabaseService.urduJoinText` — HR-2.2's shipped rule."""
    return by_number if by_number.strip() else (by_pair or by_number)


def _book(path: Path) -> list:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle).get("hadiths") or []


# ─── the census ─────────────────────────────────────────────────────────────


def census() -> dict:
    books: dict[str, dict] = {}
    for slug in BOOKS:
        spine = [r for r in _book(HADITH / slug / "english.json") if isinstance(r, dict)]
        urdu = [r for r in _book(HADITH / slug / "urdu.json") if isinstance(r, dict)]
        by_number, by_pair = _number_map(urdu), _pair_text_index(urdu)
        pair_ref = _pair_ref_index(urdu)

        # how far do the two files share a numbering space at the same index?
        agree_num = sum(
            1
            for e, u in zip(spine, urdu)
            if e.get("hadithnumber") == u.get("hadithnumber")
        )
        agree_ref = sum(
            1 for e, u in zip(spine, urdu) if e.get("reference") == u.get("reference")
        )

        counts = dict(
            spine=len(spine),
            urdu_records=len(urdu),
            number_keys=len(by_number),
            pair_keys=len(by_pair),
            align_number=f"{agree_num}/{min(len(spine), len(urdu))}",
            align_reference=f"{agree_ref}/{min(len(spine), len(urdu))}",
            en=0,
            ur_old=0,
            ur_pair=0,
            ur_new=0,
            neither_old=0,
            neither_new=0,
            recovered=0,
            recovered_ref_agrees=0,
            purepair_blanked=0,
            purepair_changed=0,
        )
        lists: dict[str, list] = {"recovered": [], "purepair_blanked": [], "purepair_changed": []}

        for i, row in enumerate(spine):
            num = _floor_number(row.get("hadithnumber"))
            key = _pair_key(row.get("hadithnumber"), row.get("arabicnumber"))
            old = by_number.get(num, "")
            pair = by_pair.get(key, "")
            new = _urdu_join_text(old, pair)
            en = _text_of(row).strip()
            ref = row.get("reference") or {}
            ident = dict(
                index=i,
                hadithnumber=row.get("hadithnumber"),
                arabicnumber=row.get("arabicnumber"),
                pairKey=key,
                book=ref.get("book"),
                hadith=ref.get("hadith"),
                oldChars=len(old.strip()),
                pairChars=len(pair.strip()),
                newChars=len(new.strip()),
            )
            counts["en"] += 1 if en else 0
            counts["ur_old"] += 1 if old.strip() else 0
            counts["ur_pair"] += 1 if pair.strip() else 0
            counts["ur_new"] += 1 if new.strip() else 0
            counts["neither_old"] += 1 if (not en and not old.strip()) else 0
            counts["neither_new"] += 1 if (not en and not new.strip()) else 0
            if not old.strip() and new.strip():
                counts["recovered"] += 1
                # independent proof: the record the pair key selects carries the
                # SAME reference as the english row it is being joined onto.
                ident["refAgrees"] = pair_ref.get(key) == row.get("reference")
                counts["recovered_ref_agrees"] += 1 if ident["refAgrees"] else 0
                lists["recovered"].append(ident)
            if old.strip() and not pair.strip():
                counts["purepair_blanked"] += 1
                lists["purepair_blanked"].append(ident)
            if old.strip() and pair.strip() and old != pair:
                counts["purepair_changed"] += 1
                lists["purepair_changed"].append(ident)
        books[slug] = {"counts": counts, **lists}

    keys = [k for k, v in books[BOOKS[0]]["counts"].items() if isinstance(v, int)]
    totals = {k: sum(b["counts"][k] for b in books.values()) for k in keys}
    return {"books": books, "totals": totals}


def _row_line(slug: str, r: dict) -> str:
    return (
        f"| {slug} | {r['index']} | {r['hadithnumber']} | {r['arabicnumber']} | "
        f"{r['pairKey']} | {r['book']}:{r['hadith']} | {r['oldChars']} | "
        f"{r['pairChars']} | {r['newChars']} |"
    )


def main() -> int:
    data = census()
    if "--json" in sys.argv:
        json.dump(data, sys.stdout, ensure_ascii=False)
        print()
        return 0

    print(
        "book        spine  urduRec numKeys pairKeys alignNum      alignRef   "
        "en    urOLD   urPAIR   urNEW  neither→  recov blanked changed"
    )
    for slug in BOOKS:
        c = data["books"][slug]["counts"]
        print(
            f"{slug:<11} {c['spine']:>5} {c['urdu_records']:>7} {c['number_keys']:>7} "
            f"{c['pair_keys']:>8} {c['align_number']:<13} {c['align_reference']:<13} "
            f"{c['en']:>5} {c['ur_old']:>7} {c['ur_pair']:>8} {c['ur_new']:>6}  "
            f"{c['neither_old']:>4}→{c['neither_new']:<4} {c['recovered']:>5} "
            f"{c['purepair_blanked']:>7} {c['purepair_changed']:>7}"
        )
    t = data["totals"]
    print(
        f"{'TOTAL':<11} {t['spine']:>5} {t['urdu_records']:>7} {'':>7} {'':>8} "
        f"{'':<13} {'':<13} {t['en']:>5} {t['ur_old']:>7} {t['ur_pair']:>8} "
        f"{t['ur_new']:>6}  {t['neither_old']:>4}→{t['neither_new']:<4} "
        f"{t['recovered']:>5} {t['purepair_blanked']:>7} {t['purepair_changed']:>7}"
    )
    print(
        f"\nrecovered rows whose pair-selected record carries the SAME reference as "
        f"the spine row: {t['recovered_ref_agrees']}/{t['recovered']} (a miss would "
        f"mean the rescue joined unrelated text)"
    )
    print(
        f"\nurdu coverage  OLD {t['ur_old']}/{t['spine']} = "
        f"{100 * t['ur_old'] / t['spine']:.2f} %   SHIPPED {t['ur_new']}/{t['spine']} = "
        f"{100 * t['ur_new'] / t['spine']:.2f} %   PUREPAIR {t['ur_pair']}/{t['spine']} = "
        f"{100 * t['ur_pair'] / t['spine']:.2f} %"
    )
    for kind, label in (
        ("recovered", "blank→text  (HR-2.2 recovers; the shipped rule's ONLY effect)"),
        ("purepair_blanked", "text→blank  (what a naive full re-key would destroy — every case below)"),
        ("purepair_changed", "text→different-text  (what a naive full re-key would re-attribute)"),
    ):
        rows = [(s, r) for s in BOOKS for r in data["books"][s][kind]]
        print(f"\n=== {label}: {len(rows)} rows ===")
        head = "| book | spine index | hadithnumber | arabicnumber | pairKey | ref | old ch | pair ch | new ch |"
        if kind == "recovered":
            head += " reference agrees |"
            print(head)
            print("|" + "---|" * 10)
        else:
            print(head)
            print("|" + "---|" * 9)
        for slug, r in rows:
            line = _row_line(slug, r)
            if kind == "recovered":
                line += f" {'YES' if r['refAgrees'] else 'NO'} |"
            print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
