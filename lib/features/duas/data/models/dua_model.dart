// lib/features/duas/data/models/dua_model.dart

// ============================================================
// QIBRA AI — DUA MODEL
// Complete data structure for each Dua
// ============================================================

class DuaModel {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String titleUrdu;
  final String arabic;
  final String transliteration;
  final String translationUrdu;
  final String translationEnglish;
  final String reference; // e.g. "Sahih al-Bukhari 6311"
  final String referenceBook; // e.g. "Sahih al-Bukhari"
  final String referenceNumber; // e.g. "6311"
  final String grade; // e.g. "Sahih", "Hasan"
  final String whenToRecite;
  final String howToRecite;
  final String benefits;
  final String category; // category id
  final List<String> tags;
  final bool isFavorite;
  final int sortOrder;

  const DuaModel({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.titleUrdu,
    required this.arabic,
    required this.transliteration,
    required this.translationUrdu,
    required this.translationEnglish,
    required this.reference,
    required this.referenceBook,
    required this.referenceNumber,
    required this.grade,
    required this.whenToRecite,
    required this.howToRecite,
    required this.benefits,
    required this.category,
    this.tags = const [],
    this.isFavorite = false,
    this.sortOrder = 0,
  });

  DuaModel copyWith({
    String? id,
    String? titleArabic,
    String? titleEnglish,
    String? titleUrdu,
    String? arabic,
    String? transliteration,
    String? translationUrdu,
    String? translationEnglish,
    String? reference,
    String? referenceBook,
    String? referenceNumber,
    String? grade,
    String? whenToRecite,
    String? howToRecite,
    String? benefits,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    int? sortOrder,
  }) {
    return DuaModel(
      id: id ?? this.id,
      titleArabic: titleArabic ?? this.titleArabic,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      titleUrdu: titleUrdu ?? this.titleUrdu,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      translationUrdu: translationUrdu ?? this.translationUrdu,
      translationEnglish: translationEnglish ?? this.translationEnglish,
      reference: reference ?? this.reference,
      referenceBook: referenceBook ?? this.referenceBook,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      grade: grade ?? this.grade,
      whenToRecite: whenToRecite ?? this.whenToRecite,
      howToRecite: howToRecite ?? this.howToRecite,
      benefits: benefits ?? this.benefits,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DuaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ============================================================
// DUA CATEGORY MODEL
// ============================================================

class DuaCategoryModel {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String nameUrdu;
  final String icon; // emoji icon
  final String colorHex; // hex color string
  final int duaCount;
  final int sortOrder;

  const DuaCategoryModel({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameUrdu,
    required this.icon,
    required this.colorHex,
    this.duaCount = 0,
    this.sortOrder = 0,
  });
}
