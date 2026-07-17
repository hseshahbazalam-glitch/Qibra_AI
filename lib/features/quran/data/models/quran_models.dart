// lib/features/quran/data/models/quran_models.dart

// ============================================================
// QIBRA AI — QURAN DATA MODELS (v1.0)
// Phase: 8.2 — Real Quran Data Integration
// ============================================================
// Description: Data models for parsing Quran JSON files
//
// Data Sources (alquran.cloud API format):
//   - quran_arabic.json     (Arabic text - all 6236 ayahs)
//   - translation_en.json   (English translation)
//   - surah_info.json       (Metadata for all 114 surahs)
//
// Models:
//   1. SurahModel         - Complete surah with all ayahs
//   2. AyahModel          - Single verse (Arabic + translation)
//   3. SurahInfoModel     - Lightweight metadata only
//   4. BookmarkModel      - User bookmarks
//   5. LastReadModel      - Reading position tracker
//   6. ReadingProgressModel - Overall progress stats
// ============================================================

import 'package:equatable/equatable.dart';

// ============================================================
// SECTION 1 — SURAH MODEL (Complete with Ayahs)
// ============================================================

/// Complete Surah data with all ayahs
///
/// Used for: Surah reader screen (full data)
class SurahModel extends Equatable {
  final int number;
  final String name;
  final String nameArabic;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<AyahModel> ayahs;

  const SurahModel({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  /// Parse from alquran.cloud API JSON structure
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    // Parse ayahs first (needed for fallback count)
    final List<AyahModel> parsedAyahs = (json['ayahs'] as List<dynamic>?)
            ?.map((ayah) => AyahModel.fromJson(ayah as Map<String, dynamic>))
            .toList() ??
        [];

    return SurahModel(
      number: (json['number'] as num?)?.toInt() ?? 0,
      name: json['englishName'] as String? ?? json['name'] as String? ?? '',
      nameArabic: json['name'] as String? ?? '',
      englishNameTranslation: json['englishNameTranslation'] as String? ?? '',
      revelationType: json['revelationType'] as String? ?? 'Meccan',
      // v7.0 FIX: Fallback to actual ayah count if numberOfAyahs missing
      numberOfAyahs:
          (json['numberOfAyahs'] as num?)?.toInt() ?? parsedAyahs.length,
      ayahs: parsedAyahs,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': nameArabic,
      'englishName': name,
      'englishNameTranslation': englishNameTranslation,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
    };
  }

  /// Copy with optional new values
  SurahModel copyWith({
    int? number,
    String? name,
    String? nameArabic,
    String? englishNameTranslation,
    String? revelationType,
    int? numberOfAyahs,
    List<AyahModel>? ayahs,
  }) {
    return SurahModel(
      number: number ?? this.number,
      name: name ?? this.name,
      nameArabic: nameArabic ?? this.nameArabic,
      englishNameTranslation:
          englishNameTranslation ?? this.englishNameTranslation,
      revelationType: revelationType ?? this.revelationType,
      numberOfAyahs: numberOfAyahs ?? this.numberOfAyahs,
      ayahs: ayahs ?? this.ayahs,
    );
  }

  // ── Helper getters ────────────────────────────────────
  bool get isMeccan => revelationType.toLowerCase() == 'meccan';
  bool get isMedinan => revelationType.toLowerCase() == 'medinan';
  String get displayName => '$number. $name';
  String get formattedName => '$name ($nameArabic)';

  /// Get ayah by number (1-based)
  AyahModel? getAyahByNumber(int ayahNumber) {
    try {
      return ayahs.firstWhere((ayah) => ayah.number == ayahNumber);
    } catch (e) {
      return null;
    }
  }

  /// Get first ayah
  AyahModel? get firstAyah => ayahs.isNotEmpty ? ayahs.first : null;

  /// Get last ayah
  AyahModel? get lastAyah => ayahs.isNotEmpty ? ayahs.last : null;

  @override
  List<Object?> get props => [
        number,
        name,
        nameArabic,
        englishNameTranslation,
        revelationType,
        numberOfAyahs,
        ayahs,
      ];

  @override
  String toString() =>
      'SurahModel($number, $name, $numberOfAyahs ayahs, $revelationType)';
}

// ============================================================
// SECTION 2 — AYAH MODEL (Single Verse)
// ============================================================

/// Single verse (ayah) with Arabic + optional translation
class AyahModel extends Equatable {
  final int number;
  final int numberInQuran;
  final String text;
  final String? translation;
  final int juz;
  final int page;
  final int? ruku;
  final bool sajdah;
  final int? hizbQuarter;

  const AyahModel({
    required this.number,
    required this.numberInQuran,
    required this.text,
    this.translation,
    required this.juz,
    required this.page,
    this.ruku,
    this.sajdah = false,
    this.hizbQuarter,
  });

  /// Parse from alquran.cloud API JSON
  factory AyahModel.fromJson(Map<String, dynamic> json) {
    // Handle sajdah (can be bool or object)
    bool sajdahValue = false;
    final dynamic sajdaData = json['sajda'];
    if (sajdaData is bool) {
      sajdahValue = sajdaData;
    } else if (sajdaData is Map<String, dynamic>) {
      sajdahValue = (sajdaData['obligatory'] as bool?) ?? false;
    }

    return AyahModel(
      number: (json['numberInSurah'] as num?)?.toInt() ??
          (json['number'] as num?)?.toInt() ??
          0,
      numberInQuran: (json['number'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String?,
      juz: (json['juz'] as num?)?.toInt() ?? 1,
      page: (json['page'] as num?)?.toInt() ?? 1,
      ruku: (json['ruku'] as num?)?.toInt(),
      sajdah: sajdahValue,
      hizbQuarter: (json['hizbQuarter'] as num?)?.toInt(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'numberInSurah': number,
      'number': numberInQuran,
      'text': text,
      'translation': translation,
      'juz': juz,
      'page': page,
      'ruku': ruku,
      'sajda': sajdah,
      'hizbQuarter': hizbQuarter,
    };
  }

  /// Copy with new translation
  AyahModel copyWithTranslation(String newTranslation) {
    return AyahModel(
      number: number,
      numberInQuran: numberInQuran,
      text: text,
      translation: newTranslation,
      juz: juz,
      page: page,
      ruku: ruku,
      sajdah: sajdah,
      hizbQuarter: hizbQuarter,
    );
  }

  /// Get preview text (first 40 chars)
  String get preview {
    if (text.length <= 40) return text;
    return '${text.substring(0, 40)}...';
  }

  /// Get translation preview
  String get translationPreview {
    if (translation == null || translation!.isEmpty) return '';
    if (translation!.length <= 60) return translation!;
    return '${translation!.substring(0, 60)}...';
  }

  @override
  List<Object?> get props => [
        number,
        numberInQuran,
        text,
        translation,
        juz,
        page,
        ruku,
        sajdah,
        hizbQuarter,
      ];

  @override
  String toString() => 'AyahModel($number: $preview)';
}

// ============================================================
// SECTION 3 — SURAH INFO MODEL (Metadata Only)
// ============================================================

/// Lightweight surah info (for list display without full ayahs)
///
/// Used for: Surah list screen (fast loading)
class SurahInfoModel extends Equatable {
  final int number;
  final String name;
  final String nameArabic;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;

  const SurahInfoModel({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory SurahInfoModel.fromJson(Map<String, dynamic> json) {
    return SurahInfoModel(
      number: (json['number'] as num?)?.toInt() ?? 0,
      name: json['englishName'] as String? ?? '',
      nameArabic: json['name'] as String? ?? '',
      englishNameTranslation: json['englishNameTranslation'] as String? ?? '',
      revelationType: json['revelationType'] as String? ?? 'Meccan',
      numberOfAyahs: (json['numberOfAyahs'] as num?)?.toInt() ?? 0,
    );
  }

  /// Create from full SurahModel
  factory SurahInfoModel.fromSurah(SurahModel surah) {
    return SurahInfoModel(
      number: surah.number,
      name: surah.name,
      nameArabic: surah.nameArabic,
      englishNameTranslation: surah.englishNameTranslation,
      revelationType: surah.revelationType,
      numberOfAyahs: surah.numberOfAyahs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'englishName': name,
      'name': nameArabic,
      'englishNameTranslation': englishNameTranslation,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
    };
  }

  bool get isMeccan => revelationType.toLowerCase() == 'meccan';
  bool get isMedinan => revelationType.toLowerCase() == 'medinan';
  String get displayName => '$number. $name';

  @override
  List<Object?> get props => [
        number,
        name,
        nameArabic,
        englishNameTranslation,
        revelationType,
        numberOfAyahs,
      ];

  @override
  String toString() => 'SurahInfoModel($number: $name)';
}

// ============================================================
// SECTION 4 — BOOKMARK MODEL
// ============================================================

/// User's bookmark on a specific ayah
class BookmarkModel extends Equatable {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final DateTime bookmarkedAt;
  final String? note;

  const BookmarkModel({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.bookmarkedAt,
    this.note,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
      surahName: json['surahName'] as String? ?? '',
      ayahText: json['ayahText'] as String? ?? '',
      bookmarkedAt: DateTime.tryParse(json['bookmarkedAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'ayahText': ayahText,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
      'note': note,
    };
  }

  /// Copy with updated note
  BookmarkModel copyWithNote(String? newNote) {
    return BookmarkModel(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      ayahText: ayahText,
      bookmarkedAt: bookmarkedAt,
      note: newNote,
    );
  }

  /// Unique key for storage
  String get key => '${surahNumber}_$ayahNumber';

  /// Formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(bookmarkedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${bookmarkedAt.day}/${bookmarkedAt.month}/${bookmarkedAt.year}';
    }
  }

  @override
  List<Object?> get props => [
        surahNumber,
        ayahNumber,
        surahName,
        ayahText,
        bookmarkedAt,
        note,
      ];

  @override
  String toString() => 'BookmarkModel($surahName $surahNumber:$ayahNumber)';
}

// ============================================================
// SECTION 5 — LAST READ POSITION
// ============================================================

/// Track user's last read position
class LastReadModel extends Equatable {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime lastReadAt;
  final int totalAyahsInSurah;

  const LastReadModel({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.lastReadAt,
    required this.totalAyahsInSurah,
  });

  factory LastReadModel.fromJson(Map<String, dynamic> json) {
    return LastReadModel(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      surahName: json['surahName'] as String? ?? 'Al-Fatihah',
      lastReadAt: DateTime.tryParse(json['lastReadAt'] as String? ?? '') ??
          DateTime.now(),
      totalAyahsInSurah: (json['totalAyahsInSurah'] as num?)?.toInt() ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'lastReadAt': lastReadAt.toIso8601String(),
      'totalAyahsInSurah': totalAyahsInSurah,
    };
  }

  /// Progress percentage in current surah (0.0 - 1.0)
  double get progressInSurah {
    if (totalAyahsInSurah == 0) return 0.0;
    return ayahNumber / totalAyahsInSurah;
  }

  /// Progress percentage as integer (0-100)
  int get progressPercentage => (progressInSurah * 100).round();

  /// Time since last read
  Duration get timeSinceLastRead => DateTime.now().difference(lastReadAt);

  /// Human readable time
  String get timeSinceLastReadFormatted {
    final duration = timeSinceLastRead;
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else if (duration.inDays < 7) {
      return '${duration.inDays} days ago';
    } else {
      return '${lastReadAt.day}/${lastReadAt.month}/${lastReadAt.year}';
    }
  }

  /// Is this recent (within last 24 hours)?
  bool get isRecent => timeSinceLastRead.inHours < 24;

  @override
  List<Object?> get props => [
        surahNumber,
        ayahNumber,
        surahName,
        lastReadAt,
        totalAyahsInSurah,
      ];

  @override
  String toString() => 'LastReadModel($surahName $surahNumber:$ayahNumber)';
}

// ============================================================
// SECTION 6 — READING PROGRESS
// ============================================================

/// Overall Quran reading progress statistics
class ReadingProgressModel extends Equatable {
  final int totalAyahsRead;
  final int totalAyahs;
  final int currentJuz;
  final int totalJuz;
  final int currentSurah;
  final int daysStreak;
  final int totalMinutesRead;
  final DateTime? firstReadDate;
  final DateTime? lastReadDate;

  const ReadingProgressModel({
    required this.totalAyahsRead,
    this.totalAyahs = 6236,
    required this.currentJuz,
    this.totalJuz = 30,
    required this.currentSurah,
    required this.daysStreak,
    this.totalMinutesRead = 0,
    this.firstReadDate,
    this.lastReadDate,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      totalAyahsRead: (json['totalAyahsRead'] as num?)?.toInt() ?? 0,
      totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 6236,
      currentJuz: (json['currentJuz'] as num?)?.toInt() ?? 1,
      totalJuz: (json['totalJuz'] as num?)?.toInt() ?? 30,
      currentSurah: (json['currentSurah'] as num?)?.toInt() ?? 1,
      daysStreak: (json['daysStreak'] as num?)?.toInt() ?? 0,
      totalMinutesRead: (json['totalMinutesRead'] as num?)?.toInt() ?? 0,
      firstReadDate: json['firstReadDate'] != null
          ? DateTime.tryParse(json['firstReadDate'] as String)
          : null,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.tryParse(json['lastReadDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAyahsRead': totalAyahsRead,
      'totalAyahs': totalAyahs,
      'currentJuz': currentJuz,
      'totalJuz': totalJuz,
      'currentSurah': currentSurah,
      'daysStreak': daysStreak,
      'totalMinutesRead': totalMinutesRead,
      'firstReadDate': firstReadDate?.toIso8601String(),
      'lastReadDate': lastReadDate?.toIso8601String(),
    };
  }

  /// Empty/default progress
  factory ReadingProgressModel.empty() {
    return const ReadingProgressModel(
      totalAyahsRead: 0,
      currentJuz: 1,
      currentSurah: 1,
      daysStreak: 0,
    );
  }

  /// Copy with new values
  ReadingProgressModel copyWith({
    int? totalAyahsRead,
    int? totalAyahs,
    int? currentJuz,
    int? totalJuz,
    int? currentSurah,
    int? daysStreak,
    int? totalMinutesRead,
    DateTime? firstReadDate,
    DateTime? lastReadDate,
  }) {
    return ReadingProgressModel(
      totalAyahsRead: totalAyahsRead ?? this.totalAyahsRead,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      currentJuz: currentJuz ?? this.currentJuz,
      totalJuz: totalJuz ?? this.totalJuz,
      currentSurah: currentSurah ?? this.currentSurah,
      daysStreak: daysStreak ?? this.daysStreak,
      totalMinutesRead: totalMinutesRead ?? this.totalMinutesRead,
      firstReadDate: firstReadDate ?? this.firstReadDate,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }

  // ── Helper getters ────────────────────────────────────

  /// Overall progress (0.0 - 1.0)
  double get overallProgress {
    if (totalAyahs == 0) return 0.0;
    return totalAyahsRead / totalAyahs;
  }

  /// Progress percentage (0-100)
  int get progressPercentage => (overallProgress * 100).round();

  /// Juz progress (0.0 - 1.0)
  double get juzProgress => currentJuz / totalJuz;

  /// Juz progress percentage
  int get juzProgressPercentage => (juzProgress * 100).round();

  /// Has any progress?
  bool get hasProgress => totalAyahsRead > 0;

  /// Is complete?
  bool get isComplete => totalAyahsRead >= totalAyahs;

  /// Days remaining to finish (if reading same pace)
  int? get daysToComplete {
    if (daysStreak == 0 || isComplete) return null;
    final ayahsRemaining = totalAyahs - totalAyahsRead;
    final avgAyahsPerDay = totalAyahsRead / daysStreak;
    if (avgAyahsPerDay == 0) return null;
    return (ayahsRemaining / avgAyahsPerDay).ceil();
  }

  @override
  List<Object?> get props => [
        totalAyahsRead,
        totalAyahs,
        currentJuz,
        totalJuz,
        currentSurah,
        daysStreak,
        totalMinutesRead,
        firstReadDate,
        lastReadDate,
      ];

  @override
  String toString() =>
      'ReadingProgressModel($progressPercentage%, Juz $currentJuz/$totalJuz, $daysStreak days)';
}

// ============================================================
// SECTION 7 — JUZ MODEL (Optional - for Juz screen)
// ============================================================

/// Juz (Para) information
class JuzModel extends Equatable {
  final int number;
  final String name;
  final String nameArabic;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final int totalAyahs;

  const JuzModel({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.totalAyahs,
  });

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      startSurah: (json['startSurah'] as num?)?.toInt() ?? 1,
      startAyah: (json['startAyah'] as num?)?.toInt() ?? 1,
      endSurah: (json['endSurah'] as num?)?.toInt() ?? 1,
      endAyah: (json['endAyah'] as num?)?.toInt() ?? 1,
      totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'nameArabic': nameArabic,
      'startSurah': startSurah,
      'startAyah': startAyah,
      'endSurah': endSurah,
      'endAyah': endAyah,
      'totalAyahs': totalAyahs,
    };
  }

  String get displayName => 'Juz $number';
  String get displayNameFull => 'Juz $number - $name';

  @override
  List<Object?> get props => [
        number,
        name,
        nameArabic,
        startSurah,
        startAyah,
        endSurah,
        endAyah,
        totalAyahs,
      ];

  @override
  String toString() => 'JuzModel($number: $name)';
}

// ============================================================
// SECTION 8 — SEARCH RESULT MODEL
// ============================================================

/// Search result for Quran search
class SearchResultModel extends Equatable {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String? translation;
  final String matchedText;
  final int matchType; // 0=Arabic, 1=Translation

  const SearchResultModel({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    this.translation,
    required this.matchedText,
    required this.matchType,
  });

  bool get isArabicMatch => matchType == 0;
  bool get isTranslationMatch => matchType == 1;

  @override
  List<Object?> get props => [
        surahNumber,
        surahName,
        ayahNumber,
        ayahText,
        translation,
        matchedText,
        matchType,
      ];
}

// ============================================================
// END OF FILE — quran_models.dart
// ============================================================
