// lib/features/duas/providers/dua_provider.dart

// ============================================================
// QIBRA AI — DUA PROVIDER (Riverpod)
// State management for Duas module
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/dua_model.dart';
import '../data/database/dua_database.dart';

// ============================================================
// SHARED PREFERENCES KEYS
// ============================================================

const _kFavoriteDuasKey = 'favorite_duas';

// ============================================================
// 1. CATEGORIES PROVIDER
// ============================================================

final duaCategoriesProvider = Provider<List<DuaCategoryModel>>((ref) {
  return DuaDatabase.getCategoriesWithCount();
});

// ============================================================
// 2. SELECTED CATEGORY PROVIDER
// ============================================================

final selectedDuaCategoryProvider = StateProvider<String?>((ref) => null);

// ============================================================
// 3. SEARCH QUERY PROVIDER
// ============================================================

final duaSearchQueryProvider = StateProvider<String>((ref) => '');

// ============================================================
// 4. FILTERED DUAS PROVIDER
// ============================================================

final filteredDuasProvider = Provider<List<DuaModel>>((ref) {
  final selectedCategory = ref.watch(selectedDuaCategoryProvider);
  final searchQuery = ref.watch(duaSearchQueryProvider);
  final favorites = ref.watch(favoriteDuaIdsProvider);

  List<DuaModel> result;

  // Search mode
  if (searchQuery.isNotEmpty) {
    result = DuaDatabase.search(searchQuery);
  }
  // Category filter
  else if (selectedCategory != null) {
    result = DuaDatabase.getByCategory(selectedCategory);
  }
  // All duas
  else {
    result = List.from(DuaDatabase.duas);
  }

  // Inject favorite status
  return result.map((dua) {
    return dua.copyWith(isFavorite: favorites.contains(dua.id));
  }).toList();
});

// ============================================================
// 5. DAILY DUA PROVIDER
// ============================================================

final dailyDuaProvider = Provider<DuaModel>((ref) {
  final favorites = ref.watch(favoriteDuaIdsProvider);
  final dua = DuaDatabase.getDailyDua();
  return dua.copyWith(isFavorite: favorites.contains(dua.id));
});

// ============================================================
// 6. FAVORITE DUAS — IDs PROVIDER (from SharedPreferences)
// ============================================================

final favoriteDuaIdsProvider =
    StateNotifierProvider<FavoriteDuasNotifier, Set<String>>((ref) {
  return FavoriteDuasNotifier();
});

class FavoriteDuasNotifier extends StateNotifier<Set<String>> {
  FavoriteDuasNotifier() : super({}) {
    _loadFavorites();
  }

  // Load from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kFavoriteDuasKey) ?? [];
      state = Set<String>.from(list);
    } catch (_) {
      state = {};
    }
  }

  // Save to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavoriteDuasKey, state.toList());
    } catch (_) {}
  }

  // Toggle favorite
  Future<void> toggleFavorite(String duaId) async {
    if (state.contains(duaId)) {
      state = Set<String>.from(state)..remove(duaId);
    } else {
      state = Set<String>.from(state)..add(duaId);
    }
    await _saveFavorites();
  }

  // Check if favorite
  bool isFavorite(String duaId) => state.contains(duaId);
}

// ============================================================
// 7. FAVORITE DUAS LIST PROVIDER
// ============================================================

final favoriteDuasProvider = Provider<List<DuaModel>>((ref) {
  final favoriteIds = ref.watch(favoriteDuaIdsProvider);
  if (favoriteIds.isEmpty) return [];

  return DuaDatabase.duas
      .where((d) => favoriteIds.contains(d.id))
      .map((d) => d.copyWith(isFavorite: true))
      .toList();
});

// ============================================================
// 8. SINGLE DUA PROVIDER (by ID)
// ============================================================

final duaByIdProvider = Provider.family<DuaModel?, String>((ref, id) {
  final favorites = ref.watch(favoriteDuaIdsProvider);
  try {
    final dua = DuaDatabase.duas.firstWhere((d) => d.id == id);
    return dua.copyWith(isFavorite: favorites.contains(dua.id));
  } catch (_) {
    return null;
  }
});

// ============================================================
// 9. DUAS BY CATEGORY PROVIDER (family)
// ============================================================

final duasByCategoryProvider =
    Provider.family<List<DuaModel>, String>((ref, categoryId) {
  final favorites = ref.watch(favoriteDuaIdsProvider);
  return DuaDatabase.getByCategory(categoryId).map((dua) {
    return dua.copyWith(isFavorite: favorites.contains(dua.id));
  }).toList();
});

// ============================================================
// 10. DUA STATS PROVIDER
// ============================================================

final duaStatsProvider = Provider<DuaStats>((ref) {
  final favorites = ref.watch(favoriteDuaIdsProvider);
  return DuaStats(
    totalDuas: DuaDatabase.duas.length,
    totalCategories: DuaDatabase.categories.length,
    favoritesCount: favorites.length,
  );
});

class DuaStats {
  final int totalDuas;
  final int totalCategories;
  final int favoritesCount;

  const DuaStats({
    required this.totalDuas,
    required this.totalCategories,
    required this.favoritesCount,
  });
}
