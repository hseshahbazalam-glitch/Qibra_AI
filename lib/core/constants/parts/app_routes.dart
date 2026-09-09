// lib/core/constants/parts/app_routes.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 11: APP ROUTES (Names)
// ============================================================
// Route names — GoRouter mein use honge (Step 10)
// Yahan sirf string constants define hain
// ============================================================

abstract final class AppRoutes {
  // --- Auth Routes ---
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String profileSetup = '/profile-setup';
  // --- Main Routes ---
  static const String home = '/home';
  static const String quran = '/quran';
  static const String prayer = '/prayer';
  static const String hadith = '/hadith';
  static const String aiChat = '/ai-chat';

  // --- Sub Routes ---
  static const String surahReader = '/quran/reader';
  static const String quranSearch = '/quran/search';
  static const String mushafReader = '/quran/mushaf';
  static const String continueReading = '/quran/continue-reading';
  static const String dailyAyah = '/quran/daily-ayah';

  static const String qibla = '/prayer/qibla';
  static const String mosques = '/prayer/mosques';
  static const String prayerSchedule = '/prayer/schedule';
  static const String prayerStatistics = '/prayer/statistics';
  static const String tahajjud = '/prayer/tahajjud';

  static const String dua = '/dua';
  static const String duaDetail = '/dua/detail';

  static const String tasbih = '/tasbih';
  static const String tools = '/tools';
  static const String islamicCalendar = '/calendar';

  // --- User Routes ---
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String more = '/more';
  static const String bookmarks = '/bookmarks';
  static const String zakat = '/tools/zakat';
  static const String inheritance = '/tools/inheritance';
  static const String habits = '/tools/habits';
}
