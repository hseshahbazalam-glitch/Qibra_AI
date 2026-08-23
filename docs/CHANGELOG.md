# CHANGELOG — Qibra AI

All notable changes to the Qibra AI codebase are documented in this file.

---

## [0.6.0] — 2026-08-23 (this branch)

- Shared `QibraPage` / `QibraAppBar`; gold fill `#C6A15B`, gold text `#6B542B`, forest `#123F36`.
- Mushaf + Ayah: navy `#1A2438` / `#0A1F14` removed; 48dp ayah type; recitation not bundled.
- Search chips stay on forest/gold. Hadith unknown author is `—`.
- FastAPI 0.6.0: health, auth, users, bookmarks, sync, AI, billing.
- Phase tests `test_phase3.py` … `test_phase15.py`. See `docs/PHASE15_AUDIT.md`.

---

## [1.0.0+1] — Production Release & Hardening

### Added
- **Clean Architecture & Domain Boundaries**: Strict modular architecture separating core utilities (`lib/core/`) and features (`lib/features/`).
- **Offline-First Islamic Knowledge Engine**: Integrated local RAG (`RagService`) over authentic offline Quran and Hadith databases with verified citation enforcement.
- **Astronomical Prayer Calculation Service**: Support for high-latitude twilight methods (Angle-based, One-Seventh, Midnight), IANA timezone resolution, and Hanafi/Standard Asr shadow factors.
- **True North & Magnetic Declination Qibla Compass**: Haversine distance model and real-time declination lookup with smooth 3D needle rotation and figure-8 calibration guide.
- **Islamic Tools Suite**: Full-featured calculators and guides including:
  - Zakat Calculator with configurable and realistic silver nisab thresholds
  - Inheritance Calculator with Faraid, Awl, Radd, and Wasiyyah (capped to 1/3) rules
  - OCR Halal Ingredient Scanner with contextual false-positive filters
  - Ramadan Fasting Tracker & Countdown
  - Sadaqah, Dhikr Counter, Habit Tracker, Asma-ul-Husna, Islamic Name Finder
  - Hajj, Umrah, and Nikah interactive guides
- **Mushaf & Surah Readers**: Dual-mode Quran experience supporting Arabic scripts, multiple translation tracks (English, Urdu, Roman Urdu), and page-by-page Mushaf reader.

### Fixed & Hardened
- **CustomPainter Zero-Division Protection**: Added safety guards in `_PieChartPainter` in `inheritance_calculator_screen.dart` to prevent NaN/Infinity canvas exceptions when estate is zero or results are empty.
- **Async Gap `mounted` Guards**: Reinforced lifecycle checks (`if (!mounted) return;`) across asynchronous operations in `notification_settings_screen.dart`, `mushaf_reader_screen.dart`, `ayah_options_sheet.dart`, `forgot_password_screen.dart`, and `verify_otp_screen.dart` to eliminate `setState() called after dispose()` errors.
- **Safe Parsing in Mushaf Bookmarks**: Replaced unsafe `int.parse` with `int.tryParse` in `mushaf_reader_screen.dart` to prevent runtime crashes on corrupted bookmark data.
- **API Client Network Retry Loop Bounds**: Hardened retry condition in `api_client.dart` with `(retriesValue ?? 0) < AppApi.maxRetries`.
- **Anonymous-First Authentication**: Completely purged legacy dummy JWT generation; guest mode runs with full offline feature availability without dummy tokens.
