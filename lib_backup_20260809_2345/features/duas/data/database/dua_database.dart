// lib/features/duas/data/database/dua_database.dart

// lib/features/duas/data/database/dua_database.dart

import '../models/dua_model.dart'; // ← SIRF YEH CHANGE HUA
import 'categories/dua_categories.dart';
import 'duas/dua_morning_evening.dart';
import 'duas/dua_sleep.dart';
import 'duas/dua_food.dart';
import 'duas/dua_travel.dart';
import 'duas/dua_prayer.dart';
import 'duas/dua_distress.dart';
import 'duas/dua_protection.dart';
import 'duas/dua_forgiveness.dart';
import 'duas/dua_family.dart';
import 'duas/dua_health.dart';
import 'duas/dua_quran.dart';
import 'duas/dua_daily.dart';
import 'duas/dua_special.dart';

class DuaDatabase {
  DuaDatabase._();

  // ============================================================
  // ALL CATEGORIES
  // ============================================================
  static List<DuaCategoryModel> get categories => DuaCategories.all;

  // ============================================================
  // ALL DUAS — Combined from all category files
  // ============================================================
  static List<DuaModel> get duas => [
        ...DuaMorningEvening.duas,
        ...DuaSleep.duas,
        ...DuaFood.duas,
        ...DuaTravel.duas,
        ...DuaPrayer.duas,
        ...DuaDistress.duas,
        ...DuaProtection.duas,
        ...DuaForgiveness.duas,
        ...DuaFamily.duas,
        ...DuaHealth.duas,
        ...DuaQuran.duas,
        ...DuaDaily.duas,
        ...DuaSpecial.duas,
      ];

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get duas by category id
  static List<DuaModel> getByCategory(String categoryId) {
    return duas.where((d) => d.category == categoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Search duas by query
  static List<DuaModel> search(String query) {
    if (query.isEmpty) return duas;
    final q = query.toLowerCase();
    return duas.where((d) {
      return d.titleEnglish.toLowerCase().contains(q) ||
          d.titleUrdu.contains(q) ||
          d.titleArabic.contains(q) ||
          d.translationEnglish.toLowerCase().contains(q) ||
          d.translationUrdu.contains(q) ||
          d.transliteration.toLowerCase().contains(q) ||
          d.tags.any((t) => t.contains(q));
    }).toList();
  }

  /// Get daily dua based on day of year
  static DuaModel getDailyDua() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final allDuas = duas;
    return allDuas[dayOfYear % allDuas.length];
  }

  /// Get category by id
  static DuaCategoryModel? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get categories with dua count
  static List<DuaCategoryModel> getCategoriesWithCount() {
    return categories.map((cat) {
      final count = duas.where((d) => d.category == cat.id).length;
      return DuaCategoryModel(
        id: cat.id,
        nameArabic: cat.nameArabic,
        nameEnglish: cat.nameEnglish,
        nameUrdu: cat.nameUrdu,
        icon: cat.icon,
        colorHex: cat.colorHex,
        duaCount: count,
        sortOrder: cat.sortOrder,
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
