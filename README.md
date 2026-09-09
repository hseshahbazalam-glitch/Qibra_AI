# Qibra AI

An offline-first Islamic companion: Quran (text + tafsir + word-by-word),
the seven major hadith collections in 7 languages, prayer times with a
fully local calculation stack, duas, tasbih, hijri calendar — **zero
trackers, zero ads, zero accounts required**. Integrity over
completeness: unavailable data is displayed as unavailable, never faked.

Start here: [`ARCHITECTURE.md`](ARCHITECTURE.md) ·
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) ·
[`lib/core/design_system/DESIGN_SYSTEM.md`](lib/core/design_system/DESIGN_SYSTEM.md)

## Project structure

```
lib/main.dart                    entry — runApp-first boot (see ARCHITECTURE)
lib/core/router/                 single GoRouter (44 routes)
lib/features/<feature>/          17 features, each:
    data/        models · services · repository   (pure Dart)
    providers/   Riverpod state — the only layer widgets watch
    presentation/ screens and sheets
lib/core/<module>/               19 shared modules (network, sync, offline,
                                 design_system, l10n, search utils, …)
lib/shared/{widgets,utils}       cross-feature building blocks
assets/data/                     bundled corpora + content_manifest.json
test/features/<feature>/, test/core/   mirror of lib/ — pin + unit tests
scripts/static_battery.py        the repo's own static-analysis gates
.github/workflows/ci.yml         CI: analyze → full suite → battery
```

## Development

Requires Flutter (CI pins `3.44.6`).

```sh
flutter pub get
flutter run                                   # device
flutter analyze --no-fatal-infos              # gate: 0 errors, 0 warnings
flutter test                                  # gate: full suite
python3 scripts/static_battery.py             # gate: "hard findings: 0 | …"
```

A `.env` at the repo root is loaded in debug builds (optional — the app
degrades honestly without it; release builds never bundle it).

## CI

One workflow (`.github/workflows/ci.yml`), one job, three sequential
gates on every push: `flutter analyze --no-fatal-infos` (infos are a
sanctioned debt — errors/warnings are not), the full `flutter test`
suite, and `scripts/static_battery.py` — a repo-authored static analyzer
whose hard findings must be zero (it also publishes `::error`/`::notice`
workflow annotations, so findings are machine-readable in the API).
The three-count battery summary line is reported verbatim in every
pass report — the project's report rule.
