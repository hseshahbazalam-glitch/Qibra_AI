// Stage 2 — honesty + brand guards for the rebuilt Prayer / Quran /
// Hadith / AI screens. These are source-scan assertions that run in
// `flutter test` without a widget harness.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;

const _stage2Screens = [
  'lib/features/prayer/presentation/prayer_times_screen.dart',
  'lib/features/quran/presentation/quran_screen.dart',
  'lib/features/hadith/presentation/hadith_screen.dart',
  'lib/features/ai/presentation/ai_explain_screen.dart',
];


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('features_quran_phase18_stage2_honesty_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('features_quran_phase18_stage2_honesty_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
  });

  test('stage 2 screens exist', () {
    for (final p in _stage2Screens) {
      expect(File(p).existsSync(), isTrue, reason: p);
    }
  });

  test('no weather UI without a real data source', () {
    for (final p in _stage2Screens) {
      final src = File(p).readAsStringSync();
      expect(RegExp(r'[Ww]eather').hasMatch(src), isFalse,
          reason: '$p must not show invented weather');
    }
  });

  test('no fake audio-player chrome (audio stage reality)', () {
    // Screens must not hand-roll players or invented timestamps; real
    // recitation lives in the app-wide provider (stream + offline).
    for (final p in _stage2Screens) {
      final src = File(p).readAsStringSync();
      if (p.contains('/ai/')) continue; // AI screen uses real flutter_tts
      expect(src.contains('package:audioplayers'), isFalse,
          reason: '$p must not fake a player');
      expect(src.contains('AudioPlayer('), isFalse,
          reason: '$p must not fake a player');
    }
    // The stale "recitation is not bundled" badge was retired with the
    // audio stage (2026-09) — keeping it would claim something false now.
    // It must not come back; the reader must not revive invented times.
    final quran = File(_stage2Screens[1]).readAsStringSync();
    expect(quran.contains('recitationNotBundled'), isFalse,
        reason: 'stale "not bundled" notice must stay retired');
    final reader =
        File('lib/features/quran/presentation/surah_reader_screen.dart')
            .readAsStringSync();
    expect(reader.contains('00:09'), isFalse,
        reason: 'no invented playback timestamps in the reader');
    final audioProvider = File(
            'lib/features/quran/providers/quran_audio_provider.dart')
        .readAsStringSync();
    expect(audioProvider.contains('class QuranAudioController'), isTrue,
        reason: 'the real player state must stay provider-backed');
  });

  test('no emoji icons in user-facing UI (single icon language)', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    for (final p in _stage2Screens) {
      final src = File(p).readAsStringSync();
      expect(emoji.hasMatch(src), isFalse, reason: '$p must avoid emoji icons');
    }
  });

  test('prayer screen explains calculation transparently', () {
    final src = File(_stage2Screens[0]).readAsStringSync();
    // A2 moved this chrome copy into AppStrings; pin both ends of the
    // honest-rendering chain: the call site renders the getter and the
    // English copy lives (verbatim) in its single source of truth.
    expect(src.contains('s.whyTimeDifferent'), isTrue);
    expect(
        File('lib/core/l10n/app_strings.dart')
            .readAsStringSync(encoding: utf8)
            .contains("'Why is my prayer time different?'"),
        isTrue);
    expect(src.contains('calculationMethod'), isTrue);
    expect(src.contains('asrMethod'), isTrue);
    expect(src.contains('highLatitudeMethod'), isTrue);
    expect(src.contains('adjustments'), isTrue);
  });

  test('hadith grades keep their honest qualifiers', () {
    final src = File(_stage2Screens[2]).readAsStringSync();
    // Collection grade wording, never "100% Authentic".
    expect(src.contains('100%'), isFalse);
    expect(src.contains('collection grade'), isTrue);
  });

  test('quran verse-of-day references are traceable, not guessed', () {
    final src = File(_stage2Screens[1]).readAsStringSync();
    expect(src.contains('dailyVerseBundleProvider'), isTrue,
        reason: 'verse of day must come from the surah-aware bundle');
    expect(src.contains('shortReference'), isTrue);
    expect(src.contains('_dailySurahNumber'), isFalse,
        reason: 'no hardcoded day-key guessing on the screen');
  });

  test('AI screen keeps the fatwa disclaimer', () {
    final src = File(_stage2Screens[3]).readAsStringSync();
    expect(src.contains('not a fatwa'), isTrue);
    expect(src.contains('SOURCES'), isTrue,
        reason: 'answers must surface a sources section');
  });
}
