// lib/features/quran/data/repository/quran_repository.dart

// ============================================================
// QIBRA AI — QURAN REPOSITORY (v1.0)
// Phase: 8.2 — Real Quran Data Integration
// ============================================================
// Description: Repository for loading and managing Quran data
//
// Features:
//   ✅ Load JSON from assets (offline)
//   ✅ Parse Arabic + Translation
//   ✅ Cache for fast access
//   ✅ Search functionality
//   ✅ Get specific surah/ayah
//   ✅ Filter by Meccan/Medinan
//   ✅ Get random ayah (for daily verse)
//   ✅ Error handling
//
// Usage:
//   final repo = QuranRepository();
//   await repo.initialize();
//   final surah = await repo.getSurah(1);  // Al-Fatihah
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/quran_models.dart';

// ============================================================
// SECTION 1 — QURAN REPOSITORY
// ============================================================

class QuranRepository {
  // ── Singleton Pattern ─────────────────────────────────
  static final QuranRepository _instance = QuranRepository._internal();
  factory QuranRepository() => _instance;
  QuranRepository._internal();

  // ── Asset paths ───────────────────────────────────────
  static const String _arabicFilePath = 'assets/data/quran/quran_arabic.json';
  static const String _translationFilePath =
      'assets/data/quran/translation_en.json';
  static const String _surahInfoFilePath = 'assets/data/quran/surah_info.json';

  // ── Cache ─────────────────────────────────────────────
  List<SurahInfoModel>? _cachedSurahInfoList;
  Map<int, SurahModel>? _cachedSurahsMap;
  Map<int, String>? _cachedTranslationsMap;
  bool _isInitialized = false;

  // ── Initialization state ──────────────────────────────
  bool get isInitialized => _isInitialized;

  // ============================================================
  // SECTION 2 — INITIALIZATION
  // ============================================================

  /// Initialize repository — load all data at app startup
  /// Call this ONCE in main.dart or splash screen
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load in parallel for speed
      await Future.wait([
        _loadSurahInfo(),
        _loadArabicQuran(),
        _loadTranslations(),
      ]);

      _isInitialized = true;
    } catch (e, stackTrace) {
      throw QuranRepositoryException(
        'Failed to initialize Quran data: $e',
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // SECTION 3 — DATA LOADING METHODS
  // ============================================================

  /// Load surah info metadata (all 114 surahs)
  Future<void> _loadSurahInfo() async {
    try {
      final String jsonString = await rootBundle.loadString(_surahInfoFilePath);
      final dynamic decoded = json.decode(jsonString);

      // Handle alquran.cloud API structure: { "data": [...] }
      final List<dynamic> surahsList = decoded is Map<String, dynamic>
          ? (decoded['data'] as List<dynamic>? ?? [])
          : (decoded is List<dynamic> ? decoded : []);

      _cachedSurahInfoList = surahsList
          .map((json) => SurahInfoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw QuranRepositoryException('Failed to load surah info: $e');
    }
  }

  /// Load Arabic Quran text (all 6236 ayahs)
  Future<void> _loadArabicQuran() async {
    try {
      final String jsonString = await rootBundle.loadString(_arabicFilePath);
      final dynamic decoded = json.decode(jsonString);

      // Handle alquran.cloud API structure
      final Map<String, dynamic> data =
          decoded is Map<String, dynamic> ? decoded : {'data': decoded};

      final Map<String, dynamic> quranData =
          data['data'] as Map<String, dynamic>? ?? data;

      final List<dynamic> surahsList =
          quranData['surahs'] as List<dynamic>? ?? [];

      _cachedSurahsMap = {};
      for (final surahJson in surahsList) {
        final surah = SurahModel.fromJson(surahJson as Map<String, dynamic>);
        _cachedSurahsMap![surah.number] = surah;
      }
    } catch (e) {
      throw QuranRepositoryException('Failed to load Arabic Quran: $e');
    }
  }

  /// Load English translations
  Future<void> _loadTranslations() async {
    try {
      final String jsonString =
          await rootBundle.loadString(_translationFilePath);
      final dynamic decoded = json.decode(jsonString);

      final Map<String, dynamic> data =
          decoded is Map<String, dynamic> ? decoded : {'data': decoded};

      final Map<String, dynamic> quranData =
          data['data'] as Map<String, dynamic>? ?? data;

      final List<dynamic> surahsList =
          quranData['surahs'] as List<dynamic>? ?? [];

      _cachedTranslationsMap = {};

      for (final surahJson in surahsList) {
        final int surahNumber = (surahJson['number'] as num?)?.toInt() ?? 0;
        final List<dynamic> ayahs = surahJson['ayahs'] as List<dynamic>? ?? [];

        for (final ayahJson in ayahs) {
          final int globalNumber = (ayahJson['number'] as num?)?.toInt() ?? 0;
          final String text = ayahJson['text'] as String? ?? '';

          // Use global ayah number as key
          _cachedTranslationsMap![globalNumber] = text;
        }
      }
    } catch (e) {
      // Translations optional — don't throw
      _cachedTranslationsMap = {};
    }
  }

  // ============================================================
  // SECTION 4 — PUBLIC API METHODS
  // ============================================================

  /// Get all surahs info (metadata only — fast)
  ///
  /// Use this for: Surah list screen
  Future<List<SurahInfoModel>> getAllSurahsInfo() async {
    await _ensureInitialized();
    return _cachedSurahInfoList ?? [];
  }

  /// Get specific surah by number (1-114) with all ayahs
  ///
  /// Use this for: Surah reader screen
  Future<SurahModel?> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('Surah number must be between 1 and 114');
    }

    await _ensureInitialized();

    final surah = _cachedSurahsMap?[surahNumber];
    if (surah == null) return null;

    // Attach translations to each ayah
    return _attachTranslations(surah);
  }

  /// Get surah info only (metadata, no ayahs — fast)
  Future<SurahInfoModel?> getSurahInfo(int surahNumber) async {
    await _ensureInitialized();

    try {
      return _cachedSurahInfoList
          ?.firstWhere((surah) => surah.number == surahNumber);
    } catch (e) {
      return null;
    }
  }

  /// Get specific ayah by surah number and ayah number
  Future<AyahModel?> getAyah(int surahNumber, int ayahNumber) async {
    final surah = await getSurah(surahNumber);
    if (surah == null) return null;

    return surah.getAyahByNumber(ayahNumber);
  }

  /// Get random ayah (for daily verse)
  Future<AyahModel?> getRandomAyah() async {
    await _ensureInitialized();

    if (_cachedSurahsMap == null || _cachedSurahsMap!.isEmpty) return null;

    // Get random surah
    final surahNumbers = _cachedSurahsMap!.keys.toList();
    surahNumbers.shuffle();
    final randomSurahNumber = surahNumbers.first;

    final surah = await getSurah(randomSurahNumber);
    if (surah == null || surah.ayahs.isEmpty) return null;

    // Get random ayah from that surah
    final ayahs = List<AyahModel>.from(surah.ayahs);
    ayahs.shuffle();
    return ayahs.first;
  }

  /// Get Meccan surahs only
  Future<List<SurahInfoModel>> getMeccanSurahs() async {
    await _ensureInitialized();
    return _cachedSurahInfoList?.where((surah) => surah.isMeccan).toList() ??
        [];
  }

  /// Get Medinan surahs only
  Future<List<SurahInfoModel>> getMedinanSurahs() async {
    await _ensureInitialized();
    return _cachedSurahInfoList?.where((surah) => surah.isMedinan).toList() ??
        [];
  }

  /// Get popular/recommended surahs
  Future<List<SurahInfoModel>> getPopularSurahs() async {
    await _ensureInitialized();

    // Popular surah numbers
    const popularNumbers = [
      1, // Al-Fatihah
      2, // Al-Baqarah
      18, // Al-Kahf
      36, // Ya-Sin
      55, // Ar-Rahman
      56, // Al-Waqiah
      67, // Al-Mulk
      112, // Al-Ikhlas
    ];

    final List<SurahInfoModel> popular = [];
    for (final num in popularNumbers) {
      final surah = await getSurahInfo(num);
      if (surah != null) popular.add(surah);
    }
    return popular;
  }

  // ============================================================
  // SECTION 5 — SEARCH FUNCTIONALITY
  // ============================================================

  /// Search Quran (Arabic + Translation)
  Future<List<SearchResultModel>> search(String query) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();

    final results = <SearchResultModel>[];
    final lowerQuery = query.toLowerCase().trim();

    if (_cachedSurahsMap == null) return results;

    for (final entry in _cachedSurahsMap!.entries) {
      final surah = entry.value;

      for (final ayah in surah.ayahs) {
        // Check Arabic text
        if (ayah.text.contains(query)) {
          results.add(SearchResultModel(
            surahNumber: surah.number,
            surahName: surah.name,
            ayahNumber: ayah.number,
            ayahText: ayah.text,
            translation: _getTranslation(ayah.numberInQuran),
            matchedText: query,
            matchType: 0, // Arabic match
          ));
          continue;
        }

        // Check translation
        final translation = _getTranslation(ayah.numberInQuran);
        if (translation != null &&
            translation.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResultModel(
            surahNumber: surah.number,
            surahName: surah.name,
            ayahNumber: ayah.number,
            ayahText: ayah.text,
            translation: translation,
            matchedText: query,
            matchType: 1, // Translation match
          ));
        }

        // Limit results for performance
        if (results.length >= 100) return results;
      }
    }

    return results;
  }

  /// Search surahs by name
  Future<List<SurahInfoModel>> searchSurahs(String query) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();

    final lowerQuery = query.toLowerCase().trim();

    return _cachedSurahInfoList?.where((surah) {
          return surah.name.toLowerCase().contains(lowerQuery) ||
              surah.nameArabic.contains(query) ||
              surah.englishNameTranslation.toLowerCase().contains(lowerQuery) ||
              surah.number.toString() == query;
        }).toList() ??
        [];
  }

  // ============================================================
  // SECTION 6 — HELPER METHODS
  // ============================================================

  /// Ensure repository is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get translation for specific ayah number
  String? _getTranslation(int globalAyahNumber) {
    return _cachedTranslationsMap?[globalAyahNumber];
  }

  /// Attach translations to all ayahs in a surah
  SurahModel _attachTranslations(SurahModel surah) {
    if (_cachedTranslationsMap == null || _cachedTranslationsMap!.isEmpty) {
      return surah;
    }

    final updatedAyahs = surah.ayahs.map((ayah) {
      final translation = _getTranslation(ayah.numberInQuran);
      if (translation != null) {
        return ayah.copyWithTranslation(translation);
      }
      return ayah;
    }).toList();

    return surah.copyWith(ayahs: updatedAyahs);
  }

  // ============================================================
  // SECTION 7 — STATISTICS
  // ============================================================

  /// Get total surahs count
  int get totalSurahs => _cachedSurahInfoList?.length ?? 0;

  /// Get total ayahs count across all surahs
  int get totalAyahs {
    if (_cachedSurahInfoList == null) return 0;
    return _cachedSurahInfoList!
        .fold(0, (sum, surah) => sum + surah.numberOfAyahs);
  }

  /// Get total Meccan surahs count
  int get meccanSurahsCount {
    return _cachedSurahInfoList?.where((surah) => surah.isMeccan).length ?? 0;
  }

  /// Get total Medinan surahs count
  int get medinanSurahsCount {
    return _cachedSurahInfoList?.where((surah) => surah.isMedinan).length ?? 0;
  }

  /// Get statistics summary
  Map<String, dynamic> get statistics {
    return {
      'totalSurahs': totalSurahs,
      'totalAyahs': totalAyahs,
      'meccanSurahs': meccanSurahsCount,
      'medinanSurahs': medinanSurahsCount,
      'isInitialized': _isInitialized,
    };
  }

  // ============================================================
  // SECTION 8 — CACHE MANAGEMENT
  // ============================================================

  /// Clear cache (free memory)
  void clearCache() {
    _cachedSurahInfoList = null;
    _cachedSurahsMap = null;
    _cachedTranslationsMap = null;
    _isInitialized = false;
  }

  /// Reload data (useful if data updated)
  Future<void> reload() async {
    clearCache();
    await initialize();
  }
}

// ============================================================
// SECTION 9 — CUSTOM EXCEPTION
// ============================================================

/// Custom exception for repository errors
class QuranRepositoryException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  QuranRepositoryException(this.message, {this.stackTrace});

  @override
  String toString() => 'QuranRepositoryException: $message';
}

// ============================================================
// END OF FILE — quran_repository.dart
// ============================================================
