// lib/features/hadith/providers/hadith_preferences_provider.dart
// ============================================================
// QIBRA AI — HADITH READING PREFERENCES
// ============================================================
// HR-3 (owner revision 2): ONE scale for the hadith reader. The world-class
// pass mirrored the Quran reader's SPLIT scales (arabicScale + translationScale)
// and that mirror cost the reader two sliders for one decision — a hadith card
// could show its matn two steps larger than its own translation, which is never
// what a person means when they drag "text size". Hadith keeps a single
// `hadithTextScale` now; the Quran feature keeps its split pair (its Arabic and
// its latin body are genuinely different typefaces with different budgets) and
// is NOT touched here.
//
// Migration rule (max-migration, in the reader's favor): a store that holds the
// two v1 keys folds into `max(arabic, translation)`, so nobody coming from the
// split scales loses size on either axis — shrinking a hadith the user had
// enlarged is the one outcome worse than a stale-looking slider. The fold is
// pure and static so the unit test pins the arithmetic without storage.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted hadith reading scale. Plain immutable value type — the clamps and
/// the migration are static and pure so the unit test can pin them without
/// touching SharedPreferences.
class HadithReadingPreferences {
  const HadithReadingPreferences({this.hadithTextScale = 1.0});

  /// The HR-3 band: 0.85–1.4. The split scales allowed 0.8–1.6 per axis; a
  /// single axis only has to survive one body type at a time, so the range
  /// tightens to what fits the reader card at 320dp without a horizontal
  /// overflow (1.4 is the measured ceiling for the Arabic matn block).
  static const double scaleMin = 0.85;
  static const double scaleMax = 1.4;

  /// Slider discipline: 11 divisions over 0.55 = a clean 0.05 per step, so the
  /// `×` readout never shows 1.2300000000000002-style noise.
  static const int scaleDivisions = 11;

  final double hadithTextScale;

  /// Clamp rule (same SHAPE as the Quran split scales, different bounds).
  static double clampScale(double v) => v.clamp(scaleMin, scaleMax);

  /// Max-migration from the v1 split store. `merged` wins when it exists; two
  /// missing legacies mean a first run (1.0); otherwise the LARGER legacy axis
  /// becomes the single scale. Never reads storage — see the file header.
  static double migrate({
    double? merged,
    double? legacyArabic,
    double? legacyTranslation,
  }) {
    if (merged != null) return clampScale(merged);
    if (legacyArabic == null && legacyTranslation == null) return 1.0;
    final a = legacyArabic ?? 1.0;
    final t = legacyTranslation ?? 1.0;
    return clampScale(a > t ? a : t);
  }

  HadithReadingPreferences copyWith({double? hadithTextScale}) {
    return HadithReadingPreferences(
      hadithTextScale: hadithTextScale ?? this.hadithTextScale,
    );
  }
}

class HadithReadingPreferencesNotifier
    extends StateNotifier<HadithReadingPreferences> {
  HadithReadingPreferencesNotifier() : super(const HadithReadingPreferences()) {
    _load();
  }

  static const _keyScale = 'hadith_reading_scale_v2_text';
  static const _keyLegacyArabic = 'hadith_reading_scale_v1_arabic';
  static const _keyLegacyTranslation = 'hadith_reading_scale_v1_translation';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final merged = prefs.getDouble(_keyScale);
      final legacyArabic = prefs.getDouble(_keyLegacyArabic);
      final legacyTranslation = prefs.getDouble(_keyLegacyTranslation);
      state = HadithReadingPreferences(
        hadithTextScale: HadithReadingPreferences.migrate(
          merged: merged,
          legacyArabic: legacyArabic,
          legacyTranslation: legacyTranslation,
        ),
      );
      if (merged == null &&
          (legacyArabic != null || legacyTranslation != null)) {
        // Fold once, write v2, retire both v1 keys in the same session — a
        // half-migrated store would re-run `migrate` on every launch and an
        // install downgrade would find a v1 key that no longer describes the
        // reader's real state.
        await _write(prefs, state);
        await prefs.remove(_keyLegacyArabic);
        await prefs.remove(_keyLegacyTranslation);
      }
    } catch (_) {
      // Unreadable storage: defaults are the honest state, not a lie.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _write(prefs, state);
    } catch (_) {
      // Persisting is best-effort; the in-session scale stays truthful.
    }
  }

  static Future<void> _write(
    SharedPreferences prefs,
    HadithReadingPreferences value,
  ) =>
      prefs.setDouble(_keyScale, value.hadithTextScale);

  Future<void> setHadithTextScale(double value) async {
    state = state.copyWith(
      hadithTextScale: HadithReadingPreferences.clampScale(value),
    );
    await _save();
  }
}

final hadithReadingPreferencesProvider = StateNotifierProvider<
    HadithReadingPreferencesNotifier, HadithReadingPreferences>((ref) {
  return HadithReadingPreferencesNotifier();
});
