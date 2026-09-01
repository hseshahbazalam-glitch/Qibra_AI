# Qibra production inspect — 2026-08-29

**Verdict: NOT APPROVED**

This is not a store-ready build. Flutter SDK is absent in this environment, so
`flutter analyze`, `flutter test`, and release builds are **NOT RUN**. Do not
treat any feature as production-certified until those commands run on a machine
with Flutter.

Labels used below are only: PRESENT & WIRED, PRESENT BUT PLACEHOLDER / STUB,
MISSING, BROKEN / LIKELY BROKEN, EXTRA, NOT RUN, UNKNOWN.

---

## A. Flutter / Dart

| Item | Status | Evidence |
| --- | --- | --- |
| Flutter SDK on PATH | MISSING | `which flutter` empty |
| `flutter analyze` | NOT RUN | SDK missing |
| `flutter test` | NOT RUN | SDK missing |
| Android APK / iOS IPA | NOT RUN | SDK missing |
| `dart analyze` | NOT RUN | SDK missing |

---

## B. Navigation (standing override: keep 6 tabs)

| Item | Status | Evidence |
| --- | --- | --- |
| Bottom nav: Home, Quran, Hadith, Prayer, Qibla, AI | PRESENT & WIRED | `lib/shared/widgets/app_bottom_nav.dart` — Hadith **kept** |
| Continue-reading / daily ayah / surah reader as GoRouter siblings | PRESENT & WIRED | `AppRoutes` siblings, not nested under tab shell (prior work) |
| Landscape unlock | EXTRA not done | Portrait lock left as-is per override |
| gen-l10n | EXTRA not done | `AppStrings` remains; gen-l10n not enabled |

---

## C. Settings / legal / account

| Item | Status | Evidence |
| --- | --- | --- |
| Privacy Policy | PRESENT BUT PLACEHOLDER / STUB | Settings copies `https://qibra.ai/privacy`. No `url_launcher`. Live page **UNKNOWN**. |
| Terms of Service | PRESENT BUT PLACEHOLDER / STUB | Same for `https://qibra.ai/terms`. |
| Delete local account data | PRESENT & WIRED | Settings tile → `AuthNotifier.deleteAccount()`. Cloud DELETE **not** called while `AppApi.isBackendEnabled == false`. |
| Help / Rate / Share / Font size / Reciter / Translation / Profile edit | PRESENT BUT PLACEHOLDER / STUB | `_showComingSoon` |
| Reciter subtitle | PRESENT & WIRED | “Recitation not bundled” |
| About copy | PRESENT & WIRED | Not a fatwa / not a scholar. BETA chip remains. |

**FIXED this pass:** Privacy/Terms no longer say “coming soon”; they show a copy-URL dialog that states the in-app browser is not wired and live pages are unverified. Delete-local-data dialog states cloud delete needs backend.

---

## D. Auth / backend flags

| Item | Status | Evidence |
| --- | --- | --- |
| `AppApi.isBackendEnabled` | PRESENT & WIRED | `false` in `lib/core/constants/app_constants.dart` |
| Guest-first | PRESENT & WIRED | Cached profile `serverValidated` false when offline (prior work) |
| Auth network fail must not logout | PRESENT & WIRED | Prior honesty pass; Flutter **NOT RUN** so runtime **UNKNOWN** |
| `isPremium` from JSON | PRESENT & WIRED | Must not trust client JSON (prior); Flutter **NOT RUN** |
| Google / Apple / phone auth flags | PRESENT & WIRED | Set **false** this pass to match disabled backend |
| Analytics / crash / perf flags | PRESENT & WIRED | Set **false** this pass. No Firebase/Sentry/Mixpanel in this checkout. |
| `quranAudioEnabled` | PRESENT & WIRED | Set **false** this pass (recitation not bundled) |

---

## E. Quran / Hadith / Prayer / Qibla / AI

| Item | Status | Evidence |
| --- | --- | --- |
| Quran + Hadith stay free | PRESENT & WIRED | No paywall on those tabs (prior) |
| Recitation audio files | MISSING | Not bundled; UI honest |
| Licensed tafsir corpus | MISSING | Unavailable unless license file in repo |
| Word-by-word “meaning” for unknown | PRESENT & WIRED | Unknown ≠ meaning (prior) |
| Hadith missing author | PRESENT & WIRED | Shows “—” (prior) |
| Prayer math / qibla formula | PRESENT & WIRED | Not rewritten this pass |
| GPS invents city name | PRESENT & WIRED | Must not invent (prior); runtime **UNKNOWN** |
| RAG / AI | PRESENT BUT PLACEHOLDER / STUB | Retrieval assistant, not scholar; backend `/ask` exists when API on |
| Notifications | PRESENT BUT PLACEHOLDER / STUB | Local only; not reboot-proof; do not claim otherwise |

---

## F. Billing / stores / legal pages

| Item | Status | Evidence |
| --- | --- | --- |
| Play / App Store listings | UNKNOWN | URLs exist in `AppInfo`; pages not fetched as live |
| In-app billing | MISSING / unconfigured | Not store-wired in this checkout |
| Privacy/Terms live HTML | UNKNOWN | Constants only |

---

## G. Palette / a11y (prior + standing)

| Item | Status | Evidence |
| --- | --- | --- |
| Ivory / forest / gold | PRESENT & WIRED | `QibraColors`; gold fill `#C6A15B`, gold text `#6B542B` |
| Tools leftover `Colors.orange` / `Colors.white` overlays | PRESENT & WIRED | tools `Colors.orange` = 0; tools `Colors.white` = 0 this pass |
| 48dp icon taps | PRESENT & WIRED | More IconButton/InkWell 40/38 lifts; decorative 36/40 left |
| Search chips | PRESENT & WIRED | Forest/sage/goldText (prior) |

---

## H. Backend pytest (this environment)

Command: `/tmp/qibra-venv/bin/python -m pytest tests -q` from `backend/`.

**Result: 86 passed, 44 failed, 3 warnings.**

Failures cluster on **HTTP 429** (`rate_limited`) and missing headers/JSON keys after 429. In-memory `RateLimitMiddleware` is shared across the suite; `test_rate_limit_returns_429` fills the bucket, later tests then 429. **Tests were not rewritten** (standing override). This is **not** a 130/130 pass.

Health production flags in app code remain **false** (do not flip them).

CORS: not added this pass (would be EXTRA without a live web client).

---

## I. What this pass implemented (bounded)

1. Tools leftover `Colors.white` overlays → `QibraColors` text tokens (no math changes).
2. More 48dp icon taps (salah/tahajjud/stats/calendar back, ayah fav/close, asma/name-finder back, qibla copy).
3. Settings stub snackbar: “not available in this build”.
4. JWT: `.env.example` only; fallback is explicitly non-prod; tests set `JWT_SECRET`.
5. Rate-limit store reset between tests (production 60/60 unchanged).
6. Removed unused `PrayerDashboardSection` / `NightWorshipCard` (zero call sites).
7. Redacted GPS coords, LastRead surah, speech/TTS error text from `debugPrint`.

**Not done (blocked or override):** drop Hadith tab, enable gen-l10n, unlock landscape, rewrite prayer/qibla/RAG/billing/zakat formulas, claim production-ready, run Flutter.

---

## J. Re-audit verdict

**NOT APPROVED for production.**

Blockers:

1. Flutter analyze + test **NOT RUN**.
2. Store listings, live privacy/terms, billing **UNKNOWN / MISSING**.
3. Recitation not bundled; tafsir license **MISSING**.
4. Backend disabled in the app (`isBackendEnabled = false`).

Until (1) runs green on a Flutter machine, any “ready” claim is false.
