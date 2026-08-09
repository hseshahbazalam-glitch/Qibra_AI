// lib/features/quran/data/repository/quran_repository.dart

// ============================================================
// QIBRA AI — QURAN REPOSITORY (v2.0)
// Version: 2.0.0 — With Urdu + Roman Urdu Translations
// ============================================================
// Description: Repository for loading and managing Quran data
//              Supports Arabic + English + Urdu + Roman Urdu
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/quran_models.dart';

// ============================================================
// SECTION 1 — QURAN REPOSITORY
// ============================================================

class QuranRepository {
  // Singleton
  static final QuranRepository _instance = QuranRepository._internal();
  factory QuranRepository() => _instance;
  QuranRepository._internal();

  // Asset paths
  static const String _arabicFilePath = 'assets/data/quran/quran_arabic.json';
  static const String _translationEnPath =
      'assets/data/quran/translation_en.json';
  static const String _translationUrPath =
      'assets/data/quran/translation_ur_jalandhry.json';
  static const String _translationRomanPath =
      'assets/data/quran/translation_ur_maududi_roman.json';
  static const String _surahInfoFilePath = 'assets/data/quran/surah_info.json';

  // Cache
  List<SurahInfoModel>? _cachedSurahInfoList;
  Map<int, SurahModel>? _cachedSurahsMap;
  Map<int, String>? _cachedTranslationsEn;
  Map<String, String>? _cachedTranslationsUrdu; // "chapter_verse" -> text
  Map<String, String>? _cachedTranslationsRoman;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ============================================================
  // SECTION 2 — INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[QURAN] Initializing...');
      final stopwatch = Stopwatch()..start();

      await Future.wait([
        _loadSurahInfo(),
        _loadArabicQuran(),
        _loadTranslationsEnglish(),
        _loadTranslationsUrdu(),
        _loadTranslationsRoman(),
      ]);

      _isInitialized = true;
      stopwatch.stop();

      debugPrint('[QURAN] Initialized in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint(
          '   English translations: ${_cachedTranslationsEn?.length ?? 0}');
      debugPrint(
          '   Urdu translations: ${_cachedTranslationsUrdu?.length ?? 0}');
      debugPrint(
          '   Roman translations: ${_cachedTranslationsRoman?.length ?? 0}');
    } catch (e, stackTrace) {
      throw QuranRepositoryException(
        'Failed to initialize Quran data: $e',
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // SECTION 3 — DATA LOADING
  // ============================================================

  Future<void> _loadSurahInfo() async {
    try {
      final jsonString = await rootBundle.loadString(_surahInfoFilePath);
      final decoded = json.decode(jsonString);

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

  Future<void> _loadArabicQuran() async {
    try {
      final jsonString = await rootBundle.loadString(_arabicFilePath);
      final decoded = json.decode(jsonString);

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

  Future<void> _loadTranslationsEnglish() async {
    try {
      final jsonString = await rootBundle.loadString(_translationEnPath);
      final decoded = json.decode(jsonString);

      final Map<String, dynamic> data =
          decoded is Map<String, dynamic> ? decoded : {'data': decoded};

      final Map<String, dynamic> quranData =
          data['data'] as Map<String, dynamic>? ?? data;

      final List<dynamic> surahsList =
          quranData['surahs'] as List<dynamic>? ?? [];

      _cachedTranslationsEn = {};

      for (final surahJson in surahsList) {
        final List<dynamic> ayahs = surahJson['ayahs'] as List<dynamic>? ?? [];

        for (final ayahJson in ayahs) {
          final int globalNumber = (ayahJson['number'] as num?)?.toInt() ?? 0;
          final String text = ayahJson['text'] as String? ?? '';

          _cachedTranslationsEn![globalNumber] = text;
        }
      }
    } catch (e) {
      debugPrint('[QURAN] English translations failed: $e');
      _cachedTranslationsEn = {};
    }
  }

  /// Load Urdu translation (Fateh Muhammad Jalandhry)
  /// Format: {"quran": [{"chapter": 1, "verse": 1, "text": "..."}]}
  Future<void> _loadTranslationsUrdu() async {
    try {
      final jsonString = await rootBundle.loadString(_translationUrPath);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final List<dynamic> ayahs = decoded['quran'] as List<dynamic>? ?? [];

      _cachedTranslationsUrdu = {};

      for (final ayahJson in ayahs) {
        final map = ayahJson as Map<String, dynamic>;
        final int chapter = (map['chapter'] as num?)?.toInt() ?? 0;
        final int verse = (map['verse'] as num?)?.toInt() ?? 0;
        final String text = map['text'] as String? ?? '';

        final key = '${chapter}_$verse';
        _cachedTranslationsUrdu![key] = text;
      }
    } catch (e) {
      debugPrint('[QURAN] Urdu translations failed: $e');
      _cachedTranslationsUrdu = {};
    }
  }

  /// Load Roman Urdu translation (Maududi Roman)
  Future<void> _loadTranslationsRoman() async {
    try {
      final jsonString = await rootBundle.loadString(_translationRomanPath);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final List<dynamic> ayahs = decoded['quran'] as List<dynamic>? ?? [];

      _cachedTranslationsRoman = {};

      for (final ayahJson in ayahs) {
        final map = ayahJson as Map<String, dynamic>;
        final int chapter = (map['chapter'] as num?)?.toInt() ?? 0;
        final int verse = (map['verse'] as num?)?.toInt() ?? 0;
        final String text = map['text'] as String? ?? '';

        final key = '${chapter}_$verse';
        _cachedTranslationsRoman![key] = text;
      }
    } catch (e) {
      debugPrint('[QURAN] Roman translations failed: $e');
      _cachedTranslationsRoman = {};
    }
  }

  // ============================================================
  // SECTION 4 — PUBLIC API
  // ============================================================

  Future<List<SurahInfoModel>> getAllSurahsInfo() async {
    await _ensureInitialized();
    return _cachedSurahInfoList ?? [];
  }

  Future<SurahModel?> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('Surah number must be between 1 and 114');
    }

    await _ensureInitialized();

    final surah = _cachedSurahsMap?[surahNumber];
    if (surah == null) return null;

    return _attachAllTranslations(surah);
  }

  Future<SurahInfoModel?> getSurahInfo(int surahNumber) async {
    await _ensureInitialized();

    try {
      return _cachedSurahInfoList
          ?.firstWhere((surah) => surah.number == surahNumber);
    } catch (e) {
      return null;
    }
  }

  Future<AyahModel?> getAyah(int surahNumber, int ayahNumber) async {
    final surah = await getSurah(surahNumber);
    if (surah == null) return null;

    return surah.getAyahByNumber(ayahNumber);
  }

  Future<AyahModel?> getRandomAyah() async {
    await _ensureInitialized();

    if (_cachedSurahsMap == null || _cachedSurahsMap!.isEmpty) return null;

    final surahNumbers = _cachedSurahsMap!.keys.toList();
    surahNumbers.shuffle();
    final randomSurahNumber = surahNumbers.first;

    final surah = await getSurah(randomSurahNumber);
    if (surah == null || surah.ayahs.isEmpty) return null;

    final ayahs = List<AyahModel>.from(surah.ayahs);
    ayahs.shuffle();
    return ayahs.first;
  }

  Future<List<SurahInfoModel>> getMeccanSurahs() async {
    await _ensureInitialized();
    return _cachedSurahInfoList?.where((surah) => surah.isMeccan).toList() ??
        [];
  }

  Future<List<SurahInfoModel>> getMedinanSurahs() async {
    await _ensureInitialized();
    return _cachedSurahInfoList?.where((surah) => surah.isMedinan).toList() ??
        [];
  }

  Future<List<SurahInfoModel>> getPopularSurahs() async {
    await _ensureInitialized();

    const popularNumbers = [1, 2, 18, 36, 55, 56, 67, 112];

    final List<SurahInfoModel> popular = [];
    for (final num in popularNumbers) {
      final surah = await getSurahInfo(num);
      if (surah != null) popular.add(surah);
    }
    return popular;
  }

  // ============================================================
  // SECTION 5 — SEARCH
  // ============================================================

  Future<List<SearchResultModel>> search(String query) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();

    final results = <SearchResultModel>[];
    final lowerQuery = query.toLowerCase().trim();

    if (_cachedSurahsMap == null) return results;

    for (final entry in _cachedSurahsMap!.entries) {
      final surah = entry.value;

      for (final ayah in surah.ayahs) {
        // Arabic text search
        if (ayah.text.contains(query)) {
          results.add(SearchResultModel(
            surahNumber: surah.number,
            surahName: surah.name,
            ayahNumber: ayah.number,
            ayahText: ayah.text,
            translation: _getTranslationEn(ayah.numberInQuran),
            matchedText: query,
            matchType: 0,
          ));
          continue;
        }

        // English translation search
        final translation = _getTranslationEn(ayah.numberInQuran);
        if (translation != null &&
            translation.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResultModel(
            surahNumber: surah.number,
            surahName: surah.name,
            ayahNumber: ayah.number,
            ayahText: ayah.text,
            translation: translation,
            matchedText: query,
            matchType: 1,
          ));
        }

        if (results.length >= 100) return results;
      }
    }

    return results;
  }

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

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Get English translation by global ayah number
  String? _getTranslationEn(int globalAyahNumber) {
    return _cachedTranslationsEn?[globalAyahNumber];
  }

  /// Get Urdu translation by chapter and verse
  String? _getTranslationUrdu(int chapter, int verse) {
    return _cachedTranslationsUrdu?['${chapter}_$verse'];
  }

  /// Get Roman Urdu translation by chapter and verse
  String? _getTranslationRoman(int chapter, int verse) {
    return _cachedTranslationsRoman?['${chapter}_$verse'];
  }

  /// Attach ALL translations (English + Urdu + Roman) to surah
  SurahModel _attachAllTranslations(SurahModel surah) {
    final updatedAyahs = surah.ayahs.map((ayah) {
      final english = _getTranslationEn(ayah.numberInQuran);
      final urdu = _getTranslationUrdu(surah.number, ayah.number);
      final roman = _getTranslationRoman(surah.number, ayah.number);

      return ayah.copyWithAllTranslations(
        english: english,
        urdu: urdu,
        roman: roman,
      );
    }).toList();

    return surah.copyWith(ayahs: updatedAyahs);
  }

  // ============================================================
  // SECTION 7 — STATISTICS
  // ============================================================

  int get totalSurahs => _cachedSurahInfoList?.length ?? 0;

  int get totalAyahs {
    if (_cachedSurahInfoList == null) return 0;
    return _cachedSurahInfoList!
        .fold(0, (sum, surah) => sum + surah.numberOfAyahs);
  }

  int get meccanSurahsCount {
    return _cachedSurahInfoList?.where((surah) => surah.isMeccan).length ?? 0;
  }

  int get medinanSurahsCount {
    return _cachedSurahInfoList?.where((surah) => surah.isMedinan).length ?? 0;
  }

  Map<String, dynamic> get statistics {
    return {
      'totalSurahs': totalSurahs,
      'totalAyahs': totalAyahs,
      'meccanSurahs': meccanSurahsCount,
      'medinanSurahs': medinanSurahsCount,
      'englishTranslations': _cachedTranslationsEn?.length ?? 0,
      'urduTranslations': _cachedTranslationsUrdu?.length ?? 0,
      'romanTranslations': _cachedTranslationsRoman?.length ?? 0,
      'isInitialized': _isInitialized,
    };
  }

  // ============================================================
  // SECTION 8 — CACHE MANAGEMENT
  // ============================================================

  void clearCache() {
    _cachedSurahInfoList = null;
    _cachedSurahsMap = null;
    _cachedTranslationsEn = null;
    _cachedTranslationsUrdu = null;
    _cachedTranslationsRoman = null;
    _isInitialized = false;
  }

  Future<void> reload() async {
    clearCache();
    await initialize();
  }
}

// ============================================================
// SECTION 9 — CUSTOM EXCEPTION
// ============================================================

class QuranRepositoryException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  QuranRepositoryException(this.message, {this.stackTrace});

  @override
  String toString() => 'QuranRepositoryException: $message';
}
