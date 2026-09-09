// lib/core/constants/parts/app_pagination.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 4: PAGINATION CONSTANTS
// ============================================================
// API se data page by page fetch karne ke liye
// Infinite scroll aur lazy loading ke liye zaroori
// ============================================================

abstract final class AppPagination {
  /// Default page size — ek request mein kitne items
  static const int defaultPageSize = 20;

  /// Large page size — heavy content ke liye
  static const int largePageSize = 50;

  /// Small page size — preview/widget ke liye
  static const int smallPageSize = 10;

  /// Quran ayahs per page
  static const int quranAyahsPerPage = 20;

  /// Hadith per page
  static const int hadithPerPage = 15;

  /// Dua per page
  static const int duaPerPage = 20;

  /// Chat messages per page
  static const int chatMessagesPerPage = 30;

  /// Notifications per page
  static const int notificationsPerPage = 25;

  /// Starting page number (most APIs start from 1)
  static const int firstPage = 1;

  /// Scroll threshold for triggering next page load
  /// Jab 80% scroll ho jaye tab next page fetch karo
  static const double scrollThreshold = 0.8;
}
