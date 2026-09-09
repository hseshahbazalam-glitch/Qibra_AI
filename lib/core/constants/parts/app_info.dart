// lib/core/constants/parts/app_info.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 1: APP INFORMATION
// ============================================================
// App ki basic identity — naam, version, tagline, links
// ============================================================

abstract final class AppInfo {
  /// App ka naam (display ke liye)
  static const String appName = 'QIBRA AI';

  /// App ka full naam
  static const String appNameFull = 'QIBRA AI — Islamic Super App';

  /// App ka tagline (onboarding, splash mein dikhega)
  static const String tagline = 'Your Complete Islamic Companion';

  /// App ka Arabic tagline
  static const String taglineArabic = 'رفيقك الإسلامي الكامل';

  /// App version — pubspec.yaml se match karna chahiye
  static const String version = '1.0.0';

  /// Build number
  static const String buildNumber = '1';

  /// Full version string
  static const String versionFull = 'v$version ($buildNumber)';

  /// Package name (Android: applicationId, iOS: bundleId)
  static const String packageName = 'ai.qibra.app';

  /// Developer/Company name
  static const String developerName = 'QIBRA Technologies';

  /// Support email
  static const String supportEmail = 'support@qibra.ai';

  /// Website URL
  static const String website = 'https://qibra.ai';

  /// Privacy Policy URL
  static const String privacyPolicy = 'https://qibra.ai/privacy';

  /// Terms of Service URL
  static const String termsOfService = 'https://qibra.ai/terms';

  /// Play Store URL
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  /// App Store URL
  static const String appStoreUrl =
      'https://apps.apple.com/app/qibra-ai/id000000000';

  /// Copyright text
  static const String copyright =
      '© 2024 QIBRA Technologies. All rights reserved.';
}
