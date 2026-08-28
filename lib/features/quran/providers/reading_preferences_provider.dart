// Persisted Quran reading preferences. Unbundled editions stay unresolved.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/content/edition_resolver.dart';

class ReadingPreferences {
  const ReadingPreferences({
    this.translationId = 'en',
    this.showTranslation = true,
    this.showTransliteration = false,
    this.fontScale = 1.0,
  });

  final String translationId;
  final bool showTranslation;
  final bool showTransliteration;
  final double fontScale;

  bool get translationBundled => EditionResolver.isBundled(translationId);

  ReadingPreferences copyWith({
    String? translationId,
    bool? showTranslation,
    bool? showTransliteration,
    double? fontScale,
  }) {
    return ReadingPreferences(
      translationId: translationId ?? this.translationId,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      fontScale: fontScale ?? this.fontScale,
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
    state = ReadingPreferences(
      translationId: EditionResolver.isBundled(id) ? id : 'en',
      showTranslation: showT,
      showTransliteration: showTr,
      fontScale: scale.clamp(0.8, 1.8),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_key}_translation', state.translationId);
    await prefs.setBool('${_key}_show_translation', state.showTranslation);
    await prefs.setBool('${_key}_show_transliteration', state.showTransliteration);
    await prefs.setDouble('${_key}_font_scale', state.fontScale);
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
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesNotifier, ReadingPreferences>(
  (ref) => ReadingPreferencesNotifier(),
);
