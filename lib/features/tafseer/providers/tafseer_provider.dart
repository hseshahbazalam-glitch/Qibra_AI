// lib/features/tafseer/providers/tafseer_provider.dart

// ============================================================
// QIBRA AI — TAFSEER PROVIDER
// Version: 1.0.0
// Description: Riverpod state management for Tafseer Ibn Kathir.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/tafseer_service.dart';

// ============================================================
// SERVICE PROVIDER
// ============================================================

/// Tafseer service singleton
final tafseerServiceProvider = Provider<TafseerService>((ref) {
  return TafseerService();
});

// ============================================================
// SURAH TAFSEER PROVIDER
// ============================================================

/// Get all tafseer ayahs for a specific surah
///
/// Usage:
///   final tafseerAsync = ref.watch(surahTafseerProvider(1));
///   tafseerAsync.when(
///     data: (ayahs) => ...,
///     loading: () => ...,
///     error: (e, s) => ...,
///   );
final surahTafseerProvider =
    FutureProvider.family<List<TafseerAyah>, int>((ref, surahNumber) async {
  final service = ref.watch(tafseerServiceProvider);
  return await service.getSurahTafseer(surahNumber);
});

// ============================================================
// AYAH TAFSEER PROVIDER
// ============================================================

/// Get tafseer for specific ayah
///
/// Usage:
///   final tafseerAsync = ref.watch(
///     ayahTafseerProvider((surah: 1, ayah: 1)),
///   );
final ayahTafseerProvider =
    FutureProvider.family<TafseerAyah?, ({int surah, int ayah})>(
        (ref, params) async {
  final service = ref.watch(tafseerServiceProvider);
  return await service.getAyahTafseer(params.surah, params.ayah);
});

// ============================================================
// CONVENIENCE PROVIDERS
// ============================================================

/// Check if tafseer data available for a surah
final hasTafseerProvider = Provider.family<bool, int>((ref, surahNumber) {
  final tafseerAsync = ref.watch(surahTafseerProvider(surahNumber));
  return tafseerAsync.when(
    data: (ayahs) => ayahs.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Cache statistics
final tafseerStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(tafseerServiceProvider);
  return service.statistics;
});
