// lib/features/duas/data/models/dua_model.dart

// ============================================================
// QIBRA AI — DUA MODEL
// Complete data structure for each Dua
// ============================================================

import 'package:flutter/material.dart';

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

/// Category rows carry legacy emoji strings as icon KEYS in the seed data.
/// Presentation must never render them raw — this maps each key onto the
/// app's single icon language (Stage D). colorHex (legacy per-category
/// palette) is deliberately left unread by any screen: one accent per
/// domain beats a rainbow.
extension DuaCategoryGlyph on DuaCategoryModel {
  IconData get iconGlyph {
    // Match on the leading code point so variation selectors (U+FE0F)
    // in the seed data can't silently break the mapping.
    final lead = icon.runes.isEmpty ? 0 : icon.runes.first;
    switch (lead) {
      case 0x1F305:
        return Icons.wb_twilight; // dawn
      case 0x2600:
        return Icons.wb_sunny; // midday
      case 0x1F319:
        return Icons.nightlight_round; // night
      case 0x1F37D:
        return Icons.restaurant_rounded; // food
      case 0x2708:
        return Icons.flight_takeoff_rounded; // travel
      case 0x1F6D5:
        return Icons.mosque_rounded; // mosque
      case 0x1F4D6:
        return Icons.menu_book_rounded; // scripture
      default:
        return Icons.volunteer_activism_rounded;
    }
  }
}
