#!/usr/bin/env python3
# QIBRA AI — WORD-DATA BUILDER (Pass Q3)
# =====================================================================
# Builds the bundled word-level datasets under assets/data/quran/
# (word_gloss_en.json + word_timings_<qari>.json). Re-runnable from
# vendored upstream checkouts ($Q3_UPSTREAM, default /tmp). The runtime
# validator (lib/features/quran/data/word/quran_word_data.dart) mirrors
# the word-unit rule and re-checks counts on every load; the CI
# integrity test re-runs this script's guarantees over the SHIPPED files.
#
# PROVENANCE (fetched 2026-09-17; recorded in
# assets/data/content_manifest.json):
#   gloss     github.com/GlobalQuran/data (Apache-2.0; LICENSE in repo)
#             — Quran/quran-wordbyword.txt, one line per ayah in
#             canonical order, '$'-separated 'ARABIC|ENGLISH GLOSS|
#             n|n|id' entries (columns 3-4 are upstream metadata,
#             ignored). Some lines embed a literal '\n' between gloss
#             parts — splitting on it makes every entry one word.
#   timings   github.com/GlobalQuran/Quran-word-for-word (Apache-2.0)
#             — QuranSeg/qaree102.js (Abdul Basit Murattal) and
#             qaree103.js (Al-Husary): cue rows "s\t a\t start_ms\t
#             dur_ms\t word_idx" against the PER-AYAH mp3s of the
#             matching everyayah.com directory (their reciters.json maps
#             102→'Abdul_Basit_Murattal', 103→'Husary'). word_idx
#             enumerates the file line's whitespace tokens from 0; a
#             leading word_idx=-1 row spans the pre-word silence;
#             rows after the last word are inter-ayah silence (dropped).
#             Sura-head ayah files OPEN with the recited BASMALA (the
#             -1 row covers it); those ayahs' word cues index the sura
#             words only, so the mapper shifts them by the 4 reused
#             basmala spans and gives span 0 the lead window.
#             The app streams the 128/192kbps encodes of the SAME
#             per-ayah master cuts (bitrate never shifts a timeline);
#             cross-checked against the Quran.com v4 per-ayah segments
#             API the same day — agreement within ±150ms (two
#             independent annotation passes on identical audio).
#
# NO FABRICATED DATA: an ayah's word layer ships only when its own
# tokens align 1:1 with the file line under exact folding or a rasm
# skeleton (defective-WAṢL style variance) — never for timings unless
# cue indices also run consecutively from 0 over that word space and
# every window has positive length. Anything unverifiable is ABSENT;
# those ayahs run in honest whole-ayah mode. The census printed by
# this script is the disclosed truth (tests pin it).
# =====================================================================
import json
import os
import re
import sys

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
UPSTREAM = os.environ.get('Q3_UPSTREAM', '/tmp')
GQDATA = os.path.join(UPSTREAM, 'gqdata', 'Quran', 'quran-wordbyword.txt')
GQWBW = os.path.join(UPSTREAM, 'gqwbw', 'QuranSeg')
QAREES = {'ar.abdulbasitmurattal': 'qaree102', 'ar.husary': 'qaree103'}

INERT = re.compile('[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u0640'
                   '\u06dd\ufeff\u200b\u200c\u200d]')
FOLD = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
        'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ة': 'ه', 'ک': 'ك',
        'ٲ': 'ا', 'ٳ': 'ا', 'ٵ': 'ا', 'ٮ': 'ي', 'ۃ': 'ه'}


def norm(s):
    out = []
    for ch in s:
        if ch.isspace() or INERT.match(ch):
            continue
        out.append(FOLD.get(ch, ch.lower() if ord(ch) < 0x80 else ch))
    return ''.join(out)


def skel(s):
    return (norm(s).replace('ي', '').replace('و', '')
            .replace('ا', '').replace('ء', ''))


def eq(a, b):
    return norm(a) == norm(b) or skel(a) == skel(b)


def unit_tokens(text):
    """Whitespace tokens of the canonical text; marker-only runs attach
    to the PREVIOUS unit (mirrored exactly by Dart wordUnits())."""
    out = []
    lead = ''
    for t in text.split():
        if not norm(t):
            if out:
                out[-1] += t
            else:
                lead += t
            continue
        out.append(lead + t)
        lead = ''
    return out


def parse_line(line):
    raw = []
    gs = []
    for tk in line.split('$'):
        tk = tk.strip()
        if not tk or '|' not in tk:
            continue
        p = tk.split('|')
        ar = p[0].strip()
        if not ar:
            continue
        g = p[1].strip() if len(p) > 1 else ''
        for w in ar.split():
            raw.append(w)
            gs.append(g if g else (gs[-1] if gs else ''))
    return raw, gs


def align(ours, theirs):
    """1:1 with two join relaxations in either direction (the two files
    split whitespace differently both ways: silent-stop splits make our
    ONE token equal THEIRS+THEIRS; multi-word gloss entries make their
    ONE raw space-run equal OURS+OURS+…). Every our-token keeps exactly
    one their-index (the group start) for gloss lookup. Greedy k-way up
    to 3 on each side; these joins are structural, never ambiguous in
    place, and the full-cover check rejects anything else."""
    ao = []
    ti = []
    i = j = 0
    no, nt = len(ours), len(theirs)
    while i < no and j < nt:
        matched = False
        for k in range(1, 4):
            if i + k > no:
                break
            cand = ' '.join(ours[i:i + k])
            for m in range(1, 4):
                if j + m > nt:
                    break
                if (k == 1 or m == 1) and eq(cand, ' '.join(theirs[j:j + m])):
                    ao.append(cand)
                    ti.append(j)
                    i += k
                    j += m
                    matched = True
                    break
            if matched:
                break
        if not matched:
            return None
    if i != no or j != nt:
        return None
    return ao, ti


def main():
    ours = json.load(
        open(os.path.join(REPO, 'assets/data/quran/quran_arabic.json'),
             encoding='utf8'))
    surahs = ours['data']['surahs']
    texts = {}
    order = []
    for su in surahs:
        for a in su['ayahs']:
            key = '%d:%d' % (su['number'], a['numberInSurah'])
            texts[key] = a['text']
            order.append(key)
    basmala = unit_tokens(texts['1:1'])
    assert len(basmala) == 4, 'unexpected 1:1 tokenization'

    lines = [l for l in open(GQDATA, encoding='utf8').read().splitlines()
             if l.strip()]
    assert len(lines) >= len(order)
    parsed = {}
    for key, line in zip(order, lines[:len(order)]):
        parsed[key] = parse_line(line)

    glosses = {}
    degraded = []
    for key in order:
        s, a = map(int, key.split(':'))
        utoks = unit_tokens(texts[key])
        fraw, fg = parsed[key]
        head = (s not in (1, 9) and a == 1 and len(utoks) >= 5
                and all(eq(u, b) for u, b in zip(utoks[:4], basmala)))
        res = align(utoks, fraw)
        mode = 0
        if res is None and head:
            res = align(utoks[4:], fraw)
            mode = 1
        if res is None and head:
            res = align(utoks[4:], fraw[4:])
            mode = 2
        if res is None:
            degraded.append(key)
            continue
        ao, ti = res
        spans = []
        if mode in (1, 2):
            g0 = glosses.get('1:1')
            if g0 is None or len(g0['w']) < 4:
                degraded.append(key)
                continue
            # byte-faithful: the head's OWN first four units render,
            # carrying the (same-word) glosses verified in the 1:1 line
            spans = [[t, g0['w'][i][1]] for i, t in enumerate(utoks[:4])]
        for k, w in enumerate(ao):
            spans.append([w, fg[ti[k]]])
        glosses[key] = {'p': mode, 'w': spans}

    # ---- timings ----
    cue_re = re.compile(r'"(\d+)\t(\d+)\t(-?\d+)\t(-?\d+)\t(-?\d+)"')
    timings_out = {}
    census = {'gloss_ok': len(glosses), 'gloss_total': len(order),
              'gloss_degraded': len(degraded),
              'gloss_modes': {0: 0, 1: 0, 2: 0}}
    for e in glosses.values():
        census['gloss_modes'][e['p']] += 1
    for qari, label in QAREES.items():
        txt = open(os.path.join(GQWBW, '%s.js' % label),
                   encoding='utf8', errors='replace').read()
        rows = {}
        for m in cue_re.finditer(txt):
            sv, av, st, du, w = map(int, m.groups())
            rows.setdefault((sv, av), []).append((w, st, st + du))
        kept, bad = {}, []
        for (sv, av), rr in sorted(rows.items()):
            key = '%d:%d' % (sv, av)
            g = glosses.get(key)
            if g is None:
                bad.append(key)
                continue
            rr.sort()
            pos = [r for r in rr if r[0] >= 0]
            lead = next((r for r in rr if r[0] < 0), None)
            n = len(g['w'])
            p = g['p']
            need = n - (4 if p == 1 else 0)
            idx = [r[0] for r in pos]
            if need <= 0 or idx[:need] != list(range(need)):
                bad.append(key)
                continue
            sel = pos[:need]
            if any(e <= t or t < 0 for _, t, e in sel):
                bad.append(key)
                continue
            out = []
            if p == 1:
                if lead is not None:
                    out.append([0, max(0, lead[1]), sel[0][1]])
                out += [[k + 4, t, e] for k, (_, t, e) in enumerate(sel)]
            else:
                out = [[k, t, e] for k, (_, t, e) in enumerate(sel)]
            kept[key] = out
        ordered = {k: kept[k] for k in sorted(
            kept, key=lambda p2: tuple(map(int, p2.split(':'))))}
        timings_out[qari] = {
            'schema': 'qibra.word_timings.v1',
            'qari': qari,
            'source': {
                'upstream': 'GlobalQuran/Quran-word-for-word',
                'file': 'QuranSeg/%s.js' % label,
                'audio': 'everyayah per-ayah master cuts; app streams '
                         'the 128/192kbps encodes of the same cuts',
                'license': 'Apache-2.0',
            },
            'ayahs': ordered,
        }
        census[qari] = {'timed_ayahs': len(kept), 'ayah_rows': len(rows),
                        'rejected': len(bad), 'reject_sample': bad[:6]}

    allw = [norm(x) for t in texts.values() for x in t.split() if norm(x)]
    for probe in ['ٱلرَّحْمَٰنِ', 'ٱللَّهِ']:
        census['occurrences[%s]' % probe] = sum(
            1 for x in allw if x == norm(probe))

    out = {'schema': 'qibra.word_gloss.v1',
           'source': {
               'upstream': 'GlobalQuran/data (Apache-2.0)',
               'file': 'Quran/quran-wordbyword.txt',
               'note': 'per-word English glosses, verified word-for-word '
                       "against the app's own bundled Uthmani text; "
                       'unverified ayahs absent (whole-ayah mode)'},
           'ayahs': {k: glosses[k] for k in order if k in glosses}}

    def dump(name, obj):
        p2 = os.path.join(REPO, 'assets/data/quran', name)
        with open(p2, 'w', encoding='utf8') as f:
            json.dump(obj, f, ensure_ascii=False, separators=(',', ':'))
        return os.path.getsize(p2)

    sizes = {'word_gloss_en.json': dump('word_gloss_en.json', out)}
    for qari, o in timings_out.items():
        sizes['word_timings_%s.json' % qari] = dump(
            'word_timings_%s.json' % qari, o)
    census['sizes_kb'] = {k: round(v / 1024.0, 1) for k, v in sizes.items()}
    census['degraded_sample'] = degraded[:10]
    print(json.dumps(census, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    sys.exit(main())
