// lib/core/constants/parts/app_storage_keys.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 3: LOCAL STORAGE KEYS
// ============================================================
// SharedPreferences aur SecureStorage mein keys
// Ek jagah define karne se typos nahi hote
// Key change karni ho to ek jagah se ho jaati hai
// ============================================================

abstract final class AppStorageKeys {
  // --- Authentication ---

  /// JWT access token
  static const String accessToken = 'access_token';

  /// JWT refresh token
  static const String refreshToken = 'refresh_token';

  /// Token expiry timestamp
  static const String tokenExpiry = 'token_expiry';

  /// Is user logged in?
  static const String isLoggedIn = 'is_logged_in';

  /// Logged in user ID
  static const String userId = 'user_id';

  // --- Onboarding ---

  /// Has user seen onboarding?
  static const String hasSeenOnboarding = 'has_seen_onboarding';

  /// Onboarding completion date
  static const String onboardingDate = 'onboarding_date';

  // --- User Preferences ---

  /// Selected app language (en, ar, ur)
  static const String appLanguage = 'app_language';

  /// Selected theme (dark, light, system)
  static const String appTheme = 'app_theme';

  /// Selected Quran translation ID
  static const String quranTranslation = 'quran_translation';

  /// Selected Quran reciter ID
  static const String quranReciter = 'quran_reciter';

  /// Quran font size (small, medium, large)
  static const String quranFontSize = 'quran_font_size';

  /// Show transliteration in Quran?
  static const String showTransliteration = 'show_transliteration';

  /// Show translation in Quran?
  static const String showTranslation = 'show_translation';

  // --- Location ---

  /// Last known latitude
  static const String lastLatitude = 'last_latitude';

  /// Last known longitude
  static const String lastLongitude = 'last_longitude';

  /// Last known city name
  static const String lastCity = 'last_city';

  /// Last known country
  static const String lastCountry = 'last_country';

  // --- Prayer Settings ---

  /// Prayer calculation method ID
  static const String prayerMethod = 'prayer_method';

  /// Asr calculation method (Standard/Hanafi)
  static const String asrMethod = 'asr_method';

  /// Prayer notifications enabled?
  static const String prayerNotifications = 'prayer_notifications';

  /// Adhan sound ID
  static const String adhanSound = 'adhan_sound';

  // --- Quran Reading ---

  /// Last read surah number
  static const String lastReadSurah = 'last_read_surah';

  /// Last read ayah number
  static const String lastReadAyah = 'last_read_ayah';

  /// Last read page number
  static const String lastReadPage = 'last_read_page';

  // --- Tasbih ---

  /// Current tasbih count
  static const String tasbihCount = 'tasbih_count';

  /// Tasbih target count
  static const String tasbihTarget = 'tasbih_target';

  /// Current tasbih dhikr text
  static const String tasbihDhikr = 'tasbih_dhikr';

  // --- Cache Timestamps ---

  /// When was prayer times last fetched
  static const String prayerTimesCacheTime = 'prayer_times_cache_time';

  /// When was Quran data last fetched
  static const String quranCacheTime = 'quran_cache_time';

  // --- Notifications ---

  /// Firebase FCM device token
  static const String fcmToken = 'fcm_token';

  /// Notification permission granted?
  static const String notificationPermission = 'notification_permission';

  // --- Analytics ---

  /// Has user consented to analytics?
  static const String analyticsConsent = 'analytics_consent';

  /// App first launch date
  static const String firstLaunchDate = 'first_launch_date';

  /// Total app open count
  static const String appOpenCount = 'app_open_count';
}
