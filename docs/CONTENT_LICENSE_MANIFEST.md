# Content license manifest

**Date:** 2026-08-30  
**Rule:** UNKNOWN stays UNKNOWN. VERIFIED requires an in-repo license file. This is **not** legal advice.

Sidecar: `assets/data/content_manifest.json`. Quran/Hadith JSON was **not** rewritten.

| Content | Source | Author/Translator | License | Commercial Use | Redistribution | Attribution | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Arabic Quran (Uthmani) | `assets/data/quran/quran_arabic.json` (`quran-uthmani`) | — | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| English translation | `translation_en.json` (`en.asad`) | Muhammad Asad | UNKNOWN | UNKNOWN | UNKNOWN | named in JSON | REQUIRES_PERMISSION |
| Urdu (Jalandhry) | `translation_ur_jalandhry.json` | Fateh Muhammad Jalandhry (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Urdu (Junagarhi) | `translation_ur_junagarhi.json` | Muhammad Junagarhi (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Urdu (Maududi) | `translation_ur_maududi.json` | Abul A'la Maududi (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Roman Urdu (Maududi) | `translation_ur_maududi_roman.json` | Maududi roman (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Urdu (Tahir-ul-Qadri) | `translation_ur_tahirulqadri.json` | Tahir-ul-Qadri (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Urdu (Usmani) | `translation_ur_usmani.json` | Usmani (filename) | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Sahih al-Bukhari JSON | `assets/data/hadith/bukhari/` | Imam al-Bukhari (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Sahih Muslim JSON | `assets/data/hadith/muslim/` | Imam Muslim (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Sunan Abu Dawud JSON | `assets/data/hadith/abudawud/` | Imam Abu Dawud (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Sunan an-Nasa'i JSON | `assets/data/hadith/nasai/` | Imam an-Nasa'i (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Sunan Ibn Majah JSON | `assets/data/hadith/ibnmajah/` | Imam Ibn Majah (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Muwatta Malik JSON | `assets/data/hadith/malik/` | Imam Malik (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Jami at-Tirmidhi JSON | `assets/data/hadith/tirmidhi/` (urdu.json exists: 3,998 records, 67 with empty text — per-hadith fallback territory, found 2026-09-05; the old “no urdu.json” note was stale) | Imam al-Tirmidhi (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Tafsir Ibn Kathir | not bundled | Ibn Kathir (work); edition absent | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | DO_NOT_DISTRIBUTE |
| Word-by-word meanings | not bundled | — | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Hindi translation | not bundled | — | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
| Recitation audio | not bundled; streamed at runtime from everyayah.com (`Alafasy_128kbps`, per-ayah) with cdn.islamic.network fallback (`ar.alafasy`, global-ayah) — audio stage below | Mishary Rashid Alafasy | free non-commercial web distribution by the source sites; NO license file in repo | UNKNOWN | runtime fetch only; **no audio committed** (G15 gate); offline copies live in app-internal storage on-device | qari named in code + UI | REQUIRES_PERMISSION |

Permission required for any VERIFIED upgrade: a license file in git, plus explicit commercial/redistribution terms. Do not ship a store build treating these rows as cleared.

Unbundled Hindi remains an honest miss. Recitation audio is STILL not
bundled — what changed (2026-09-03, audio stage) is that it is now
*streamed* at runtime; see the next section.

## Quran recitation audio (2026-09-03, audio stage)

The app ships **no recitation files** and the static battery (G15) fails
the build if any ever enter this repo. Playback fetches per-ayah MP3s at
runtime from **everyayah.com** (`data/Alafasy_128kbps/SSSAAA.mp3`, the
archive's public non-commercial distribution of Mishary Rashid Alafasy's
128 kbps recitation), falling back to **cdn.islamic.network**
(`quran/audio/128/ar.alafasy/<global>` — the King Fahd Complex-run CDN)
exactly once per track before surfacing an honest failure. Optional
per-surah downloads are written to app-internal storage only
(`tilawat/ar.alafasy/`), can be deleted from the UI, and are never
committed, mirrored, or re-hosted by us — and never proxied through the
app's backend. Both sites publish these recitations freely for personal
use, and neither grants Qibra a *commercial* redistribution license in
writing, so per this manifest's rule the status stays
**REQUIRES_PERMISSION / commercial-use UNKNOWN**: this is streaming from
the sources' own public CDNs, not redistribution by us, and upgrading
this row to VERIFIED would require an actual license file in git. The
audio is Quran recitation — the content itself is the verbatim Arabic
text already in the app; only the audio editions' terms are the open
question.

## Hadith language expansion — dataset investigation (2026-09-05, Phase A, no feature code)

Source investigated: **fawazahmed0/hadith-api**, branch `1` (repo last pushed
2026-06-03), read through the dataset's OWN metadata (`editions.json`, per-edition
`author`/`language`/`source` fields, per-hadith file trees) — not third-party
keyword tags. GitHub tree API + per-directory counts; no full clone.

**License truth (answers the “CC0 vs CC BY-NC” question: neither).** The repo's
`LICENSE` file is **The Unlicense** — a public-domain dedication by the repo
author for *their* work (the compilation/scripts). It is not CC0 and not
CC BY-NC, and it cannot dedicate translators' copyrights it doesn't hold:
edition metadata lists `author: "Unknown"` for almost everything, `source` is
empty for most languages (rus → isnad.link; malik-urdu → an archive.org copy of
Rahmat Publications' Salim Al-Hilali), and References.md credits third-party
sites (sunnah.com, urdupoint, al-maktaba, IIUM, hamariweb, …) without
per-translation license files. **Consequence under this manifest's rule
(UNKNOWN stays UNKNOWN, VERIFIED requires an in-repo license file): hadith
content rows above are NOT upgraded by the Unlicense statement.** Bundling
any new language is a distribution decision the owner must make with that
gap visible — same footing as the existing ar/en/ur rows.

**Availability matrix (language × our 7 collections).** All covered
languages carry the canonical hadith counts per book (bukhari 7,563 · muslim
7,563 · abudawud 5,274 · nasai 5,758 · tirmidhi 3,956 · ibnmajah 4,341 ·
malik 1,858 — file-count verified against per-hadith directory trees; text
presence spot-checked at first/middle/last files in each language, all
non-empty). “Raw MB” = sum of the seven pretty JSON files; “min MB” = sum of
`.min.json`:

| Lang | Books | Raw MB | min MB | Notes |
| --- | --- | --- | --- | --- |
| ara (Arabic) | 7/7 | 47.8 | 44.4 | already bundled; only editions with `grades` data; also diacritics-removed `-1` variants |
| eng (English) | 7/7 | 25.8 | 22.4 | already bundled; authors vary per book (Muhsin Khan bukhari, Abdul Hamid Siddiqui abudawud, rest Unknown) |
| urd (Urdu, Nastaliq) | 7/7 | 39.9 | 36.5 | already bundled; `rtl` |
| ben (Bengali) | 7/7 | 60.3 | 56.9 | PASS coverage gate |
| tur (Turkish) | 7/7 | 35.2 | 31.8 | PASS coverage gate |
| ind (Indonesian) | 7/7 | 34.3 | 30.9 | PASS coverage gate |
| fra (French) | 6/7 | 23.6 | 20.7 | no `fra-tirmidhi` in dataset → tirmidhi = “unavailable in this language” per book; PASSES the ≥5/7 gate |
| rus (Russian) | 3/7 | 17.1 | 15.7 | BELOW GATE — skipped (hadith-api covers bukhari/muslim/abudawud only) |
| tam (Tamil) | 2/7 | 23.8 | 23.0 | BELOW GATE — skipped |
| Roman Urdu | 0/7 | — | — | **does not exist in the dataset** (only script-Urdu `urd-*`). Per the fabricated-text rule this is reported unavailable-by-data; no model-generated translations were or will be used. |

**Size rule status (owner decides before any Phase B).** Every gate-passing
NEW language adds **>20 MB of bundle assets raw** (ben 60.3 / tur 35.2 / ind
34.3 / fra 23.6 MB), so the standing SIZE RULE says: **STOP — do not bundle;
download-pack (tilawat pattern: on-demand fetch, app-internal cache, deletable
from UI, nothing committed) is the compliant route.** Measured on the existing
bundle, Flutter's asset deflate compresses these JSON at ~5.7× (3.12 MB →
0.55 MB sample), so *if* the owner elects bundling anyway, expected APK deltas
are roughly ben ≈10.6 / tur ≈6.2 / ind ≈6.0 / fra ≈4.2 MB (device APK build is
the authority, not this estimate). New languages carry `grades: []` — the
grade chip already hides unknown grades, so nothing is invented there.

**Per-hadith gaps for the fallback to cover:** at file level none found for
covered books (counts match canonical); empty-text records DO exist inside
our current tirmidhi Urdu extraction (67) — the fallback UI is therefore
already load-bearing for shipped data, not hypothetical.

### Phase B — executed (owner elected BUNDLE, 2026-09-05)

The owner elected Option A (bundle all four languages) over download-pack,
explicitly overriding the >20 MB size rule with knowledge of the numbers
above. Record of what shipped:

- **Transport:** `fawazahmed0/hadith-api` @ branch `1`, `editions/{ben,tur,ind,fra}-{book}.json`
  fetched via the GitHub blobs API (27 files, 153.4 MB; `fra-tirmidhi` does not exist).
- **Extraction (Rev. 2):** `scripts/extract_hadith_languages.py` (kept in-repo as
  provenance). Records are joined to OUR shipped records ONLY by the exact canonical
  `(hadithnumber, arabicnumber)` pair — never by array index, never by flooring.
  Both sides key numbers through identical logic (Python `canon_num` ≡ Dart
  `HadithDatabaseService.numberKey`: integral values stringify without a decimal
  point, fractional labels like `402.2` stay strings), so the Python join and the
  runtime Dart join agree by construction — verified over all 476,040 base-record
  numbers (0 key mismatches). Empty language texts are skipped (they must not
  shadow a real record). Unmatched or empty dataset records are DROPPED (they
  become `hasX == false` → the "unavailable" fallback), never guessed. Output is
  compact JSON (no pretty indentation, no per-language `grades` — the dataset's
  grades live only in `ara-*` editions, so nothing is invented; the grade chip
  keeps reflecting the base record).
- **Mismatch report (measured; full table printed by the script):** dataset-unmatched
  is 0 for every book × language except Malik, where the French edition carries 41
  (and Indonesian 1) records whose numbers our 1,858-record base does not contain —
  reported, not force-joined, not dropped silently. Dataset-side empty texts are
  skipped, never padded (e.g. turkish-Nasai: 5,136 of 5,765 records are empty — only
  the 629 real translations ship; bengali-bukhari: 60 numbered empties including
  402.2, which is therefore HONESTLY absent in Bengali). Our base contains 60
  duplicate `(hadithnumber, arabicnumber)` pairs (54 of them point at DIFFERENT
  records — Rev. 1's last-wins base parse had misattributed them); the extractor
  takes base-first and the runtime mirror reproduces the identical choice.
- **Coverage per book (keyed records → texts shipped):**

  | book (our keyed) | bn | tr | id | fr |
  | --- | --- | --- | --- | --- |
  | bukhari (7,563) | 7,529 | 7,521 | 6,858 | 7,589 |
  | muslim (7,563) | 7,360 | 7,380 | 4,927 | 7,307 |
  | abudawud (5,274) | 5,270 | 5,266 | 4,406 | 5,274 |
  | nasai (5,758) | 5,656 | 629 | 5,335 | 5,679 |
  | tirmidhi (3,956) | 3,895 | 3,769 | 3,540 | — (no fra-tirmidhi edition) |
  | ibnmajah (4,341) | 4,336 | 4,319 | 4,269 | 4,340 |
  | malik (1,858) | 1,749 | 1,558 | 1,552 | 1,505 |
  | **total** | **35,795** | **30,442** | **30,887** | **31,694** |

- **Fractional records:** where the datasets themselves number a hadith `N.2`, the
  key is shipped as the string `"N.2"` and joins 1:1 to the base's fractional entry.
  90 such records ship (e.g. fr-bukhari 26 — including 402.2 "Rapporté par Anas…",
  whose 844-character text Rev. 1 had mislabeled as 402 — tr-bukhari 11, id-tirmidhi 19,
  fr-nasai 7, bn-tirmidhi 4, tr-tirmidhi 14, id-bukhari 2, id-nasai 4, fr-ibnmajah 2,
  tr-ibnmajah 1). The multilang test pins 402.2 present (fr) / absent (bn) verbatim.

- **License status unchanged:** the dataset's repo-level The Unlicense dedication
  covers the repo owner's rights only. Translator-level licensing for bn/tr/id/fr
  remains **UNKNOWN — no row was upgraded**; `assets/data/content_manifest.json`
  records the seven-language layout and the UNKNOWN stance. These translations are
  human works credited to their published editions (sunnah.com / urdupoint /
  al-maktaba / IIUM / isnad.link per the dataset's References); no AI-generated
  translation text is or will be bundled under any name.
- **Size as shipped (Rev. 2):** 27 files, **125,468,580 B raw → ≈24.9 MB deflated**
  (measured in-repo, zlib-9 per language: bn 53.3→7.4, tr 27.7→7.6, id 26.8→5.6,
  fr 17.7→4.3 MB). The extraction's stripping (compact JSON, no duplicate
  metadata, empties dropped, no per-language grades) is what brought Phase A's
  ~27.4 MB combined estimate down. Expected APK asset delta ≈ 25 MB (device build
  is the authority). Bundle raw total 109 → 234 MB.
- **Loader honesty:** the per-book loader keeps the existing pattern — sequential
  per-book loads with one `Future.wait` batch of rootBundle reads on the UI isolate
  (no isolates exist in `_loadBook` today; `searchBatchOffMain` already off-isolates
  query scans). Boot now decodes ≈4× more JSON than before; device measurement is
  the authority for any ANR/memory follow-up (flagged, not hidden).
- **UI contract:** the reading-language set and the Settings selector are DERIVED
  from `HadithAvailability` (lib/features/hadith/data/hadith_availability.dart),
  pinned to disk by `test/hadith_multilang_test.dart`. French shows its honest
  "6 of 7 collections" note; inside Tirmidhi every French hadith renders the
  existing "Verified translation unavailable for this language." fallback line
  (per-hadith mechanism chosen over a selector lock — documented decision).
  Book screen, home tab (today card, tiles, detail sheet, recently-read),
  home feed card and the related-hadith strip all consume
  `hadithTextForLanguage`/`localHadithTextForLanguage` — no surface shows a
  fixed-English body anymore. RTL: Urdu renders rtl, Arabic remains the source
  block (translation block hidden when the reading language is Arabic).
  Search: db + in-book filters match all seven language fields; the fold passes
  Bengali codepoints through unchanged (verified pinned). **Known limitation:**
  no accent/turkish-specific case folding — queries must match diacritics
  verbatim (pinned as a limitation, not fixed silently).

### Phase B unbundled — PASS X5 (2026-11-12)

The owner's app-size pass removed the four Phase B translations from the
**shipped bundle**. Everything above stays as the record of what was bundled,
how it was extracted and how it was joined; what changed is the file list, not
the provenance:

| | before X5 | after X5 |
| --- | --- | --- |
| hadith JSON files | **49** = 48 editions (7 books x 7 − the absent fr-tirmidhi) + kitab_names.json | **22** = 21 editions (7 x 3) + kitab_names.json |
| raw size (sum of file bytes) | 228.0 MB | **108.3 MB** (hadith); all of `assets/`: 106 files / 301.3 MB -> 79 files / **181.7 MB** |
| deflated per file, zlib-9 (what an APK entry actually costs) | 40.6 MB (hadith); 55.6 MB (all of `assets/`) | **16.9 MB** / **31.9 MB** — a **23.7 MB** expected APK asset delta, NOT ~120 MB (device build is the authority, as ever) |
| selector | 7 codes ('fr' carrying the '6 of 7 collections' note) | **3 codes** — `en`, `ar`, `ur`, all 7 books, no note |

* **What was removed:** `assets/data/hadith/<book>/{bengali,turkish,indonesian,french}.json`
  — 27 files, 119.7 MB raw / 23.7 MB deflated (french-tirmidhi never existed).
* **What was NOT:** the pair-key join (`pairKey`/`pairTextIndex`), the per-language
  coverage math, the model's `textBengali`-family fields and
  `scripts/extract_hadith_languages.py`. `HadithAvailability` remains the single
  source of truth and `newLanguageFiles` is now empty — so re-bundling an
  edition is *data + one map row*, and `warmLanguage` correctly answers "nothing
  to fold" for every code in the meantime. X1's lazy fold therefore costs zero
  at boot and stays available.
* **Licence stance:** unchanged. The rows stayed `UNKNOWN` while these files
  shipped and there is nothing to downgrade or upgrade now that they do not.
  The `content_manifest.json` hadith rows were re-scoped to
  `(ar/en/ur JSON)` and its `notes` line records the removal, so the sidecar
  cannot claim bytes the bundle no longer carries — that claim is a test
  (`sidecar records the THREE-edition layout and the X5 removal`).
* **Reader impact:** a device that had Bengali/Turkish/Indonesian/French selected
  now falls back to English through the notifier's existing
  `supported.contains(saved)` filter; no screen can open an edition with no file
  behind it. The disclosure rows shrink with the data: two remain (Urdu in
  Nasai at 67%, Urdu in Malik at 86%) and both are pinned against the shipped
  files.

## Hadith data freshness — HR-2 verification (2026-11-14, result: no rewrite)

Owner instruction for this pass, verbatim: *"redesign karo, hadith me jo 3 language h
avi wahi rahe, data restore NAHI krna h — bus fresh data dalna h"*. The three shipped
languages (en / ar / ur) therefore stay exactly as they are, and "fresh" was measured
against **upstream**, not against git history. Upstream is `fawazahmed0/hadith-api` @
branch `1` (repo last pushed 2026-06-03), file set `editions/{ara,eng,urd}-{book}.json`
for the same seven books. The answer came back: **the app is already on the current
upstream bytes — there is nothing to restore and nothing to refresh.**

Method, chosen so that no normalization, no diff tool and no judgment sits between the
two sides: compare **git blob SHAs**. `git hash-object` of the shipped file against the
`sha` the GitHub contents API reports for the same path upstream. An equal blob SHA is
byte-identity, full stop.

| book | eng | ara | urd |
| --- | --- | --- | --- |
| bukhari | `993e35a5` · 5,181,725 · = | `72a64ea2` · 9,770,083 · = | `69a1fa4a` · 9,945,297 · = |
| muslim | `344d1f3e` · 4,296,152 · = | `a94ab4a0` · 8,685,140 · = | `9c656e01` · 7,657,637 · = |
| abudawud | `99434b22` · 4,311,308 · = | `3a9fd5a3` · 7,345,422 · = | `80176612` · 6,068,981 · ≠ |
| tirmidhi | `d7ffdab2` · 3,124,797 · = | `80d8ed3d` · 7,120,806 · = | `fbd50f84` · 5,751,781 · = |
| nasai | `2842bd08` · 4,033,923 · = | `e383bdb2` · 7,152,291 · = | `43959fcb` · 4,672,980 · ≠ |
| ibnmajah | `911b1d01` · 3,241,088 · = | `ee6c03a4` · 5,583,102 · ≠ | `46645c67` · 4,342,459 · = |
| malik | `373cfbaa` · 1,614,960 · = | `cbdd5570` · 2,150,337 · = | `1ea618bf` · 1,498,465 · = |

`=` upstream blob SHA == shipped blob SHA (byte-identical) · `≠` differs. Upstream
truncated SHA-1 and upstream byte size per cell.

### What the 3 differing files actually contain

**1,760 bytes. That is the entire difference across all 21 files** (113,548,734 upstream
vs 113,546,974 shipped), and every byte of it is accounted for:

| file | records differing | the whole difference |
| --- | --- | --- |
| `urd-nasai.json` | 702 | 1,725 U+00A0 (NO-BREAK SPACE) upstream where the shipped copy has a plain space |
| `urd-abudawud.json` | 3 | 3 U+00A0 |
| `ara-ibnmajah.json` | 8 | **upstream carries 16 U+FFFD replacement characters** — a broken ligature in *its* encoder — where the shipped copy holds the clean Arabic |

1,728 × 1 B (NBSP is 2 bytes in UTF-8, space is 1) + 16 × 2 B = **1,760 B, exactly**.
So: 713 records differ, **zero** of them in a way a reader can see, and in 8 of them
upstream is the *worse* copy.

### The four honesty walls, answered with measured numbers

1. **Upstream blanks stay blank** — blanks per file are identical on both sides:
   `ara-ibnmajah` 5 = 5 · `urd-abudawud` 1 = 1 · **`urd-nasai` 1,891 = 1,891**.
   Refreshing could not have filled one blank, which is why the X6 "no Urdu text here"
   line and its English-reveal chip remain the actual fix and stay wired.
2. **diff ≈ 0 is a valid result** — it is the result. Reported, not hidden.
3. **Coverage pins do not move** — `nasai/urdu` stays 3,875 / 5,765 = 67 %,
   `malik/urdu` 1,590 / 1,859 = 86 %, `bukhari/urdu` 6,994 / 7,589 = 92 %. No
   old→new transition exists because no text changed.
4. **License re-verified** — see the next sub-section.

Structural drift: **none observed.** In all three compared files the record count, the
`(hadithnumber, arabicnumber)` spine order, the `reference` values, the per-record key
set (`arabicnumber, grades, hadithnumber, reference, text`) and the whole `metadata`
object *including `sections`* are identical. Had any of those differed, this pass would
have stopped and reported instead of writing files.

**Decision: zero data churn, and the 21 JSONs stay byte-for-byte as they are.** Adopting
the "fresh" copies would import 1,728 non-breaking spaces and 16 corruption characters
to make 713 records strictly worse. The owner's rule — refresh only text fields, only
where the fresh edition carries text, spine untouched — is satisfied by this null
result, and it is the only outcome the data supports. If those 8 Ibn Majah rows are ever
wanted verbatim, the thing to fix is upstream's encoder, not our bundle.

**Size before / after: identical.** 22 files under `assets/data/hadith/` = 113,553,406 B
= 108.29 MiB (the 21 edition files above + `kitab_names.json`, 6,432 B). No edition was
added or dropped by this pass, so nothing is re-bundled and the packaged-size estimate
from the X5 measurement stands unchanged: **the APK/AAB delta of HR-2 is 0 bytes.**

**Re-verify any time** (scratch dir only; the downloads are never committed):

```bash
curl -s "https://api.github.com/repos/fawazahmed0/hadith-api/contents/editions?ref=1" \
  | python3 -c "import json,re,sys; want = re.compile(r'^(ara|eng|urd)-(bukhari|muslim|'
      r'abudawud|tirmidhi|nasai|ibnmajah|malik)\\.json$'); [print(e['name'], e['sha'], e['size'])
      for e in json.load(sys.stdin) if want.match(e['name'])]"

# the other side of every row, from this repo:
git hash-object assets/data/hadith/BUKHARI/ENGLISH.json    # …21 files
```

Equal sha ⇒ that file is current. This pass measured 18 equal, 3 unequal, and wrote the
3 off in the table above rather than shipping them.

### Upstream license re-verification (same pass)

`fawazahmed0/hadith-api` @ branch `1` carries a `LICENSE` file = **The Unlicense**
(public-domain dedication), read from the repository itself on 2026-11-14 and vendored
verbatim at `docs/hadith-upstream-unlicense.txt` (1,211 B). GitHub's SPDX detection for
the repo agrees: `Unlicense`. Stated narrowly, because the distinction matters:

- **What the dedication covers:** the edition JSON files *as that project publishes
  them* — its encodings, its joins, its metadata. Copying, modifying, selling and
  redistributing those bytes carries no condition from upstream, which is what makes
  bundling them in this repo permissible *as far as that source is concerned*.
- **What it cannot cover:** the copyright of the translators whose words the bytes carry
  (`eng-bukhari` is Muhsin Khan's translation; the Urdu editions have their own
  translators). A redistributor's public-domain dedication does not donate rights it
  does not hold.
- **So the seven hadith rows in the table at the top keep `UNKNOWN` for translation
  rights and stay `REQUIRES_PERMISSION` for any store build that treats those
  translations as cleared.** What changed is narrower and is the whole claim: the
  *source's own* terms are no longer unknown, and an in-repo license file now exists for
  them.

## Visual identity assets (2026-08-31)

Original raster art generated for Qibra (no third-party stock download). **No letters/Arabic in image files.** Arabic in the app is Amiri text, not baked into PNGs.

| Content | Source | Author | License | Commercial Use | Redistribution | Attribution | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `assets/images/logo/qibra_logo.png` | AI-generated original (this repo) | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art — not a licensed third-party mark |
| `assets/images/hero/splash_bg.png` | AI-generated original | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/hero/home_hero_bg.png` | AI-generated original | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/hero/pattern_tile.png` | AI-generated original | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/hero/empty_state.png` | Geometric PNG drawn in-repo (Pillow) | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/features/*.png` | AI-generated original | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/illustrations/onboarding_1.png` `onboarding_2.png` | AI-generated original | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/images/illustrations/onboarding_3.png` | Geometric PNG drawn in-repo (Pillow) | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art |
| `assets/icons/*.svg` | Hand-written SVG in this repo | Qibra session art | original-for-this-app | UNKNOWN | repo-only | n/a | original art — **not wired** (`flutter_svg` not in pubspec) |
| `assets/animations/*.json` | Empty-layer Lottie stubs | — | n/a | n/a | n/a | n/a | PLACEHOLDER — not used in UI |
| `assets/audio/azan_makkah.mp3` | bundled azan clip | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN — kept, not replaced |
