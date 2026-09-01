# Qibra design system — Midnight Navy (product-owner override, approved)

> **Override note.** The previous "dark-first emerald" identity (`bg_canvas #071512`
> etc.) is **stale**. The product owner approved a **midnight NAVY** global brand:
> deep navy surfaces + emerald (action/prayer) + purple (AI) + gold (sacred accent).
> Source of truth: `lib/core/design_system/qibra_navy.dart` (`QibraNavy`).
> `QibraColors.dark`, `QibraColorsNext.dark`, `AppColorsDark` and `AppTheme.dark`
> all derive from it, so hex values cannot drift apart.

## Color

| Token | Hex | Use |
| --- | --- | --- |
| canvas | `#020B14` | App background |
| surface | `#04111C` | Nav, sheets |
| card | `#071B28` | Cards |
| cardElevated | `#0A2536` | Hero / pressed / modals |
| hairline | `#143045` | Thin borders |
| emerald | `#2ED39A` | Actions, progress, next prayer, success |
| emeraldDeep | `#0E9F6E` | Gradient stops, fills |
| violet | `#9B6CFF` | AI only (QIBRA AI, AI CTA, AI tab) |
| violetDeep | `#6C3CE6` | AI gradient stop |
| gold | `#D9B26A` | Islamic highlights, sacred accents (sparse) |
| goldBright | `#F2D98F` | Gold **text** on navy |
| blue | `#5EA2FF` | Information, search, hadith states |
| cyan | `#43D6E8` | Secondary info |
| orange | `#FF9C4F` | Warnings, streaks (rare) |
| red | `#E5484D` | Errors / destructive only |
| textPrimary | `#ECF3FA` | Titles, body |
| textSecondary | `#A6BACD` | Captions |
| textMuted | `#71869B` | Hints |

Ratio: ~60–70% navy surfaces, 15–20% emerald, 8–12% violet, 5–8% gold.
Color communicates meaning; decoration is restrained.

## Contrast floor (WCAG)

- `textPrimary` on `canvas` ≈ 17:1 (AAA)
- `textSecondary` on `card` ≈ 8.8:1 (AAA)
- `textMuted` on `card` ≈ 4.7:1 (AA)
- `emerald` / `violet` / `goldBright` on navy ≥ 4.5:1 (AA)

## Chrome

- Six tabs kept (standing contract): Home, Quran, Prayer, Hadith, AI, More.
- Active tab: emerald; AI tab: violet; indicator hairline + label weight —
  never color alone.
- Portrait only. Icon buttons 48dp. No gen-l10n in this stage.
- Home hero uses a vector night-sky backdrop (`QibraNightSkyBackdrop`), no
  looping animation (reduced-motion safe).

## Honesty (unchanged, reinforced)

- **No invented weather.** Location + Hijri date are shown instead; weather stays
  out until a real source is wired.
- **No fake audio player.** "Listen" UI appears only if recitation is bundled;
  until then the honest "Recitation not bundled" pattern is the only allowed state.
- No invented streaks, GPS cities, or "100% Authentic" — grades show their
  qualifier (`Sahih (collection grade, not independently verified)`).
- AI is retrieval only — not a fatwa; every claim needs a traceable source.

## Legacy

`QibraColors.light` (ivory Family A) remains for compile/migration only.
`AppEmerald`/`AppGold` light-mode scales are unchanged.
