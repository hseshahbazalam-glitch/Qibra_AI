# Phase 6 content audit — Quran / Hadith / licensing

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `7794952` (requested `8d0309b` is **not** in this checkout; no reset).  
**Verdict: NOT APPROVED.** No license files in-repo. Flutter SDK **NOT RUN**. PostgreSQL **NOT RUN**. `content_production_ready` remains **false**.

This file was written **before** Phase 6 code edits. UNKNOWN is not converted to VERIFIED.

---

## Labels

PRESENT & WIRED | PRESENT BUT PLACEHOLDER | MISSING | BROKEN / LIKELY BROKEN | EXTRA | NOT RUN | UNKNOWN

Feature status: FOUNDATION | WIRED | FUNCTIONAL | PRODUCTION READY | BLOCKED

Content legal status (manifest only): VERIFIED | REQUIRES_PERMISSION | UNKNOWN | DO_NOT_DISTRIBUTE

---

## What this repo actually contains

| Path | Shape | Observed |
| --- | --- | --- |
| `assets/data/quran/quran_arabic.json` | alquran.cloud `{code,status,data.surahs[]}` | 114 surahs, 6236 ayahs, edition `quran-uthmani`. Ayah 1:1 starts with U+FEFF BOM. 0 empty. 0 duplicate global numbers. Ordering 1..114 and `numberInSurah` 1..n match canonical counts. |
| `assets/data/quran/translation_en.json` | same wrapper | 114/6236, 0 empty. `edition.identifier=en.asad`, `englishName=Muhammad Asad`. |
| `assets/data/quran/translation_ur_*.json` | `{quran:[{chapter,verse,text}]}` | All 6236 rows, 114 surahs, no duplicate (chapter,verse). **Tahir-ul-Qadri: 217 empty `text` fields** (incl. all of 7:1–… and 100:7–11). Other Urdu files 0 empty. |
| `assets/data/quran/surah_info.json` | `{data:[…]}` | 114 rows, ayah sum 6236. |
| `assets/data/hadith/{bukhari,muslim,abudawud,nasai,ibnmajah,malik,tirmidhi}/{arabic,english,urdu}.json` | `{metadata,hadiths[]}` | sunnah.com-like (`hadithnumber`,`text`,`grades`,`reference`). **No `tirmidhi/urdu.json`.** Record counts ≠ popular UI constants (e.g. Bukhari file 7589 vs UI 7563). Empty texts in several files (Bukhari urdu 570, Nasai urdu 1891, Muslim ar/en 203). Duplicate `hadithnumber` per file: 0. Muslim urdu: some rows missing `hadithnumber`. |
| Tafsir Ibn Kathir | — | **MISSING.** `TafseerScreen` already says verified tafsir is not bundled. No tafsir JSON/DB. |
| Word-by-word meanings | — | **MISSING.** Tokens only; gloss is `UNKNOWN`. |
| Recitation audio | — | **MISSING** / UNKNOWN. |
| Hindi translation | — | **MISSING** (honest miss via `EditionResolver`). |
| In-repo LICENSE for any of the above | — | **MISSING.** Only `docs/CONTENT_LICENSE_MANIFEST.md` stub. |

JSON was **not** rewritten. Integrity issues are recorded, not “fixed” by inventing text.

---

## Provenance of datasets (evidence in files, not guesses treated as licenses)

- Arabic: `data.edition.identifier = quran-uthmani` (Uthmani rasm). Typical CDN shape of islamic.network / alquran.cloud. **No license field.** Status: **UNKNOWN**.
- English: `en.asad` / Muhammad Asad. Named modern translation. **No license file.** Status: **REQUIRES_PERMISSION** (cannot verify redistribution/commercial bundling).
- Urdu files: translator is **filename-only** (Jalandhry, Junagarhi, Maududi, Maududi roman, Tahir-ul-Qadri, Usmani). No license, no source URL in JSON. Status: **UNKNOWN** (named living/modern translators → treat commercial bundling as **REQUIRES_PERMISSION** where the author is modern; still not VERIFIED).
- Hadith JSON: compiler names in `metadata.name` only. Edition/source URL **absent**. Looks like community hadith dumps; **do not assume MIT or sunnah.com terms**. Status: **UNKNOWN**.
- Grades inside hadith JSON are **not** independently verified. UI must not say “100% Authentic”.

Never assume public domain.

---

## RAG path (inspect)

| Piece | Status |
| --- | --- |
| `backend/app/rag.py` | Retrieval = substring match. No passage → refuse. `verified` always False. Does **not** store provenance fields today. |
| `lib/features/ai/services/rag_service.dart` | Searches local QuranRepository + HadithDatabaseService. Context says “not independently verified”. No license gate. |
| Ingest into Postgres | **Not present.** Quran/Hadith stay on-device JSON. Do not copy them into SQL. |
| Generated Islamic text inserted into DB | **Not found.** |

Production RAG eligibility: **BLOCKED** until a source is VERIFIED (requires an in-repo license file). Bundled files may be searched locally but must not be treated as production-approved.

---

## Database

User-data SQLAlchemy models have no Quran/Hadith verse tables (KEEP). Provenance belongs in a **sidecar manifest**, not a schema rewrite. Do not add Quran text to Postgres.

---

## Existing Phase 6 stubs

`docs/PHASE6_REPORT.md` / `test_phase6.py` cover last-write-wins merge and canonical 114/6236 **constants**, not live JSON license. `scripts/validate_content.py` only checks surah/ayah counts if the file exists.

---

## Planned edits (after this audit)

1. Expand validator (no JSON rewrite).  
2. Sidecar `assets/data/content_manifest.json` + Dart/Python provenance records.  
3. RAG provenance fields + production-corpus filter (VERIFIED only; currently empty).  
4. Manifest + reports.  
5. Additive pytest. Do not restyle UI. Do not enable `isBackendEnabled`. Do not set `content_production_ready` true.

**Audit status: NOT APPROVED for production distribution of bundled translations/hadith.**
