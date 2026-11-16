// lib/core/constants/parts/app_api.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

// ============================================================
// SECTION 2: API CONSTANTS
// ============================================================
// Backend API ke saare URLs aur configuration
// Production aur development alag-alag hote hain
// ============================================================

abstract final class AppApi {
  // --- Backend availability ---
  // When false, app runs anonymous-first (no server auth required).
  // Set to true only once the Render service answers /health (docs/DEPLOY.md).
  static const bool isBackendEnabled = true;

  // --- Base URLs ---

  /// Production API base URL — live Render service (docs/DEPLOY.md).
  /// The previously planned custom domain is retired; this is the single
  /// source constant every network layer reads (ApiClient — nothing else).
  static const String baseUrlProduction = 'https://qibra-ai.onrender.com';

  /// Development/Local API base URL
  static const String baseUrlDevelopment = 'http://localhost:8000';

  /// Current active base URL
  /// Development mein development URL use karo
  /// Production build mein production URL
  static const String baseUrl = baseUrlProduction;

  /// API version prefix — the Render service mounts every route at the
  /// ROOT (/ai/ask, /health); there is no /v1. Kept empty as the single
  /// source so nothing re-introduces the old prefix. See docs/DEPLOY.md.
  static const String apiVersion = '';

  /// Full API URL — identical to baseUrl (root-mounted backend).
  static const String apiUrl = baseUrl;

  // --- Timeouts ---
  // P0.2: unified 20s timeout per audit (was 30s, too long for mobile)

  /// Connection timeout — server se connect hone ka max time
  static const Duration connectTimeout = Duration(seconds: 20);

  /// Receive timeout — data receive karne ka max time
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Send timeout — data bhejne ka max time
  static const Duration sendTimeout = Duration(seconds: 20);

  /// AI ask budget — Render free tier cold start is 50-60s, so 20s
  /// receiveTimeout cut it off and 120s hung the chat feel. Owner
  /// 2026-09-02: hard 90s ceiling on both stream and non-stream paths.
  static const Duration aiAskTimeout = Duration(seconds: 90);

  // --- Retry Configuration ---

  /// Maximum retry attempts on failure
  static const int maxRetries = 3;

  /// Delay between retries
  static const Duration retryDelay = Duration(seconds: 2);

  // --- Endpoints ---
  // Har feature ka apna endpoint group hai

  // Auth endpoints
  static const String endpointLogin = '/auth/login';
  static const String endpointRegister = '/auth/register';
  static const String endpointLogout = '/auth/logout';
  static const String endpointRefreshToken = '/auth/refresh';
  static const String endpointForgotPassword = '/auth/forgot-password';
  static const String endpointResetPassword = '/auth/reset-password';
  static const String endpointVerifyOtp = '/auth/verify-otp';
  static const String endpointResendOtp = '/auth/resend-otp';
  static const String endpointGoogleAuth = '/auth/google';
  static const String endpointAppleAuth = '/auth/apple';

  // User endpoints
  static const String endpointProfile = '/user/profile';
  static const String endpointUpdateProfile = '/user/profile/update';
  static const String endpointUpdatePassword = '/user/password/update';
  static const String endpointDeleteAccount = '/user/delete';
  static const String endpointUploadAvatar = '/user/avatar';

  // Prayer endpoints
  static const String endpointPrayerTimes = '/prayer/times';
  static const String endpointQiblaDirection = '/prayer/qibla';
  static const String endpointNearbyMosques = '/prayer/mosques/nearby';
  static const String endpointPrayerReminders = '/prayer/reminders';

  // Quran endpoints
  static const String endpointQuranSurahs = '/quran/surahs';
  static const String endpointQuranAyahs = '/quran/ayahs';
  static const String endpointQuranSearch = '/quran/search';
  static const String endpointQuranAudio = '/quran/audio';
  static const String endpointQuranTranslations = '/quran/translations';
  static const String endpointQuranBookmarks = '/quran/bookmarks';
  static const String endpointQuranLastRead = '/quran/last-read';

  // Hadith endpoints
  static const String endpointHadithCollections = '/hadith/collections';
  static const String endpointHadithBooks = '/hadith/books';
  static const String endpointHadithSearch = '/hadith/search';
  static const String endpointHadithDaily = '/hadith/daily';
  static const String endpointHadithBookmarks = '/hadith/bookmarks';

  // AI endpoints
  static const String endpointAiAsk = '/ai/ask';
  static const String endpointAiChat = '/ai/chat';
  static const String endpointAiChatHistory = '/ai/chat/history';
  static const String endpointAiIslamicQuestion = '/ai/question';
  static const String endpointAiFatwa = '/ai/fatwa';

  // Dua endpoints
  static const String endpointDuaCategories = '/dua/categories';
  static const String endpointDuaList = '/dua/list';
  static const String endpointDuaFavorites = '/dua/favorites';

  // Islamic Calendar endpoints
  static const String endpointHijriDate = '/calendar/hijri';
  static const String endpointIslamicEvents = '/calendar/events';
  static const String endpointRamadanCalendar = '/calendar/ramadan';

  // Tasbih endpoints
  static const String endpointTasbihSave = '/tasbih/save';
  static const String endpointTasbihHistory = '/tasbih/history';

  // Notification endpoints
  static const String endpointNotifications = '/notifications';
  static const String endpointNotificationRead = '/notifications/read';
  static const String endpointRegisterDevice = '/notifications/register-device';
  // Tools Routes
  static const String zakat = '/tools/zakat';
  static const String inheritance = '/tools/inheritance';
  static const String habits = '/tools/habits';
  static const String dhikr = '/tasbih';
  // --- External APIs ---

  /// Prayer times API (Aladhan — free, reliable)
  static const String aladhanBaseUrl = 'https://api.aladhan.com/v1';

  /// Prayer times endpoint
  static const String aladhanPrayerTimes = '$aladhanBaseUrl/timings';

  /// Hijri calendar endpoint
  static const String aladhanHijriDate = '$aladhanBaseUrl/gToH';

  /// Islamic months endpoint
  static const String aladhanIslamicCalendar = '$aladhanBaseUrl/hijriCalendar';

  /// Quran API (free)
  static const String quranApiBaseUrl = 'https://api.quran.com/api/v4';

  /// Hadith API
  static const String hadithApiBaseUrl = 'https://api.hadith.gading.dev';
}
