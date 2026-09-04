// Persisted Quran reading preferences. Unbundled editions stay unresolved.
//
// World-class pass (2026-09-04): the single `fontScale` was SPLIT into
// `arabicScale` and `translationScale` — readers routinely want the
// Arabic larger than the latin translation (or vice versa). On first
// load, the legacy `font_scale` value migrates: BOTH new scales default
// to whatever the old single scale was (clamped to the shared range).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/content/edition_resolver.dart';

enum QuranReadingMode { arabicOnly, arabicAndTranslation, translationOnly }

class ReadingPreferences {
  const ReadingPreferences({
    this.translationId = 'en',
    this.showTranslation = true,
    this.showTransliteration = false,
    this.arabicScale = 1.0,
    this.translationScale = 1.0,
    this.lineHeight = 1.8,
    this.fontFamily = 'Amiri',
    this.mode = QuranReadingMode.arabicAndTranslation,
  });

  /// Shared clamp range for both scales.
  static const double scaleMin = 0.8;
  static const double scaleMax = 1.6;

  final String translationId;
  final bool showTranslation;
  final bool showTransliteration;

  /// Multiplier for the Arabic Quran text.
  final double arabicScale;

  /// Multiplier for translation + transliteration body text.
  final double translationScale;
  final double lineHeight;
  final String fontFamily;
  final QuranReadingMode mode;

  static double clampScale(double v) => v.clamp(scaleMin, scaleMax).toDouble();

  /// Pure legacy migration — unit-tested. A missing/null old value means
  /// both scales are the default 1.0; an out-of-range old value clamps.
  static ({double arabic, double translation}) splitLegacyScale(
      double? legacyScale) {
    final base = legacyScale ?? 1.0;
    final v = clampScale(base);
    return (arabic: v, translation: v);
  }

  bool get translationBundled => EditionResolver.isBundled(translationId);

  ReadingPreferences copyWith({
    String? translationId,
    bool? showTranslation,
    bool? showTransliteration,
    double? arabicScale,
    double? translationScale,
    double? lineHeight,
    String? fontFamily,
    QuranReadingMode? mode,
  }) {
    return ReadingPreferences(
      translationId: translationId ?? this.translationId,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      arabicScale: arabicScale ?? this.arabicScale,
      translationScale: translationScale ?? this.translationScale,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      mode: mode ?? this.mode,
    );
  }
}

class ReadingPreferencesNotifier extends StateNotifier<ReadingPreferences> {
  ReadingPreferencesNotifier() : super(const ReadingPreferences()) {
    _load();
  }

  static const _key = 'quran_reading_preferences_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('${_key}_translation') ?? 'en';
    final showT = prefs.getBool('${_key}_show_translation') ?? true;
    final showTr = prefs.getBool('${_key}_show_transliteration') ?? false;
    final height = prefs.getDouble('${_key}_line_height') ?? 1.8;
    final font = prefs.getString('${_key}_font_family') ?? 'Amiri';
    final modeName = prefs.getString('${_key}_mode') ?? QuranReadingMode.arabicAndTranslation.name;
    final mode = QuranReadingMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => QuranReadingMode.arabicAndTranslation,
    );
    // Split-scale load with backward-compatible migration from the old
    // single font_scale key (legacy value is left in place, never
    // rewritten — a downgrade still finds it).
    final legacyScale = prefs.getDouble('${_key}_font_scale');
    final arabic = prefs.getDouble('${_key}_arabic_scale');
    final translation = prefs.getDouble('${_key}_translation_scale');
    final migrated =
        (arabic == null || translation == null)
            ? ReadingPreferences.splitLegacyScale(legacyScale)
            : null;
    final scales = migrated ??
        (arabic: ReadingPreferences.clampScale(arabic!),
         translation: ReadingPreferences.clampScale(translation!));
    state = ReadingPreferences(
      translationId: EditionResolver.isBundled(id) ? id : 'en',
      showTranslation: showT,
      showTransliteration: showTr,
      arabicScale: scales.arabic,
      translationScale: scales.translation,
      lineHeight: height.clamp(1.4, 2.4),
      fontFamily: font,
      mode: mode,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_key}_translation', state.translationId);
    await prefs.setBool('${_key}_show_translation', state.showTranslation);
    await prefs.setBool('${_key}_show_transliteration', state.showTransliteration);
    await prefs.setDouble('${_key}_arabic_scale', state.arabicScale);
    await prefs.setDouble('${_key}_translation_scale', state.translationScale);
    await prefs.setDouble('${_key}_line_height', state.lineHeight);
    await prefs.setString('${_key}_font_family', state.fontFamily);
    await prefs.setString('${_key}_mode', state.mode.name);
  }

  Future<void> setTranslation(String id) async {
    final miss = EditionResolver.miss(id);
    if (miss != null) {
      return;
    }
    state = state.copyWith(translationId: id);
    await _save();
  }

  Future<void> setShowTranslation(bool value) async {
    state = state.copyWith(showTranslation: value);
    await _save();
  }

  Future<void> setShowTransliteration(bool value) async {
    state = state.copyWith(showTransliteration: value);
    await _save();
  }

  Future<void> setArabicScale(double value) async {
    state = state.copyWith(arabicScale: ReadingPreferences.clampScale(value));
    await _save();
  }

  Future<void> setTranslationScale(double value) async {
    state = state.copyWith(
        translationScale: ReadingPreferences.clampScale(value));
    await _save();
  }

  /// Settings-screen single-knob behavior: sets BOTH scales together
  /// (the split fine-tuning lives in the reader's settings sheet).
  Future<void> setBothScales(double value) async {
    final v = ReadingPreferences.clampScale(value);
    state = state.copyWith(arabicScale: v, translationScale: v);
    await _save();
  }

  Future<void> setLineHeight(double value) async {
    state = state.copyWith(lineHeight: value.clamp(1.4, 2.4));
    await _save();
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _save();
  }

  Future<void> setMode(QuranReadingMode mode) async {
    state = state.copyWith(mode: mode);
    await _save();
  }
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesNotifier, ReadingPreferences>(
  (ref) => ReadingPreferencesNotifier(),
);
