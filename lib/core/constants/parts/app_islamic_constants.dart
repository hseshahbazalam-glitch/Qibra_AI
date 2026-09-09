// lib/core/constants/parts/app_islamic_constants.dart
// Part of the app_constants library (Professionalization Phase B,
// 2026-09-08 — pure structure): one class per file, body and doc
// comments VERBATIM; the library root keeps the public import path, so
// every call site compiles exactly as before the split.

part of '../app_constants.dart';

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

  // --- Juz (Para) Start Boundaries (1-indexed, surah:ayah) ---
  /// Standard Uthmani mushaf Juz start points.
  /// Index 0 = Juz 1, length = 30. Each entry: [surahNumber, ayahNumber].
  static const List<List<int>> juzBoundaries = [
    [1, 1],
    [2, 142],
    [2, 253],
    [3, 93],
    [4, 24],
    [4, 148],
    [5, 83],
    [6, 111],
    [7, 88],
    [8, 41],
    [9, 93],
    [11, 6],
    [12, 53],
    [15, 2],
    [17, 1],
    [18, 75],
    [21, 1],
    [23, 1],
    [25, 21],
    [27, 56],
    [29, 46],
    [33, 28],
    [36, 28],
    [39, 32],
    [41, 47],
    [46, 1],
    [51, 31],
    [58, 1],
    [67, 1],
    [78, 1],
  ];

  // --- Sajdah (Prostration) Points ---
  /// The 15 agreed-upon sajdah verses (14 wājib + 1 mustahab in Hanafi fiqh).
  /// Format: {surah: ayah}.
  static const Map<int, List<int>> sajdahPoints = {
    7: [206],
    13: [15],
    16: [50],
    17: [109],
    19: [58],
    22: [18, 77],
    25: [60],
    27: [26],
    32: [15],
    38: [24],
    41: [38],
    53: [62],
    84: [21],
    96: [19],
  };

  /// Total sajdah points in the Quran.
  static const int totalSajdahPoints = 15;

  // --- Revelation Order of Surahs ---
  /// Traditional chronological revelation order of all 114 surahs
  /// (surah numbers in the order they were revealed).
  static const List<int> revelationOrder = [
    96,
    68,
    73,
    74,
    1,
    111,
    81,
    87,
    92,
    89,
    93,
    94,
    103,
    100,
    108,
    102,
    107,
    109,
    105,
    113,
    114,
    112,
    53,
    80,
    97,
    91,
    85,
    95,
    106,
    101,
    75,
    104,
    77,
    50,
    90,
    86,
    54,
    38,
    7,
    72,
    36,
    25,
    35,
    19,
    20,
    56,
    26,
    27,
    28,
    17,
    10,
    11,
    12,
    15,
    6,
    37,
    31,
    34,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    51,
    88,
    18,
    16,
    71,
    14,
    21,
    23,
    32,
    52,
    67,
    69,
    70,
    78,
    79,
    82,
    84,
    30,
    29,
    83,
    2,
    8,
    3,
    33,
    60,
    4,
    99,
    57,
    47,
    13,
    55,
    76,
    65,
    98,
    59,
    24,
    22,
    63,
    58,
    49,
    66,
    64,
    61,
    62,
    48,
    5,
    9,
    110,
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
