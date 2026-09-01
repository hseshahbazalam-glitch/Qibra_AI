# Phase 13 report — Accessibility + i18n

Status: **WIRED** for chrome locale + 48dp token. Not production-ready. Flutter analyze/test **NOT RUN** (SDK not on PATH). Device/Postgres/Redis **NOT RUN**.

## What landed

- `flutter_localizations` SDK dependency. **No** `generate: true` / gen-l10n.
- `MaterialApp.router` now sets `locale`, `supportedLocales` (en/ar/ur), Material/Cupertino/Widgets delegates, `localeResolutionCallback` → `AppLocales.resolve`, and `AppStringsScope`.
- **No** `MediaQuery.textScaler` clamp.
- Bottom nav: **six tabs kept**. Labels from `AppStrings` (`navHome` … `navMore`). Semantics `button` + `selected` + `label`.
- 404 chrome strings via `AppStrings`. Quran/Hadith **source text is not** wrapped in `_t()`.
- Gold TEXT remains `#6B542B`. Gold FILL not used as body text. `AppA11y.minTapTarget` stays **48**. Portrait-only unchanged.

## Honesty

- Quran/Hadith/tafsir/prayer/qibla/authenticity/user stats are never invented.
- Recitation not bundled. Tafsir unavailable unless licensed.
- Unbundled editions (e.g. Hindi) stay honest misses.
- ~65 IconButtons still mostly unlabeled — not mass-restyled this phase.
- Independent: UI locale vs Quran translation vs Hadith language.

## Tests

- Flutter: `test/phase13_test.dart`, `test/phase13_a11y_l10n_test.dart` — **NOT RUN**.
- Backend: `backend/tests/test_phase13.py` (bookmarks) + `backend/tests/test_phase13_i18n.py` (contracts).

## Out of scope (not done)

- gen-l10n, dropping a tab, landscape unlock, Home restyle, translating ayah/hadith, mass 48dp restyle.
