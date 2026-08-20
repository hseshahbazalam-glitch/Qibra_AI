# QIBRA AI — ENGINEERING BIBLE

## 1. ARCHITECTURAL PRINCIPLES
Qibra AI follows Clean Architecture combined with Feature-Driven Development, MVVM, and Riverpod State Management:

```
lib/
├── core/                   # Shared foundations & framework
│   ├── constants/          # Fixed app constants & asset registry
│   ├── design_system/      # Typography, colors, spacing, theme tokens
│   ├── network/            # ApiClient (centralized Dio layer)
│   ├── providers/          # Global Riverpod providers (theme, auth, storage)
│   ├── router/             # GoRouter routes and route guards
│   └── services/           # System-wide services (notifications, calculations)
├── features/               # Feature domain modules
│   ├── ai/                 # AI Explain, local RAG, voice services
│   ├── auth/               # Anonymous-first auth, guest mode, credentials
│   ├── calendar/           # Hijri & Gregorian synchronizer
│   ├── duas/               # Masnoon supplications & offline catalog
│   ├── hadith/             # Hadith collections & local search index
│   ├── home/               # Central executive dashboard
│   ├── onboarding/         # First-run experience
│   ├── prayer/             # Astronomical prayer calculations & tracker
│   ├── qibla/              # Magnetic & true north compass
│   ├── quran/              # Surah reader, Mushaf page viewer, search
│   ├── settings/           # App preferences & notifications
│   ├── splash/             # Startup sequence & initialization
│   ├── tasbih/             # Digital Tasbih counter
│   └── tools/              # Islamic calculators & guides
└── shared/                 # Reusable cross-feature UI widgets
```

---

## 2. STATE MANAGEMENT & DATA FLOW
- **ProviderScope**: Root of the application.
- **StateNotifier / Notifier**: Used for stateful domains (Auth, Theme, Locale, Reading Progress, Audio).
- **FutureProvider / StreamProvider**: Used for async initialization and hardware sensor streams (Connectivity, Geolocator, Compass).
- **Zero Dummy Synchronous Storage**: Always resolve `SharedPreferences` asynchronously via `sharedPreferencesProvider.future`.
- **Selector Precision**: Always use `ref.watch(provider.select(...))` in UI build methods where practical to minimize rebuild cycles.

---

## 3. UI/UX & DESIGN SYSTEM RULES
- **Dark Emerald + Royal Gold Identity**: Background (`#020A08`), Emerald Accent (`#00A86B` / `#00E676`), Royal Gold (`#D4AF37`).
- **Typography**: Always utilize typography tokens from `AppTextStyles` and `AppTypography`.
- **4px Spacing Grid**: Always apply `AppSpacing` tokens (`AppSpacing.xs`, `sm`, `md`, `lg`, `xl`, etc.).
- **Async UI Safety**: Always verify `if (!mounted) return;` after `await` calls in `StatefulWidget` states before triggering `setState()`, `ScaffoldMessenger`, or `Navigator`.

---

## 4. RELIABILITY & CALCULATION ACCURACY
- **Astronomical Prayer Calculations**: Calculations must handle extreme latitudes gracefully via high-latitude twilight fallback algorithms.
- **Qibla Geometry**: True-north bearings computed using great-circle trigonometry relative to Kaaba coordinates (`21.3891° N, 39.8579° E`).
- **Islamic Inheritance & Zakat**: Strictly adheres to classical Faraid rules (Awl proportional adjustments, Radd residual distributions, Wasiyyah $\le 1/3$ constraint) and current realistic silver nisab baselines.
