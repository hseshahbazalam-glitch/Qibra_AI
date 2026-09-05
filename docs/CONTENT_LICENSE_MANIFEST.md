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
