# Content provenance

Metadata fields used in the sidecar (`assets/data/content_manifest.json`) and RAG hits:

`source_id` · `source_name` · `collection` · `edition` · `translator` · `license` · `license_url` · `copyright_status` · `attribution_required` · `verified_at` · `verification_status`

Quran/Hadith **text stays on-device**. It is not copied into Postgres.

| Id | Source | Trust / status |
| --- | --- | --- |
| quran_arabic_uthmani | assets/data/quran/quran_arabic.json | bundled / UNKNOWN |
| quran_en_asad | assets/data/quran/translation_en.json | bundled / REQUIRES_PERMISSION |
| urdu editions | assets/data/quran/translation_ur_*.json | bundled / UNKNOWN |
| hadith_* | assets/data/hadith/ | bundled / UNKNOWN |
| tafsir_ibn_kathir | not bundled | DO_NOT_DISTRIBUTE |
| recitation audio | not bundled | UNKNOWN |
| Hindi translation | not bundled | UNKNOWN |
| word-by-word gloss | not bundled | UNKNOWN |

Integrity (not a license grant):

- Arabic: 114 surahs / 6236 ayahs, ordered, 0 empty, 0 duplicate global ids. Ayah 1:1 has a U+FEFF BOM (recorded, not stripped).
- English Asad: 6236 ayahs, 0 empty.
- Urdu: 6236 rows each. Tahir-ul-Qadri has **217 empty texts** (not invented).
- Hadith: no duplicate `hadithnumber` in present files. Empty texts exist. `tirmidhi/urdu.json` missing.

Never invent VERIFIED. Never claim "Verified Qibra sources". RAG `verified` is always false. Production RAG accepts only `verification_status=VERIFIED` (currently none).
