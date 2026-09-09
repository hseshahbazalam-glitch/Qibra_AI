// lib/core/constants/parts/app_feature_flags.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 8: FEATURE FLAGS
// ============================================================
// Feature flags = konsi features enable/disable hain
// New features ko gradually roll out karne ke liye
// A/B testing ke liye bhi use hota hai
// ============================================================

abstract final class AppFeatureFlags {
  // --- Core Features ---

  /// Is Quran feature enabled?
  static const bool quranEnabled = true;

  /// Is Prayer feature enabled?
  static const bool prayerEnabled = true;

  /// Is Hadith feature enabled?
  static const bool hadithEnabled = true;

  /// Is AI Chat feature enabled?
  static const bool aiChatEnabled = true;

  /// Is Qibla Compass enabled?
  static const bool qiblaEnabled = true;

  /// Is Tasbih Counter enabled?
  static const bool tasbihEnabled = true;

  /// Is Dua section enabled?
  static const bool duaEnabled = true;

  /// Is Islamic Calendar enabled?
  static const bool islamicCalendarEnabled = true;

  // --- Premium Features ---
  // (dead flags removed: quranOfflineEnabled and quranAudioEnabled had
  // zero references anywhere in lib/ or test/; offline downloads and
  // streaming recitation shipped for real in the audio stage and are
  // not gated by booleans.)

  /// Is AI Fatwa feature enabled?
  static const bool aiFatwaEnabled = false; // Coming soon

  /// Is AI voice input enabled?
  static const bool aiVoiceEnabled = false; // Coming soon

  // --- Social Features ---

  /// Is community feature enabled?
  static const bool communityEnabled = false; // Coming soon

  /// Is sharing enabled?
  static const bool sharingEnabled = true;

  // --- Auth Features ---

  /// Live social auth is off while AppApi.isBackendEnabled is false.
  static const bool googleAuthEnabled = false;

  static const bool appleAuthEnabled = false;

  static const bool phoneAuthEnabled = false;

  // --- Developer Options ---

  /// Show debug info in UI?
  /// MUST be false in production!
  static const bool showDebugInfo = false;

  /// Observability consent default is OFF. No Firebase/Sentry/Mixpanel wired.
  static const bool analyticsEnabled = false;

  static const bool crashReportingEnabled = false;

  static const bool performanceMonitoringEnabled = false;
}
