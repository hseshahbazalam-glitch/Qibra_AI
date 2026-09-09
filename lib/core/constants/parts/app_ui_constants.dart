// lib/core/constants/parts/app_ui_constants.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 9: UI CONSTANTS
// ============================================================
// UI se related fixed values jo design system mein
// nahi hain lekin app mein commonly use hote hain
// ============================================================

abstract final class AppUIConstants {
  // --- Animation ---

  /// Standard page transition duration
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Shimmer animation duration
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  /// Splash screen duration
  static const Duration splashDuration = Duration(milliseconds: 3000);

  /// Snackbar display duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Toast display duration
  static const Duration toastDuration = Duration(seconds: 2);

  /// Debounce duration (search input)
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // --- Sizes ---

  /// Standard avatar size
  static const double avatarSize = 48.0;

  /// Large avatar size (profile screen)
  static const double avatarSizeLarge = 96.0;

  /// Small avatar size (list items)
  static const double avatarSizeSmall = 32.0;

  /// Standard icon button tap area (min 48×48 for accessibility)
  static const double tapTargetSize = 48.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Standard button height
  static const double buttonHeight = 52.0;

  /// Standard input field height
  static const double inputHeight = 52.0;

  /// Minimum card height
  static const double cardMinHeight = 80.0;

  /// Prayer card height
  static const double prayerCardHeight = 120.0;

  /// Feature card height
  static const double featureCardHeight = 140.0;

  // --- Limits ---

  /// Maximum lines for description text
  static const int descriptionMaxLines = 3;

  /// Maximum lines for card subtitle
  static const int cardSubtitleMaxLines = 2;

  /// Maximum AI chat messages shown at once
  static const int maxVisibleChatMessages = 50;

  /// Maximum recently read surahs shown
  static const int maxRecentSurahs = 5;

  // --- Map ---

  /// Default map zoom level
  static const double defaultMapZoom = 15.0;

  /// Nearby mosque search radius (meters)
  static const double mosqueSearchRadius = 5000.0;
}
