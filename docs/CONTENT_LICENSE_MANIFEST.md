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
| Jami at-Tirmidhi JSON | `assets/data/hadith/tirmidhi/` (no urdu.json) | Imam al-Tirmidhi (compiler); translators UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |
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
