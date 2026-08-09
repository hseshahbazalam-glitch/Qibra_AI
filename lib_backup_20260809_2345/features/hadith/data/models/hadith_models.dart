// lib/features/hadith/data/models/hadith_models.dart

// ============================================================
// QIBRA AI — HADITH MODELS (v1.0)
// Phase: 10 — Hadith Module
// ============================================================
// Description: Data models for Hadith collections
//
// Models:
//   ✅ HadithBook       — Book metadata (Bukhari, Muslim, etc.)
//   ✅ HadithChapter    — Chapter within a book
//   ✅ HadithModel      — Single hadith with Arabic + Translation
//   ✅ HadithGrade      — Authenticity grade (Sahih, Hasan, Da'if)
//   ✅ HadithNarrator   — Narrator info
//   ✅ HadithBookmark   — User bookmarks
//   ✅ HadithSearchResult — Search results
//
// API: hadithapi.com (free tier)
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ============================================================
// SECTION 1 — HADITH GRADE (Authenticity)
// ============================================================

enum HadithGrade {
  sahih('Sahih', 'صحيح', 'Authentic', Color(0xFF00A86B)),
  hasan('Hasan', 'حسن', 'Good', Color(0xFF0891B2)),
  daif('Daif', 'ضعيف', 'Weak', Color(0xFFF59E0B)),
  mawdu('Mawdu', 'موضوع', 'Fabricated', Color(0xFFEF4444)),
  unknown('Unknown', 'غير معروف', 'Unknown grade', Color(0xFF6B7280));

  const HadithGrade(this.label, this.arabicLabel, this.description, this.color);

  final String label;
  final String arabicLabel;
  final String description;
  final Color color;

  /// Parse grade from API string
  static HadithGrade fromString(String? value) {
    if (value == null) return HadithGrade.unknown;
    final lower = value.toLowerCase().trim();

    if (lower.contains('sahih') || lower.contains('صحيح')) {
      return HadithGrade.sahih;
    }
    if (lower.contains('hasan') || lower.contains('حسن')) {
      return HadithGrade.hasan;
    }
    if (lower.contains('daif') ||
        lower.contains('da\'if') ||
        lower.contains('ضعيف')) {
      return HadithGrade.daif;
    }
    if (lower.contains('mawdu') || lower.contains('موضوع')) {
      return HadithGrade.mawdu;
    }
    return HadithGrade.unknown;
  }

  IconData get icon {
    switch (this) {
      case HadithGrade.sahih:
        return Icons.verified_rounded;
      case HadithGrade.hasan:
        return Icons.check_circle_rounded;
      case HadithGrade.daif:
        return Icons.warning_rounded;
      case HadithGrade.mawdu:
        return Icons.error_rounded;
      case HadithGrade.unknown:
        return Icons.help_rounded;
    }
  }
}

// ============================================================
// SECTION 2 — HADITH BOOK
// ============================================================

class HadithBook extends Equatable {
  const HadithBook({
    required this.id,
    required this.slug,
    required this.name,
    required this.nameArabic,
    required this.author,
    required this.authorArabic,
    required this.totalHadiths,
    required this.totalChapters,
    required this.description,
    required this.color,
    this.compiledYear,
    this.isFavorite = false,
  });

  final String id;
  final String slug; // 'bukhari', 'muslim', etc.
  final String name;
  final String nameArabic;
  final String author;
  final String authorArabic;
  final int totalHadiths;
  final int totalChapters;
  final String description;
  final Color color;
  final String? compiledYear;
  final bool isFavorite;

  /// Parse from API JSON
  factory HadithBook.fromJson(Map<String, dynamic> json) {
    return HadithBook(
      id: json['id']?.toString() ?? '',
      slug: json['bookSlug'] as String? ?? json['slug'] as String? ?? '',
      name: json['bookName'] as String? ?? json['name'] as String? ?? '',
      nameArabic: json['bookNameArabic'] as String? ??
          json['nameArabic'] as String? ??
          '',
      author: json['writerName'] as String? ?? json['author'] as String? ?? '',
      authorArabic: json['writerNameArabic'] as String? ??
          json['authorArabic'] as String? ??
          '',
      totalHadiths: (json['hadiths_count'] as num?)?.toInt() ??
          (json['totalHadiths'] as num?)?.toInt() ??
          0,
      totalChapters: (json['chapters_count'] as num?)?.toInt() ??
          (json['totalChapters'] as num?)?.toInt() ??
          0,
      description: json['description'] as String? ?? '',
      color: _parseColor(json['color'] as String?),
      compiledYear: json['compiledYear'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'nameArabic': nameArabic,
      'author': author,
      'authorArabic': authorArabic,
      'totalHadiths': totalHadiths,
      'totalChapters': totalChapters,
      'description': description,
      'color': '#${color.toARGB32().toRadixString(16).substring(2)}',
      'compiledYear': compiledYear,
      'isFavorite': isFavorite,
    };
  }

  HadithBook copyWith({
    String? id,
    String? slug,
    String? name,
    String? nameArabic,
    String? author,
    String? authorArabic,
    int? totalHadiths,
    int? totalChapters,
    String? description,
    Color? color,
    String? compiledYear,
    bool? isFavorite,
  }) {
    return HadithBook(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      nameArabic: nameArabic ?? this.nameArabic,
      author: author ?? this.author,
      authorArabic: authorArabic ?? this.authorArabic,
      totalHadiths: totalHadiths ?? this.totalHadiths,
      totalChapters: totalChapters ?? this.totalChapters,
      description: description ?? this.description,
      color: color ?? this.color,
      compiledYear: compiledYear ?? this.compiledYear,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        name,
        nameArabic,
        author,
        totalHadiths,
        totalChapters,
        isFavorite,
      ];

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF00A86B);
    try {
      final cleanHex = hex.replaceAll('#', '');
      final value = int.parse('FF$cleanHex', radix: 16);
      return Color(value);
    } catch (_) {
      return const Color(0xFF00A86B);
    }
  }
}

// ============================================================
// SECTION 3 — HADITH CHAPTER
// ============================================================

class HadithChapter extends Equatable {
  const HadithChapter({
    required this.id,
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.bookSlug,
    required this.hadithCount,
    this.description,
  });

  final String id;
  final int number;
  final String name;
  final String nameArabic;
  final String bookSlug;
  final int hadithCount;
  final String? description;

  factory HadithChapter.fromJson(Map<String, dynamic> json) {
    return HadithChapter(
      id: json['id']?.toString() ?? '',
      number: (json['chapterNumber'] as num?)?.toInt() ??
          (json['number'] as num?)?.toInt() ??
          0,
      name: json['chapterEnglish'] as String? ??
          json['name'] as String? ??
          json['chapterName'] as String? ??
          '',
      nameArabic: json['chapterArabic'] as String? ??
          json['nameArabic'] as String? ??
          '',
      bookSlug: json['bookSlug'] as String? ?? '',
      hadithCount: (json['hadiths_count'] as num?)?.toInt() ??
          (json['hadithCount'] as num?)?.toInt() ??
          0,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'nameArabic': nameArabic,
      'bookSlug': bookSlug,
      'hadithCount': hadithCount,
      'description': description,
    };
  }

  String get displayName => '$number. $name';

  @override
  List<Object?> get props =>
      [id, number, name, nameArabic, bookSlug, hadithCount];
}

// ============================================================
// SECTION 4 — HADITH NARRATOR
// ============================================================

class HadithNarrator extends Equatable {
  const HadithNarrator({
    required this.name,
    this.nameArabic,
    this.title,
    this.death,
  });

  final String name;
  final String? nameArabic;
  final String? title; // e.g., "Companion (RA)"
  final String? death; // e.g., "58 AH"

  factory HadithNarrator.fromJson(Map<String, dynamic> json) {
    return HadithNarrator(
      name: json['name'] as String? ?? '',
      nameArabic: json['nameArabic'] as String?,
      title: json['title'] as String?,
      death: json['death'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameArabic': nameArabic,
      'title': title,
      'death': death,
    };
  }

  String get displayName {
    if (title != null && title!.isNotEmpty) {
      return '$name ($title)';
    }
    return name;
  }

  @override
  List<Object?> get props => [name, nameArabic, title, death];
}

// ============================================================
// SECTION 5 — HADITH MODEL (Main)
// ============================================================

class HadithModel extends Equatable {
  const HadithModel({
    required this.id,
    required this.hadithNumber,
    required this.bookSlug,
    required this.bookName,
    required this.chapterNumber,
    required this.chapterName,
    required this.textArabic,
    required this.textEnglish,
    required this.textUrdu,
    required this.grade,
    required this.narrator,
    this.reference,
    this.chainOfNarration,
    this.explanation,
    this.tags = const [],
    this.isBookmarked = false,
    this.isFavorite = false,
  });

  final String id;
  final int hadithNumber;
  final String bookSlug;
  final String bookName;
  final int chapterNumber;
  final String chapterName;
  final String textArabic;
  final String textEnglish;
  final String textUrdu;
  final HadithGrade grade;
  final HadithNarrator narrator;
  final String? reference; // e.g., "Sahih al-Bukhari 1"
  final String? chainOfNarration;
  final String? explanation;
  final List<String> tags;
  final bool isBookmarked;
  final bool isFavorite;

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    // Handle nested book info
    final bookData = json['book'] as Map<String, dynamic>?;
    final chapterData = json['chapter'] as Map<String, dynamic>?;

    return HadithModel(
      id: json['id']?.toString() ?? '',
      hadithNumber: (json['hadithNumber'] as num?)?.toInt() ??
          (json['number'] as num?)?.toInt() ??
          0,
      bookSlug:
          bookData?['bookSlug'] as String? ?? json['bookSlug'] as String? ?? '',
      bookName:
          bookData?['bookName'] as String? ?? json['bookName'] as String? ?? '',
      chapterNumber: (chapterData?['chapterNumber'] as num?)?.toInt() ??
          (json['chapterNumber'] as num?)?.toInt() ??
          0,
      chapterName: chapterData?['chapterEnglish'] as String? ??
          json['chapterName'] as String? ??
          '',
      textArabic: json['hadithArabic'] as String? ??
          json['arabic'] as String? ??
          json['textArabic'] as String? ??
          '',
      textEnglish: json['hadithEnglish'] as String? ??
          json['english'] as String? ??
          json['textEnglish'] as String? ??
          '',
      textUrdu: json['hadithUrdu'] as String? ??
          json['urdu'] as String? ??
          json['textUrdu'] as String? ??
          '',
      grade: HadithGrade.fromString(
        json['status'] as String? ?? json['grade'] as String?,
      ),
      narrator: HadithNarrator.fromJson({
        'name': json['englishNarrator'] as String? ??
            json['narrator'] as String? ??
            'Unknown',
        'nameArabic':
            json['arabicNarrator'] as String? ?? json['narratorArabic'],
      }),
      reference: json['reference'] as String?,
      chainOfNarration: json['chain'] as String?,
      explanation: json['explanation'] as String?,
      tags: _parseTags(json['tags']),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hadithNumber': hadithNumber,
      'bookSlug': bookSlug,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'chapterName': chapterName,
      'textArabic': textArabic,
      'textEnglish': textEnglish,
      'textUrdu': textUrdu,
      'grade': grade.name,
      'narrator': narrator.toJson(),
      'reference': reference,
      'chainOfNarration': chainOfNarration,
      'explanation': explanation,
      'tags': tags,
      'isBookmarked': isBookmarked,
      'isFavorite': isFavorite,
    };
  }

  HadithModel copyWith({
    String? id,
    int? hadithNumber,
    String? bookSlug,
    String? bookName,
    int? chapterNumber,
    String? chapterName,
    String? textArabic,
    String? textEnglish,
    String? textUrdu,
    HadithGrade? grade,
    HadithNarrator? narrator,
    String? reference,
    String? chainOfNarration,
    String? explanation,
    List<String>? tags,
    bool? isBookmarked,
    bool? isFavorite,
  }) {
    return HadithModel(
      id: id ?? this.id,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      bookSlug: bookSlug ?? this.bookSlug,
      bookName: bookName ?? this.bookName,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      chapterName: chapterName ?? this.chapterName,
      textArabic: textArabic ?? this.textArabic,
      textEnglish: textEnglish ?? this.textEnglish,
      textUrdu: textUrdu ?? this.textUrdu,
      grade: grade ?? this.grade,
      narrator: narrator ?? this.narrator,
      reference: reference ?? this.reference,
      chainOfNarration: chainOfNarration ?? this.chainOfNarration,
      explanation: explanation ?? this.explanation,
      tags: tags ?? this.tags,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get displayReference {
    if (reference != null && reference!.isNotEmpty) return reference!;
    return '$bookName $hadithNumber';
  }

  String get shortText {
    if (textEnglish.length <= 100) return textEnglish;
    return '${textEnglish.substring(0, 100)}...';
  }

  bool get hasArabic => textArabic.isNotEmpty;
  bool get hasEnglish => textEnglish.isNotEmpty;
  bool get hasUrdu => textUrdu.isNotEmpty;
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;
  bool get hasChain => chainOfNarration != null && chainOfNarration!.isNotEmpty;

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return tags.map((t) => t.toString()).toList();
    }
    if (tags is String) {
      return tags.split(',').map((t) => t.trim()).toList();
    }
    return [];
  }

  @override
  List<Object?> get props => [
        id,
        hadithNumber,
        bookSlug,
        chapterNumber,
        textArabic,
        textEnglish,
        grade,
        isBookmarked,
        isFavorite,
      ];
}

// ============================================================
// SECTION 6 — HADITH BOOKMARK
// ============================================================

class HadithBookmark extends Equatable {
  const HadithBookmark({
    required this.id,
    required this.hadithId,
    required this.bookSlug,
    required this.bookName,
    required this.hadithNumber,
    required this.chapterName,
    required this.textPreview,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String hadithId;
  final String bookSlug;
  final String bookName;
  final int hadithNumber;
  final String chapterName;
  final String textPreview;
  final DateTime createdAt;
  final String? note;

  factory HadithBookmark.fromJson(Map<String, dynamic> json) {
    return HadithBookmark(
      id: json['id'] as String? ?? '',
      hadithId: json['hadithId'] as String? ?? '',
      bookSlug: json['bookSlug'] as String? ?? '',
      bookName: json['bookName'] as String? ?? '',
      hadithNumber: (json['hadithNumber'] as num?)?.toInt() ?? 0,
      chapterName: json['chapterName'] as String? ?? '',
      textPreview: json['textPreview'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hadithId': hadithId,
      'bookSlug': bookSlug,
      'bookName': bookName,
      'hadithNumber': hadithNumber,
      'chapterName': chapterName,
      'textPreview': textPreview,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  HadithBookmark copyWith({
    String? id,
    String? hadithId,
    String? bookSlug,
    String? bookName,
    int? hadithNumber,
    String? chapterName,
    String? textPreview,
    DateTime? createdAt,
    String? note,
  }) {
    return HadithBookmark(
      id: id ?? this.id,
      hadithId: hadithId ?? this.hadithId,
      bookSlug: bookSlug ?? this.bookSlug,
      bookName: bookName ?? this.bookName,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      chapterName: chapterName ?? this.chapterName,
      textPreview: textPreview ?? this.textPreview,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  @override
  List<Object?> get props => [id, hadithId, bookSlug, hadithNumber, createdAt];
}

// ============================================================
// SECTION 7 — HADITH SEARCH RESULT
// ============================================================

class HadithSearchResult extends Equatable {
  const HadithSearchResult({
    required this.hadith,
    required this.matchType,
    required this.matchedText,
    this.relevanceScore = 0.0,
  });

  final HadithModel hadith;
  final HadithMatchType matchType;
  final String matchedText;
  final double relevanceScore;

  @override
  List<Object?> get props =>
      [hadith.id, matchType, matchedText, relevanceScore];
}

enum HadithMatchType {
  arabic('Arabic'),
  english('English'),
  urdu('Urdu'),
  narrator('Narrator'),
  reference('Reference');

  const HadithMatchType(this.label);
  final String label;
}

// ============================================================
// SECTION 8 — POPULAR HADITH BOOKS (Static)
// ============================================================

/// Static list of 6 major hadith books (Kutub al-Sittah)
/// Used when API is unavailable
const List<HadithBook> popularHadithBooks = [
  HadithBook(
    id: 'bukhari',
    slug: 'sahih-bukhari',
    name: 'Sahih al-Bukhari',
    nameArabic: 'صحيح البخاري',
    author: 'Imam Bukhari',
    authorArabic: 'الإمام البخاري',
    totalHadiths: 7563,
    totalChapters: 97,
    description:
        'The most authentic book after the Holy Quran. Compiled by Imam Muhammad al-Bukhari.',
    color: Color(0xFF00A86B),
    compiledYear: '846 CE',
  ),
  HadithBook(
    id: 'muslim',
    slug: 'sahih-muslim',
    name: 'Sahih Muslim',
    nameArabic: 'صحيح مسلم',
    author: 'Imam Muslim',
    authorArabic: 'الإمام مسلم',
    totalHadiths: 7500,
    totalChapters: 56,
    description:
        'Second most authentic hadith collection. Compiled by Imam Muslim ibn al-Hajjaj.',
    color: Color(0xFF0891B2),
    compiledYear: '875 CE',
  ),
  HadithBook(
    id: 'abudawud',
    slug: 'abu-dawood',
    name: 'Sunan Abu Dawud',
    nameArabic: 'سنن أبي داود',
    author: 'Imam Abu Dawud',
    authorArabic: 'الإمام أبو داود',
    totalHadiths: 5274,
    totalChapters: 43,
    description:
        'Collection of hadiths focusing on Islamic jurisprudence and rulings.',
    color: Color(0xFFB45309),
    compiledYear: '888 CE',
  ),
  HadithBook(
    id: 'tirmidhi',
    slug: 'al-tirmidhi',
    name: 'Jami at-Tirmidhi',
    nameArabic: 'جامع الترمذي',
    author: 'Imam Tirmidhi',
    authorArabic: 'الإمام الترمذي',
    totalHadiths: 3956,
    totalChapters: 49,
    description:
        'Comprehensive collection with commentary on the strength of each hadith.',
    color: Color(0xFF7C3AED),
    compiledYear: '892 CE',
  ),
  HadithBook(
    id: 'nasai',
    slug: 'sunan-nasai',
    name: 'Sunan an-Nasa\'i',
    nameArabic: 'سنن النسائي',
    author: 'Imam an-Nasa\'i',
    authorArabic: 'الإمام النسائي',
    totalHadiths: 5761,
    totalChapters: 51,
    description:
        'Known for its strict criteria in accepting hadiths, focusing on chains.',
    color: Color(0xFFF59E0B),
    compiledYear: '915 CE',
  ),
  HadithBook(
    id: 'ibnmajah',
    slug: 'ibn-e-majah',
    name: 'Sunan Ibn Majah',
    nameArabic: 'سنن ابن ماجه',
    author: 'Imam Ibn Majah',
    authorArabic: 'الإمام ابن ماجه',
    totalHadiths: 4341,
    totalChapters: 37,
    description:
        'Sixth of the Kutub al-Sittah, containing many unique hadiths.',
    color: Color(0xFFEC4899),
    compiledYear: '887 CE',
  ),
];

// ============================================================
// END OF FILE — hadith_models.dart
// ============================================================
