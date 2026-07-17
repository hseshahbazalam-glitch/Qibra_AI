// lib/core/constants/app_constants.dart

// ============================================================
// QIBRA AI — APP CONSTANTS
// Version: 1.0.0
// Description: Single source of truth for all fixed values.
//              App info, API, Storage, Islamic data,
//              Validation, Cache, and Feature flags.
//              Nothing is hardcoded anywhere else in the app.
// ============================================================

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

// ============================================================
// SECTION 2: API CONSTANTS
// ============================================================
// Backend API ke saare URLs aur configuration
// Production aur development alag-alag hote hain
// ============================================================

abstract final class AppApi {
  // --- Base URLs ---

  /// Production API base URL
  static const String baseUrlProduction = 'https://api.qibra.ai';

  /// Development/Local API base URL
  static const String baseUrlDevelopment = 'http://localhost:8000';

  /// Current active base URL
  /// Development mein development URL use karo
  /// Production build mein production URL
  static const String baseUrl = baseUrlProduction;

  /// API version prefix
  static const String apiVersion = '/v1';

  /// Full API URL (base + version)
  static const String apiUrl = '$baseUrl$apiVersion';

  // --- Timeouts ---

  /// Connection timeout — server se connect hone ka max time
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout — data receive karne ka max time
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout — data bhejne ka max time
  static const Duration sendTimeout = Duration(seconds: 30);

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

// ============================================================
// SECTION 5: ISLAMIC CONSTANTS
// ============================================================
// Islam ke specific numbers aur data jo app mein use honge
// Quran, Prayer, Hijri Calendar related constants
// ============================================================

abstract final class AppIslamicConstants {
  // --- Quran ---

  /// Total number of surahs in Quran
  static const int quranTotalSurahs = 114;

  /// Total number of ayahs in Quran
  static const int quranTotalAyahs = 6236;

  /// Total number of pages in standard Mushaf
  static const int quranTotalPages = 604;

  /// Total number of juz (para)
  static const int quranTotalJuz = 30;

  /// Total number of hizb
  static const int quranTotalHizb = 60;

  /// Total number of ruku
  static const int quranTotalRuku = 540;

  /// Surah Al-Fatiha number
  static const int surahFatiha = 1;

  /// Surah Al-Baqarah number (longest surah)
  static const int surahBaqarah = 2;

  /// Surah Al-Kahf number (read every Friday)
  static const int surahKahf = 18;

  /// Surah Yaseen number
  static const int surahYaseen = 36;

  /// Surah Al-Mulk number
  static const int surahMulk = 67;

  /// Surah Al-Ikhlas number
  static const int surahIkhlas = 112;

  /// Surah Al-Falaq number
  static const int surahFalaq = 113;

  /// Surah Al-Nas number
  static const int surahNas = 114;

  // --- Daily Prayers ---

  /// Total daily prayers
  static const int totalDailyPrayers = 5;

  /// Prayer names in English
  static const List<String> prayerNamesEnglish = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  /// Prayer names in Arabic
  static const List<String> prayerNamesArabic = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  /// Prayer names in Urdu
  static const List<String> prayerNamesUrdu = [
    'فجر',
    'ظہر',
    'عصر',
    'مغرب',
    'عشاء',
  ];

  // --- Prayer Calculation Methods ---
  // Aladhan API mein method IDs

  /// University of Islamic Sciences, Karachi (Pakistan/India)
  static const int methodKarachi = 1;

  /// Islamic Society of North America (ISNA)
  static const int methodISNA = 2;

  /// Muslim World League
  static const int methodMWL = 3;

  /// Umm Al-Qura University, Makkah
  static const int methodMakkah = 4;

  /// Egyptian General Authority of Survey
  static const int methodEgypt = 5;

  /// Default method (Karachi — most common for South Asia)
  static const int defaultPrayerMethod = methodKarachi;

  // --- Hijri Months ---

  /// All 12 Hijri month names in Arabic
  static const List<String> hijriMonthsArabic = [
    'محرم', // 1 — Muharram
    'صفر', // 2 — Safar
    'ربيع الأول', // 3 — Rabi al-Awwal
    'ربيع الثاني', // 4 — Rabi al-Thani
    'جمادى الأولى', // 5 — Jumada al-Ula
    'جمادى الثانية', // 6 — Jumada al-Thania
    'رجب', // 7 — Rajab
    'شعبان', // 8 — Sha\'ban
    'رمضان', // 9 — Ramadan
    'شوال', // 10 — Shawwal
    'ذو القعدة', // 11 — Dhu al-Qadah
    'ذو الحجة', // 12 — Dhu al-Hijjah
  ];

  /// All 12 Hijri month names in English
  static const List<String> hijriMonthsEnglish = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Thania',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];

  // --- Important Islamic Days ---

  /// Ramadan month number (Hijri)
  static const int ramadanMonth = 9;

  /// Eid ul-Fitr date (1st Shawwal)
  static const int eidUlFitrDay = 1;
  static const int eidUlFitrMonth = 10;

  /// Eid ul-Adha date (10th Dhu al-Hijjah)
  static const int eidUlAdhaDay = 10;
  static const int eidUlAdhaMonth = 12;

  /// Laylatul Qadr nights (odd nights of last 10 days of Ramadan)
  static const List<int> laylatulQadrNights = [21, 23, 25, 27, 29];

  /// Most likely Laylatul Qadr night
  static const int laylatulQadrBest = 27;

  // --- Islamic Days of Week ---

  /// Friday = Jumu'ah (special day in Islam)
  /// In Dart, DateTime.friday = 5
  static const int jumuahDay = 5;

  // --- Qibla ---

  /// Kaaba latitude (Makkah, Saudi Arabia)
  static const double kaabatullahLatitude = 21.3891;

  /// Kaaba longitude
  static const double kaabatullahLongitude = 39.8579;

  // --- Tasbih Defaults ---

  /// Standard tasbih count (SubhanAllah × 33)
  static const int tasbihSubhanAllah = 33;

  /// Standard tasbih count (Alhamdulillah × 33)
  static const int tasbihAlhamdulillah = 33;

  /// Standard tasbih count (Allahu Akbar × 34)
  static const int tasbihAllahuAkbar = 34;

  /// Total standard tasbih (33+33+34)
  static const int tasbihTotal = 100;

  // --- Hadith Collections ---

  /// Major hadith collection names
  static const List<String> hadithCollections = [
    'Sahih al-Bukhari',
    'Sahih Muslim',
    "Sunan Abu Da'ud",
    'Jami al-Tirmidhi',
    'Sunan al-Nasa\'i',
    'Sunan Ibn Majah',
    'Muwatta Malik',
    'Musnad Ahmad',
  ];

  // --- Common Duas ---

  /// Bismillah
  static const String bismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  /// Alhamdulillah
  static const String alhamdulillah = 'الْحَمْدُ لِلَّهِ';

  /// SubhanAllah
  static const String subhanAllah = 'سُبْحَانَ اللَّهِ';

  /// Allahu Akbar
  static const String allahuAkbar = 'اللَّهُ أَكْبَرُ';

  /// La ilaha illa Allah
  static const String shahada =
      'لَا إِلَٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ';

  /// Astaghfirullah
  static const String astaghfirullah = 'أَسْتَغْفِرُ اللَّهَ';

  /// Salawat on Prophet (PBUH)
  static const String salawat =
      'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ';

  /// Inna lillahi wa inna ilayhi raji'un
  static const String innaLillah =
      'إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ';

  /// Mashallah
  static const String mashallah = 'مَا شَاءَ اللَّهُ';

  /// Inshallah
  static const String inshallah = 'إِنْ شَاءَ اللَّهُ';
}

// ============================================================
// SECTION 6: VALIDATION CONSTANTS
// ============================================================
// Form validation ke liye rules aur patterns
// Regex patterns = input format check karne ke liye
// ============================================================

abstract final class AppValidation {
  // --- Length Limits ---

  /// Minimum password length
  static const int passwordMinLength = 8;

  /// Maximum password length
  static const int passwordMaxLength = 32;

  /// Minimum name length
  static const int nameMinLength = 2;

  /// Maximum name length
  static const int nameMaxLength = 50;

  /// Maximum email length
  static const int emailMaxLength = 100;

  /// Maximum bio length
  static const int bioMaxLength = 200;

  /// OTP length (6 digits)
  static const int otpLength = 6;

  /// Maximum AI chat message length
  static const int aiChatMaxLength = 500;

  /// Maximum search query length
  static const int searchMaxLength = 100;

  // --- Regex Patterns ---
  // Regex = Regular Expression — input format check karne ka pattern
  // ^ = start, $ = end, + = one or more, * = zero or more
  // [a-z] = any lowercase letter, \d = any digit

  /// Valid email pattern
  /// Example valid: user@example.com, user.name@domain.co.uk
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Strong password pattern
  /// Must have: uppercase, lowercase, number, special char, 8+ chars
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Phone number pattern (international format)
  /// Example: +923001234567, +14155552671
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');

  /// Name pattern — only letters, spaces, hyphens
  static final RegExp nameRegex = RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']{2,50}$");

  /// OTP pattern — exactly 6 digits
  static final RegExp otpRegex = RegExp(r'^\d{6}$');

  /// URL pattern
  static final RegExp urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  // --- Error Messages ---

  /// Required field error
  static const String errorRequired = 'This field is required';

  /// Invalid email error
  static const String errorEmail = 'Please enter a valid email address';

  /// Weak password error
  static const String errorPassword =
      'Password must be 8+ chars with uppercase, lowercase, number & special character';

  /// Password too short error
  static const String errorPasswordShort =
      'Password must be at least 8 characters';

  /// Passwords don't match error
  static const String errorPasswordMatch = 'Passwords do not match';

  /// Invalid phone error
  static const String errorPhone =
      'Please enter a valid phone number with country code';

  /// Invalid name error
  static const String errorName = 'Name must be 2-50 characters (letters only)';

  /// Invalid OTP error
  static const String errorOtp = 'Please enter a valid 6-digit OTP';

  /// Name too short error
  static const String errorNameShort = 'Name must be at least 2 characters';

  /// Text too long error
  static String errorTooLong(int max) => 'Maximum $max characters allowed';
}

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

  /// Is offline Quran download enabled?
  static const bool quranOfflineEnabled = true;

  /// Is Quran audio enabled?
  static const bool quranAudioEnabled = true;

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

  /// Is Google Sign-In enabled?
  static const bool googleAuthEnabled = true;

  /// Is Apple Sign-In enabled?
  static const bool appleAuthEnabled = true;

  /// Is phone/OTP auth enabled?
  static const bool phoneAuthEnabled = true;

  // --- Developer Options ---

  /// Show debug info in UI?
  /// MUST be false in production!
  static const bool showDebugInfo = false;

  /// Enable analytics?
  static const bool analyticsEnabled = true;

  /// Enable crash reporting?
  static const bool crashReportingEnabled = true;

  /// Enable performance monitoring?
  static const bool performanceMonitoringEnabled = true;
}

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
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';
  static const String profileSetup = '/profile-setup';
  // --- Main Routes ---
  static const String home = '/home';
  static const String quran = '/quran';
  static const String prayer = '/prayer';
  static const String hadith = '/hadith';
  static const String aiChat = '/ai-chat';

  // --- Sub Routes ---
  static const String quranSurah = '/quran/surah';
  static const String quranSearch = '/quran/search';
  static const String quranBookmarks = '/quran/bookmarks';

  static const String prayerTimes = '/prayer/times';
  static const String qibla = '/prayer/qibla';
  static const String mosques = '/prayer/mosques';

  static const String hadithCollection = '/hadith/collection';
  static const String hadithDetail = '/hadith/detail';
  static const String hadithSearch = '/hadith/search';

  static const String dua = '/dua';
  static const String duaDetail = '/dua/detail';

  static const String tasbih = '/tasbih';
  static const String islamicCalendar = '/calendar';

  // --- User Routes ---
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String about = '/about';
}
