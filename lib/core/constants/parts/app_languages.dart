// lib/core/constants/parts/app_languages.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 10: SUPPORTED LANGUAGES
// ============================================================

abstract final class AppLanguages {
  /// English
  static const String english = 'en';

  /// Arabic
  static const String arabic = 'ar';

  /// Urdu
  static const String urdu = 'ur';

  /// Default language
  static const String defaultLanguage = english;

  /// All supported languages
  static const List<String> supported = [english, arabic, urdu];

  /// Language display names
  static const Map<String, String> displayNames = {
    english: 'English',
    arabic: 'العربية',
    urdu: 'اردو',
  };
}
