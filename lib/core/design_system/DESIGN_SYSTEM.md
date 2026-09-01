# Qibra AI design system

Warm ivory, deep forest, sage, and champagne gold. Light is the primary identity. Dark is a forest-night variant, not neon.

## Palette (Family A)

| Role | Hex | Use |
| --- | --- | --- |
| Background | `#F5F3EC` | Screen canvas |
| Card / ivory | `#FEFDF9` | Surfaces |
| Surface | `#EEF1EA` | Soft panels |
| Primary / forest | `#123F36` | Actions and type |
| Secondary / sage | `#2F6B5D` | Support |
| Accent gold (hairline only) | `#C6A15B` | Thin gold — never a fill for body chrome |
| Gold TEXT | `#6B542B` | Readable gold labels |
| Text | `#19312C` / `#4A5A54` | Primary / muted |
| Border | `#E4E0D5` | Hairline dividers |
| Danger | `#B42318` | Stop / delete / error |

Hierarchy: about 70% ivory and white, 20% forest and sage, 10% gold.

Do **not** remint gold fill `#C6A15B` as a solid button or screen fill. Gold TEXT is `#6B542B`.

Do **not** use navy `#0A1F14`, `#1A2438`, `#141926` or rainbow `#EC407A`, `#7E57C2`, `#42A5F5`.

Do not clamp `textScaler`. Do not unlock landscape. Do not drop a tab. Do not enable `gen-l10n`.

## Type

- English UI: Inter
- Arabic: Amiri
- Generous line height, quiet labels

## Components

- `QibraPage` — ivory canvas, loading / empty / error / offline / retry
- `QibraAppBar` — 48dp tap targets
- Cards: ivory, 20px radius, 1px border
- Primary buttons: forest fill, ivory label
- Stop / delete: danger `#B42318`, 48dp

## Data honesty

Use existing providers. If a value is unknown, show loading, empty, or `—`. Do not invent prayer times, weather, streaks, mosque names, recitation audio, or authenticity labels.
