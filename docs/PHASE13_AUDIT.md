# Phase 13 audit — Accessibility + internationalization

**Date:** 2026-08-31  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `3d0bf12`  
**Written before implementation.**

**Verdict:** Foundation exists (`AppA11y`, `AppLocales`, `AppStrings`, `localeProvider`) but **MaterialApp is not wired** to locale/delegates/RTL. gen-l10n must stay **off**. Do not restyle UI (Phase 14). Do not clamp `textScaler`. Do not translate Quran/Hadith source text.

Flutter SDK **NOT RUN**. Device / TalkBack / VoiceOver **NOT RUN**.

---

## 1. Accessibility

| Item | Status |
| --- | --- |
| `AppA11y.minTapTarget` = 48 | PRESENT |
| `AppSemanticIconButton` | PRESENT, barely used |
| Bottom nav height 68, 6 tabs | PRESENT; labels hardcoded English; no `Semantics` |
| IconButton count ~65 | Most lack `tooltip` / semantic label |
| `textScaler` | **Not clamped** (KEEP) |
| Contrast tokens | `Contrast.goldText` `#6B542B`; gold fill not body text |
| Auth buttons | Some `Semantics` |
| Focus / keyboard | Not audited on device |
| Decorative images | `SafeImage` custom painters — extra a11y nodes possible |

**Do not** mass-restyle screens to add 48dp padding everywhere (layout change → Phase 14). Safe: nav semantics, tap-target helper already on `qibra_ui` app bar.

---

## 2. Internationalization

| Item | Status |
| --- | --- |
| Locales en / ar / ur | PRESENT in `AppLocales` + `AppLanguages` |
| `localeProvider` persisted | PRESENT |
| Quran translation vs UI vs Hadith language | Independent (KEEP) |
| `AppStrings` hand-written | Partial chrome only |
| `MaterialApp.locale` / `supportedLocales` / delegates | **MISSING** — `AppLocales` imported in `main.dart` unused |
| `AppStringsScope` | Unused in tree |
| `flutter_localizations` | **not** in pubspec (SDK dep allowed; gen-l10n not) |
| `generate: true` | Absent (KEEP absent) |
| RTL `AppLocales.isRtl` | Defined; MaterialApp never applies it |
| Hardcoded nav: Home/Quran/Prayer/Hadith/AI/More | English only |
| Quran/Hadith JSON | Must remain source text; never run through `_t()` |

Hindi / unbundled editions stay honest misses.

---

## 3. UI text safety

Bottom nav already `FittedBox` + `maxLines: 1` (long ar/ur labels). Many screens still English-only; translating all copy would be a redesign. **Out of scope** except chrome we already have (`AppStrings`) + nav labels.

---

## 4. Contract risks

| Change | Risk |
| --- | --- |
| Enable gen-l10n | **STOP** — standing ban |
| Clamp text scale | **STOP** |
| Drop a tab / unlock landscape | **STOP** |
| Translate ayah/hadith bodies | **STOP** |
| Wire MaterialApp locale | Safe — existing `localeProvider` |
| Localize 6 nav labels via `AppStrings` | Safe — same 6 tabs, no color/layout change |
| Add `flutter_localizations` SDK | Safe |

---

## 5. Privacy / performance

No new analytics. No logging of user/Quran/Hadith/AI/GPS. No extra network. No second corpus load.

---

## 6. Plan after this audit

1. Add `flutter_localizations` (SDK).  
2. Wire `locale`, delegates, `AppStringsScope`; do not clamp scaler.  
3. Nav labels + `Semantics` (selected/button).  
4. Tests: RTL, 48dp, strings, gold text, no gen-l10n.  
5. Leave Home/Quran/Hadith layouts, prayer math, billing, observability.
