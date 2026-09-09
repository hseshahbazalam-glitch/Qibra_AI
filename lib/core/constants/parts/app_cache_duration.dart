// lib/core/constants/parts/app_cache_duration.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 7: CACHE DURATIONS
// ============================================================
// Data kitne time tak cached/stored rahega
// Cache se data fast milta hai (no API call needed)
// ============================================================

abstract final class AppCacheDuration {
  /// Prayer times cache — 1 day
  /// Prayer times daily change hote hain
  static const Duration prayerTimes = Duration(hours: 24);

  /// Quran surahs list cache — 30 days
  /// Quran data rarely change hota hai
  static const Duration quranSurahs = Duration(days: 30);

  /// Quran ayahs cache — 30 days
  static const Duration quranAyahs = Duration(days: 30);

  /// Hadith collections cache — 7 days
  static const Duration hadithCollections = Duration(days: 7);

  /// Daily hadith cache — 1 day
  static const Duration dailyHadith = Duration(hours: 24);

  /// Dua list cache — 7 days
  static const Duration duaList = Duration(days: 7);

  /// User profile cache — 1 hour
  static const Duration userProfile = Duration(hours: 1);

  /// Prayer method list cache — 30 days
  static const Duration prayerMethods = Duration(days: 30);

  /// Islamic events cache — 1 day
  static const Duration islamicEvents = Duration(hours: 24);

  /// Hijri date cache — 1 hour
  static const Duration hijriDate = Duration(hours: 1);

  /// Search results cache — 30 minutes
  static const Duration searchResults = Duration(minutes: 30);

  /// AI chat history cache — 1 hour
  static const Duration aiChatHistory = Duration(hours: 1);

  /// Location cache — 30 minutes
  static const Duration location = Duration(minutes: 30);

  /// Notifications cache — 15 minutes
  static const Duration notifications = Duration(minutes: 15);
}
