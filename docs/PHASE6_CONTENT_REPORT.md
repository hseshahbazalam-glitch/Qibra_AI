# Phase 6 content report — validation + licensing

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Requested HEAD `8d0309b`:** not in this checkout. Work continued from `7794952`.  
**Status:** WIRED for integrity tests. Legal clearance **BLOCKED**. **Not production-ready.**

---

## 1. Git commit

Recorded after this report is committed (see final user summary).

## 2. Files changed

Audit + sidecar manifest + validator + RAG provenance fields + additive tests + docs. No Quran/Hadith JSON rewrite. No UI restyle. `isBackendEnabled` false. `content_production_ready` false.

## 3. Quran records verified (integrity, not license)

- Arabic `quran-uthmani`: **114 surahs, 6236 ayahs**, order 1..114, `numberInSurah` sequential, 0 empty, 0 duplicate global numbers.
- BOM on 1:1: **1** ayah (recorded).
- Many ayahs are not NFC-equal to NFC normalize (Uthmani combining marks). Not rewritten.

## 4. Hadith records verified (integrity, not license)

| Collection | arabic | english | urdu |
| --- | ---: | ---: | ---: |
| bukhari | 7589 | 7589 | 7589 |
| muslim | 7563 | 7563 | 7564 |
| abudawud | 5274 | 5274 | 5274 |
| nasai | 5765 | 5765 | 5765 |
| ibnmajah | 4343 | 4343 | 4343 |
| malik | 1858 | 1858 | 1889 |
| tirmidhi | 3998 | 3998 | **missing file** |

Duplicate `hadithnumber` per present file: 0. Empty texts: present (not filled). UI `popularHadithBooks` counts differ from files — not silently “fixed”.

## 5. Translation sources

- English: JSON edition `en.asad` / Muhammad Asad.
- Urdu: filename-only (Jalandhry, Junagarhi, Maududi, Maududi roman, Tahir-ul-Qadri, Usmani).
- Hindi: not bundled.

## 6. Tafsir sources

Ibn Kathir: **not bundled**. Screen already reports unavailability. Status **DO_NOT_DISTRIBUTE** until a licensed edition exists.

## 7. License status of every source

See `docs/CONTENT_LICENSE_MANIFEST.md`. No row is VERIFIED.

## 8. Unknown / unverified sources

All bundled JSON except English Asad (REQUIRES_PERMISSION) and tafsir (DO_NOT_DISTRIBUTE). No in-repo license files.

## 9. RAG provenance status

- Local retrieve still substring-only; `verified` always False.
- Hits now carry provenance metadata.
- `production_corpus()` keeps only VERIFIED rows → currently empty → production answer refuses.
- No Islamic text generated into the database.

## 10. Tests executed

- `/tmp/qibra-venv/bin/python -m pytest tests -q` from `backend/` (see run below).
- `scripts/validate_content.py` (see run below).

## 11. Tests not executed and why

- Flutter analyze / `flutter test`: SDK absent → **NOT RUN**.
- PostgreSQL: no server → **NOT RUN**.
- Store / legal counsel review: **NOT RUN**.

## 12. Production blockers

1. No license files.  
2. Asad translation REQUIRES_PERMISSION.  
3. Tahir-ul-Qadri 217 empty verses.  
4. Hadith empty rows + missing Tirmidhi Urdu.  
5. `content_production_ready` false.  
6. Flutter/Postgres untested here.

## 13. Security / legal risks

Bundling named modern translations and hadith English/Urdu dumps without a written license may be **copyright-restricted**. This report does not authorize store distribution. Do not log Quran/Hadith text.

## 14. Exact next recommended phase

Obtain written licenses (or replace with clearly licensed corpora) **before** any store release. Next product phase after that remains connected-backend e2e — not a content rewrite.
