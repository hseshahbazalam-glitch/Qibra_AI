# Qibra AI — Conventions

Practical rules for touching this repo. The "why" behind most of them is
in [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (quality system) and the
CI file itself.

## Naming & file layout

- Screens: `lib/features/<feature>/presentation/<feature>_screen.dart`
  (detail surfaces ride as `<feature>_book_screen.dart` style siblings).
- One pass = one pin file in `test/` mirroring the lib tree:
  `test/features/<feature>/<name>_test.dart`, `test/core/<name>_test.dart`
  (organized 2026-09-08 — files were *moved*, never renamed; pin names
  are quoted by CI history, keep them stable).
- **Part files are SANCTIONED for genuinely large screens** — a
  `part`/`part of` split keeps private state shared without creating a
  public API. Rule (Phase C, 2026-09-08): **dot-free names**, one
  concern per part file, named `<screen>_<concern>.dart`. The four
  sanctioned parts (renamed from the legacy dot-form this pass):
  `profile_setup_form.dart`, `tasbih_detail.dart`,
  `asma_ul_husna_learn.dart`, `inheritance_results.dart` — parents hold
  the matching `part '...'` directive. New dot-part files
  (`<screen>.<part>.dart`) remain forbidden.

## Import policy (going forward)

- Cross-feature and cross-layer references use **`package:qibra_ai/…`**
  imports (192 exist today; they are pin-robust against folder moves).
- **Relative imports are allowed only *within* one feature folder**
  (`../providers/…` inside `features/hadith/` etc.). The 280 legacy
  `'../'`-style imports elsewhere are Phase-C cleanup, **not** a target
  state — do not add to the count, do not mass-migrate opportunistically.
- Never import `features/*` from `core/*` or `shared/*` (layering;
  battery flags reverse edges).

## Constants — the parts pattern

`lib/core/constants/app_constants.dart` is a library root; each
`abstract final class` group lives in `parts/app_<class>.dart`. **New
constants join the owning class's part file — no new top-level constants
files, no new classes in the root.** Call sites keep the single public
import (`package:qibra_ai/core/constants/app_constants.dart`). Source-pin
caveat: a pin asserting a constant's TEXT must point at the PART file
holding it (the root no longer contains class bodies).

## Design tokens

- **Navy single-source:** `lib/core/design_system/qibra_navy.dart`
  (light/dark pair in `qibra_colors.dart` resolves via `QibraColors.of`).
- Gold is an accent budget: ≤5–8% of any screen's visible ink.
  Violet is **AI-surface-only** (explain flow) — nowhere else.
- **No `Color(0x…)` literals in screens/widgets** — tokens or theme
  colors only (several battery G-gates + pin tests scan for this).
- Fonts are **bundled only** (`Inter`, `Amiri` via pubspec `fonts:`);
  nothing may reintroduce a runtime CDN font (main.dart header comment).
- Images: `SafeImage` with the cacheWidth rules; no `Opacity(`/
  `ColorFiltered` wrappers on large subtrees, no `saveLayer`-inducing
  decoration on list rows (perf pins — see `test/core/perf_pass_test.dart`).

## Testing conventions

- **Prefer pure functions:** logic worth pinning gets extracted to a
  static/top-level pure (`@visibleForTesting` when lib-side) and unit-
  tested directly — `neighbourNumber`, `hadithPositionLabel`,
  `hadithHighlightSpans`, `todayIndexFor`, `applyRecent`… precedents.
- **Fixtures only:** no network, no real corpus files in unit tests;
  widget tests pump minimal compositions at 320/360dp when overflow is
  the risk under test (`test/features/hadith/hadith_redesign_test.dart`).
- **Negative pins go comment-blind:** use
  `test/support/source_guards.dart → stripCommentsForGuard` when
  asserting an absence (the 2026-09-08 'View details' incident is the
  cautionary tale); positive pins may read the raw file.
- Source pins: every lib file a test reads is referenced by its full
  path string; moving lib files = updating pins in the SAME commit.
- The singleton caution: tests that swap global seams (e.g.
  `RagService.attachHadithDb`) must restore pristine state in `tearDown`
  — Riverpod containers in tests never leak app-wide providers.

## Commit messages

Conventional-style, scoped, ledger-consistent:
`feat|fix|test|perf|chore(ci)|docs(<scope>): <imperative summary ≤72ch>`
+ body with the *why* (CI run ids, owner rulings and incidents are
cited inline where relevant — the history doubles as the design log).
Small logical commits; a multi-item pass lands as one commit per item
or per layer, never one giant blob.

## Gates before pushing

```sh
flutter analyze --no-fatal-infos     # 0e / 0w (infos sanctioned)
flutter test                         # full suite
python3 scripts/static_battery.py    # must print: hard findings: 0 | …
```
Report battery results as the verbatim three-count line; never paraphrase.
