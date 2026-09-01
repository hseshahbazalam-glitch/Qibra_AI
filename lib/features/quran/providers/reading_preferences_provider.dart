// Persisted Quran reading preferences. Unbundled editions stay unresolved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/content/edition_resolver.dart';

enum QuranReadingMode { arabicOnly, arabicAndTranslation, translationOnly }

class ReadingPreferences {
  const ReadingPreferences({
    this.translationId = 'en',
    this.showTranslation = true,
    this.showTransliteration = false,
    this.fontScale = 1.0,
    this.lineHeight = 1.8,
    this.fontFamily = 'Amiri',
    this.mode = QuranReadingMode.arabicAndTranslation,
  });

  final String translationId;
  final bool showTranslation;
  final bool showTransliteration;
  final double fontScale;
  final double lineHeight;
  final String fontFamily;
  final QuranReadingMode mode;

  bool get translationBundled => EditionResolver.isBundled(translationId);

  ReadingPreferences copyWith({
    String? translationId,
    bool? showTranslation,
    bool? showTransliteration,
    double? fontScale,
    double? lineHeight,
    String? fontFamily,
    QuranReadingMode? mode,
  }) {
    return ReadingPreferences(
      translationId: translationId ?? this.translationId,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      fontScale: fontScale ?? this.fontScale,
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
    final scale = prefs.getDouble('${_key}_font_scale') ?? 1.0;
    final height = prefs.getDouble('${_key}_line_height') ?? 1.8;
    final font = prefs.getString('${_key}_font_family') ?? 'Amiri';
    final modeName = prefs.getString('${_key}_mode') ?? QuranReadingMode.arabicAndTranslation.name;
    final mode = QuranReadingMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => QuranReadingMode.arabicAndTranslation,
    );
    state = ReadingPreferences(
      translationId: EditionResolver.isBundled(id) ? id : 'en',
      showTranslation: showT,
      showTransliteration: showTr,
      fontScale: scale.clamp(0.8, 1.8),
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
    await prefs.setDouble('${_key}_font_scale', state.fontScale);
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

  Future<void> setFontScale(double value) async {
    state = state.copyWith(fontScale: value.clamp(0.8, 1.8));
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
