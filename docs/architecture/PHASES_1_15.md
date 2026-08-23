# Qibra AI — Phases 1 to 15 on the existing project

This branch restores the Phase 1–15 product on the existing Qibra AI
repository. It does not start a second app.

| Phase | Area | Where it lives |
| --- | --- | --- |
| 1 | App shell, theme, navigation | `lib/main.dart`, `lib/core/` |
| 2 | Anonymous-first auth + secure storage | `lib/core/providers/auth_provider.dart` |
| 3 | Home dashboard | `lib/features/home/` |
| 4 | Prayer times, IANA zones, high-latitude | `lib/features/prayer/` |
| 5 | Qibla | `lib/features/qibla/` |
| 6 | Quran corpus + readers | `lib/features/quran/`, `assets/data/quran/` |
| 7 | AI client + local RAG, backend proxy path | `lib/features/ai/`, `POST /api/v1/ai/chat` |
| 8 | Hadith corpus | `lib/features/hadith/`, `assets/data/hadith/` |
| 9 | Duas | `lib/features/duas/` |
| 10 | Tafsir screen (no fabricated corpus) | `lib/features/tafseer/`, `GET /api/v1/tafsir` |
| 11 | Tools (zakat, fara'id, halal, ramadan) | `lib/features/tools/` |
| 12 | Settings, profile, notifications | `lib/features/settings/` |
| 13 | FastAPI contract backend | `backend/` |
| 14 | Docs + automated tests | `docs/`, `test/`, `backend/tests/` |
| 15 | Family space (local-first) | `lib/features/family/` |

The HTTP surface remains exactly the paths in `docs/api/API_CONTRACT.md`.
