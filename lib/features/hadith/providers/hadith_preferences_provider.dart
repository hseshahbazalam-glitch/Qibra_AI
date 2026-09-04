// lib/features/hadith/providers/hadith_preferences_provider.dart
// ============================================================
// QIBRA AI — HADITH READING PREFERENCES (world-class hadith pass, item 1)
// ============================================================
// Mirrors the Quran pass's split-scale pattern (arabicScale for the
// Arabic matn, translationScale for the translation bodies). Mirrored,
// NOT shared: quran's ReadingPreferences also owns translation ids,
// transliteration and reading-mode fields that a hadith surface must
// neither persist nor be invalidated by. The clamp range, the load-time
// clamp discipline, and the honest best-effort storage handling are the
// same pattern, deliberately so.
//
// No legacy single-scale key exists for hadith (hadith text sizes were
// hardcoded before this pass), so the only migration rule here is
// "missing key -> default 1.0"; the clamp bounds make any foreign value
// unreadable-as-is land inside [scaleMin, scaleMax].

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted hadith reading scales. Plain immutable value type — the
/// clamps are static and pure so the unit test can pin them without
/// touching SharedPreferences.
class HadithReadingPreferences {
  const HadithReadingPreferences({
    this.arabicScale = 1.0,
    this.translationScale = 1.0,
  });

  static const double scaleMin = 0.8;
  static const double scaleMax = 1.6;

  final double arabicScale;
  final double translationScale;

  /// Clamp rule (same range and semantics as the Quran split scales).
  static double clampScale(double v) => v.clamp(scaleMin, scaleMax);

  HadithReadingPreferences copyWith({
    double? arabicScale,
    double? translationScale,
  }) {
    return HadithReadingPreferences(
      arabicScale: arabicScale ?? this.arabicScale,
      translationScale: translationScale ?? this.translationScale,
    );
  }
}

class HadithReadingPreferencesNotifier
    extends StateNotifier<HadithReadingPreferences> {
  HadithReadingPreferencesNotifier() : super(const HadithReadingPreferences()) {
    _load();
  }

  static const _keyArabic = 'hadith_reading_scale_v1_arabic';
  static const _keyTranslation = 'hadith_reading_scale_v1_translation';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final arabic = prefs.getDouble(_keyArabic);
      final translation = prefs.getDouble(_keyTranslation);
      state = HadithReadingPreferences(
        arabicScale: HadithReadingPreferences.clampScale(arabic ?? 1.0),
        translationScale:
            HadithReadingPreferences.clampScale(translation ?? 1.0),
      );
    } catch (_) {
      // Unreadable storage: defaults are the honest state, not a lie.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyArabic, state.arabicScale);
      await prefs.setDouble(_keyTranslation, state.translationScale);
    } catch (_) {
      // Persisting is best-effort; the in-session scale stays truthful.
    }
  }

  Future<void> setArabicScale(double value) async {
    state = state.copyWith(
      arabicScale: HadithReadingPreferences.clampScale(value),
    );
    await _save();
  }

  Future<void> setTranslationScale(double value) async {
    state = state.copyWith(
      translationScale: HadithReadingPreferences.clampScale(value),
    );
    await _save();
  }
}

final hadithReadingPreferencesProvider = StateNotifierProvider<
    HadithReadingPreferencesNotifier, HadithReadingPreferences>((ref) {
  return HadithReadingPreferencesNotifier();
});
