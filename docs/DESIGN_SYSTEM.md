# Qibra design system — Family A

Identity is ivory / forest / gold. Do **not** switch to midnight+emerald. Do **not** gold-wash type. Gold FILL is not body text.

## Color

| Token | Hex | Use |
| --- | --- | --- |
| Ivory / card | `#FEFDF9` | Surfaces, cards |
| Canvas | `#F5F3EC` | App background |
| Forest | `#123F36` | Primary fill, filled cards, nav selected |
| Sage | `#2F6B5D` | Secondary / success / chips |
| Gold FILL | `#C6A15B` | Icons, borders, small fills only |
| Gold TEXT | `#6B542B` | Captions, section labels, Arabic display captions |
| Ink | `#19312C` | Body / titles on ivory |
| Danger | `#B42318` | Error, destructive, BETA badge |
| Border | `#E4E0D5` | Hairlines |

Source of truth in code: `lib/core/design_system/qibra_colors.dart` (`QibraColors.of(context)`). Parallel `AppColors` exists for compile; prefer `QibraColors`. Dark palette is forest-night, not navy.

Search chips: forest / sage / gold TEXT only.

## Typography

- Latin: Inter (`GoogleFonts.inter`) via `AppTextStyles`.
- Arabic: Amiri via `AppArabicStyles`. Scripture is **not** translated with `_t()`.
- Styles do **not** bake light ink except `inputError` (`AppColors.error`). Call sites `copyWith(color: QibraColors.of(context).…)`.
- Gold TEXT extension: `#6B542B`. Gold FILL is not a type color.

## Spacing & radius

`AppSpacing` 4px grid. Common card radius 16–20. Do not invent a new grid.

## Chrome

- Shared: `QibraPage` / `QibraAppBar` / `QibraCard` / `QibraChip` / `QibraStatus`.
- Six-tab bar kept (Home, Quran, Prayer, Hadith, AI, More). Portrait only.
- Back icon follows `Directionality`. Icon buttons 48dp (`AppA11y.minTapTarget`).
- Do not clamp `MediaQuery.textScaler`. Do not enable gen-l10n.

## Motion

Calm fades. Splash particles are decorative and reduced. Respect reduced-motion is **not** wired (UNKNOWN / NOT RUN).

## Honesty

Recitation not bundled. Tafsir unavailable unless licensed. AI is retrieval only — not a fatwa. UNKNOWN stays UNKNOWN.
