// PASS Q3 — Word-touch & explain (word layer honesty).
//
// The honesty core under test: spans render ONLY when they fold-align
// to the app's own canonical Uthmani text (the runtime validator is the
// single gate — corrupt or absent data can only fall back to the
// historical plain-Text ayah render). Timings address the exact
// everyayah per-ayah files the player streams; a qari without verified
// cue coverage plays from the ayah START and says so plainly.
//
// Layout note (mirrors quran_reading_pass_q2_test.dart): the app's REAL
// fonts load first — Ahem metrics manufacture fake overflow here too.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/data/word/quran_word_data.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_audio_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_word_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _glossAsset = 'assets/data/quran/word_gloss_en.json';
const _abmAsset = 'assets/data/quran/word_timings_ar.abdulbasitmurattal.json';
const _husaryAsset = 'assets/data/quran/word_timings_ar.husary.json';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync(encoding: utf8))
        as Map<String, dynamic>;

/// Real corpus decoded from the shipped assets (no rootBundle needed).
QuranWordCorpus _realCorpus() => QuranWordCorpus.fromJson(
      glossJson: _readJson(_glossAsset),
      timingsByQari: {
        'ar.abdulbasitmurattal': _readJson(_abmAsset),
        'ar.husary': _readJson(_husaryAsset),
      },
    );

class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};
  @override
  Future<void> checkSurah(int surah) async {}
}

/// Records queue + word-start calls without touching a real player.
class _RecordingAudio extends QuranAudioController {
  final List<({int surahNumber, int startIndex})> queueCalls = [];
  final List<({int spanIndex, List<WordCue>? cues})> wordCalls = [];

  @override
  QuranAudioState build() => const QuranAudioState();

  @override
  Future<void> startQueue({
    required int surahNumber,
    required String surahName,
    required List<PlayableAyah> queue,
    required int startIndex,
  }) async {
    queueCalls.add((surahNumber: surahNumber, startIndex: startIndex));
  }

  @override
  Future<void> playFromWord({
    required int surahNumber,
    required String surahName,
    required List<PlayableAyah> queue,
    required int startIndex,
    required int spanIndex,
    List<WordCue>? cues,
  }) async {
    // Mirror the production delegation (record + forward to startQueue)
    // exactly as the real controller stages its word intent.
    wordCalls.add((spanIndex: spanIndex, cues: cues));
    await startQueue(
      surahNumber: surahNumber,
      surahName: surahName,
      queue: queue,
      startIndex: startIndex,
    );
  }
}

const surah1 = SurahModel(
  number: 1,
  name: 'Al-Fatihah',
  nameArabic: 'الفاتحة',
  englishNameTranslation: 'The Opening',
  revelationType: 'Meccan',
  numberOfAyahs: 2,
  ayahs: [
    AyahModel(
      number: 1,
      numberInQuran: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      juz: 1,
      page: 1,
      translation: 'In the name of Allah, the Entirely Merciful,',
    ),
    AyahModel(
      number: 2,
      numberInQuran: 2,
      text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      juz: 1,
      page: 1,
      translation: 'All praise is due to Allah, Lord of the worlds',
    ),
  ],
);

Future<void> _pumpReader(
  WidgetTester tester, {
  required QuranWordCorpus? corpus,
  _RecordingAudio? audio,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Local-final hoist: a mutable PARAMETER's non-null promotion never
  // flows into the override's closure (analyzer error), a final local's
  // does. (Pass Q3 CI red: the analyzer caught what we must not fake.)
  final recordingAudio = audio;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      surahDetailProvider(1).overrideWith((ref) async => surah1),
      quranDownloadProvider.overrideWith(_NoopDownloads.new),
      quranWordCorpusProvider.overrideWith((ref) async => corpus),
      if (recordingAudio != null)
        quranAudioProvider.overrideWith(() => recordingAudio),
    ],
    child: MaterialApp(
      home: AppStringsScope(
        locale: const Locale('en'),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: const SurahReaderScreen(surahNumber: 1),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Real Inter + Amiri faces (mirrors the Q2 harness verbatim — file
/// bytes through FontLoader; no rootBundle needed in a test VM).
Future<void> loadAppTestFonts() async {
  Future<void> faces(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await faces('Inter', [
    for (final w in [
      'Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black',
    ])
      'assets/fonts/Inter-$w.ttf',
  ]);
  await faces('Amiri', [
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Amiri-Bold.ttf',
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Same real-fonts-first rule as the Q2 harness: Ahem metrics
  // manufacture fake overflow in the reader's Arabic card (the
  // widget tests here would drown in bogus RenderFlex reports).
  setUpAll(loadAppTestFonts);

  group('word units + folding (pure, mirrors the builder)', () {
    test('unitize: diacritics never split words; standalone pause marks '
        'attach to the previous unit', () {
      final units = QuranWordCorpus.unitize('لَا رَيْبَ ۖ فِيهِ');
      expect(units.length, 3,
          reason: 'the lone ۖ mark is NOT a word for counting purposes');
      expect(QuranWordCorpus.normalizeUnits(units[1]),
          QuranWordCorpus.normalizeUnits('رَيْبَۖ'));
      expect(QuranWordCorpus.normalizeUnits(units.join(' ')),
          QuranWordCorpus.normalizeUnits('لَا رَيْبَ ۖ فِيهِ'),
          reason: 'fold-join identity is stable under unit regrouping');
    });

    test('normalizeUnits folds alef family / ta marbuta / tatweel', () {
      expect(QuranWordCorpus.normalizeUnits('ٱلْحَمْدُ'),
          QuranWordCorpus.normalizeUnits('الحمد'));
      expect(QuranWordCorpus.normalizeUnits('ٱللَّهِ'),
          QuranWordCorpus.normalizeUnits('الله'));
    });

    test('countOccurrences counts word forms over the real corpus, live',
        () {
      final texts = [
        for (final s
            in (_readJson('assets/data/quran/quran_arabic.json')['data']
                    ['surahs'] as List))
          for (final a in (s as Map)['ayahs'] as List)
            (a as Map)['text'] as String,
      ];
      expect(texts.length, 6236);
      // Pinned against scripts/build_word_data.py (Python fold) — the
      // Dart implementation must agree on the exact numbers.
      expect(QuranWordCorpus.countOccurrences('ٱلرَّحْمَٰنِ', texts), 157);
      expect(QuranWordCorpus.countOccurrences('ٱللَّهِ', texts), 2265);
      expect(QuranWordCorpus.countOccurrences('لَايExists', texts), 0);
    });
  });

  group('alignment validator (the honesty core)', () {
    test('a shipped, verified ayah returns spans; a corrupted one returns '
        'null (whole-ayah fallback), never a wrong mapping', () {
      final corpus = _realCorpus();
      final good = corpus.wordsFor(
          1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ');
      expect(good, isNotNull);
      expect(good!.spans.length, 4);
      final corrupt = QuranWordCorpus.fromJson(glossJson: {
        'ayahs': {
          '1:2': {
            'p': 0,
            'w': [
              ['الْحَمْدُ', 'praise'],
              ['لِلَّهَX', 'WRONG'], // one letter off
              ['رَبِّ', 'lord'],
              ['الْعَالَمِينَ', 'worlds'],
            ]
          }
        }
      });
      expect(
          corrupt.wordsFor(1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'),
          isNull);
    });

    test('seekStartMs: exact start, clamp, and honest absence', () {
      const cues = [
        WordCue(span: 0, startMs: 40, endMs: 1230),
        WordCue(span: 1, startMs: -5, endMs: 4160),
      ];
      expect(QuranWordCorpus.seekStartMs(cues, 0), 40);
      expect(QuranWordCorpus.seekStartMs(cues, 1), 0,
          reason: 'negative cue start clamps to the file start');
      expect(QuranWordCorpus.seekStartMs(cues, 2), isNull,
          reason: 'no cue = play from ayah start, never a guess');
      expect(QuranWordCorpus.seekStartMs(null, 0), isNull);
    });

    test('spanAtMs maps playing position to the sounding word window', () {
      const cues = [
        WordCue(span: 0, startMs: 0, endMs: 100),
        WordCue(span: 1, startMs: 100, endMs: 250),
      ];
      expect(QuranWordCorpus.spanAtMs(cues, 50), 0);
      expect(QuranWordCorpus.spanAtMs(cues, 249), 1);
      expect(QuranWordCorpus.spanAtMs(cues, 250), isNull);
      expect(QuranWordCorpus.spanAtMs(null, 10), isNull);
    });
  });

  group('dataset integrity (real files, whole corpus)', () {
    late Map<String, dynamic> gloss;
    late Map<String, String> texts;

    setUpAll(() {
      gloss = _readJson(_glossAsset);
      final surahs =
          _readJson('assets/data/quran/quran_arabic.json')['data']['surahs']
              as List;
      texts = {
        for (final s in surahs)
          for (final a in (s as Map)['ayahs'] as List)
            '${s['number']}:${(a as Map)['numberInSurah']}':
                a['text'] as String,
      };
    });

    test('every gloss entry is present in the corpus, aligns to the app '
        'text, and the census is exactly 6221/6236 (15 degrade — pinned, '
        'so silent drift fails CI)', () {
      final ayahs = gloss['ayahs'] as Map<String, dynamic>;
      expect(ayahs.length, 6221);
      expect(texts.length, 6236);
      final corpus = QuranWordCorpus.fromJson(glossJson: gloss);
      for (final entry in ayahs.entries) {
        final parts = entry.key.split(':');
        final s = int.parse(parts[0]);
        final a = int.parse(parts[1]);
        final words = corpus.wordsFor(s, a, texts[entry.key]!);
        expect(words, isNotNull, reason: '${entry.key} failed re-verify');
        final w = entry.value as Map;
        expect((w['w'] as List).length, words!.spans.length);
      }
    });

    test('timing files: consecutive span indices from 0, positive '
        'windows, and exactly the cued-ayah census', () {
      final census = {
        'ar.abdulbasitmurattal': 5544,
        'ar.husary': 5792,
      };
      final glossAyahs = (gloss['ayahs'] as Map).cast<String, dynamic>();
      for (final qari in census.keys) {
        final doc = _readJson(
            'assets/data/quran/word_timings_$qari.json');
        final ayahs = doc['ayahs'] as Map<String, dynamic>;
        expect(ayahs.length, census[qari], reason: '$qari census drift');
        for (final entry in ayahs.entries) {
          final cues = (entry.value as List)
              .map((c) => (c as List).cast<int>())
              .toList();
          expect(cues.map((c) => c[0]).toList(),
              List<int>.generate(cues.length, (i) => i),
              reason: '${entry.key} $qari cue indices must be '
                  'consecutive from the first rendered span');
          expect(
              cues.every((c) => c[1] >= 0 && c[2] > c[1]),
              isTrue,
              reason: '${entry.key} $qari windows must have positive '
                  'length');
          final g = glossAyahs[entry.key] as Map;
          expect(cues.last[0], lessThanOrEqualTo((g['w'] as List).length),
              reason: 'cues address spans that exist in the gloss file');
        }
      }
    });

    test('bundled word data stays within the ≤15MB promise', () {
      const files = [_glossAsset, _abmAsset, _husaryAsset];
      var total = 0;
      for (final f in files) {
        final len = File(f).lengthSync();
        expect(len, lessThan(5 * 1024 * 1024), reason: f);
        total += len;
      }
      expect(total, lessThan(15 * 1024 * 1024));
    });

    test('the assets live flat under the already-registered assets/data/'
        'quran/ directory (pubspec untouched, by contract)', () {
      for (final f in [_glossAsset, _abmAsset, _husaryAsset]) {
        expect(File(f).existsSync(), isTrue);
        expect(f, isNot(contains('word/')),
            reason: 'subdirectories would need a pubspec edit — forbidden');
      }
    });
  });

  group('reader word layer (widget)', () {
    testWidgets('aligned ayah renders per-word spans; the plain-Text '
        'render disappears in its favor', (tester) async {
      final corpus = _realCorpus();
      await _pumpReader(tester, corpus: corpus);
      final spans = corpus.wordsFor(
          1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ')!;
      for (final s in spans.spans) {
        expect(find.text(s.word), findsOneWidget,
            reason: 'span "${s.word}" must render as its own word');
      }
      // The word layer REPLACES the single Text for aligned ayahs:
      expect(
          find.text('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), findsNothing);
    });

    testWidgets('corrupted corpus → the validator withholds words and '
        'the historical plain-Text render survives intact', (tester) async {
      final corpus = QuranWordCorpus.fromJson(glossJson: {
        'ayahs': {
          '1:2': {
            'p': 0,
            'w': [
              [' nonsense ', 'x'],
            ]
          }
        }
      });
      await _pumpReader(tester, corpus: corpus);
      expect(
          find.text('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), findsOneWidget);
      expect(find.textContaining('نonsense'), findsNothing);
    });

    testWidgets('word tap with listen mode OFF bubbles to the whole-ayah '
        'options sheet (zero gesture conflict with the card)',
        (tester) async {
      final corpus = _realCorpus();
      final audio = _RecordingAudio();
      await _pumpReader(tester, corpus: corpus, audio: audio);
      final spanWord = corpus.wordsFor(
          1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ')!
        .spans[1]
        .word;
      await tester.tap(find.text(spanWord));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The ayah options sheet opens (the pre-existing behavior); NO
      // word play was requested.
      expect(audio.wordCalls, isEmpty);
      expect(find.text('Tafsir'), findsWidgets,
          reason: 'the whole-ayah options sheet must have opened');
    });

    testWidgets('word tap in listen mode plays FROM THAT WORD (exact '
        'cues flow through)', (tester) async {
      final corpus = _realCorpus();
      final audio = _RecordingAudio();
      SharedPreferences.setMockInitialValues({
        'quran_reading_preferences_v1_listen_word_by_word': true,
        'quran_reading_preferences_v1_qari_id': 'ar.abdulbasitmurattal',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          surahDetailProvider(1).overrideWith((ref) async => surah1),
          quranDownloadProvider.overrideWith(_NoopDownloads.new),
          quranWordCorpusProvider.overrideWith((ref) async => corpus),
          quranAudioProvider.overrideWith(() => audio),
        ],
        child: MaterialApp(
          home: AppStringsScope(
            locale: const Locale('en'),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: const SurahReaderScreen(surahNumber: 1),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The persisted flag IS the reader's listen-mode state (the prefs
      // check below is load-bearing; a stray second container would read
      // defaults asynchronously and flake — the tap outcome proves the
      // wiring end-to-end).
      expect(prefs.getBool('quran_reading_preferences_v1_listen_word_by_word'),
          isTrue);
      final words = corpus.wordsFor(
          1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ')!;
      await tester.tap(find.text(words.spans[1].word));
      await tester.pump();
      expect(audio.wordCalls.length, 1);
      expect(audio.wordCalls.single.spanIndex, 1);
      final cues = audio.wordCalls.single.cues;
      expect(cues, isNotNull,
          reason: 'the active qari has cue data for this ayah');
      expect(QuranWordCorpus.seekStartMs(cues, 1), isNotNull,
          reason: 'word 1 resolves to an exact ms offset');
    });

    testWidgets('long-press a word opens the explain sheet: gloss, live '
        'count when computed, honest lines, and the play button',
        (tester) async {
      final corpus = _realCorpus();
      final words = corpus.wordsFor(
          1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ')!;
      final target = words.spans[1];
      await _pumpReader(tester, corpus: corpus);
      await tester.longPress(find.text(target.word));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // The word itself renders large in the sheet.
      expect(find.text(target.word), findsWidgets);
      // The gloss line (real data for لِلَّهِ in the shipped file):
      expect(find.text(target.gloss), findsOneWidget);
      // Root layer deferred — disclosed honestly:
      expect(find.textContaining('Root morphology'), findsOneWidget);
      // Play + ayah-scoped actions, word never claims ayah scopes:
      expect(find.textContaining('Play from this word'), findsOneWidget);
      expect(find.textContaining('Open Tafseer'), findsOneWidget);
      expect(find.textContaining('Ask AI about this word'), findsOneWidget);
    });

    testWidgets('listen toggle in the settings sheet persists to prefs',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpReader(tester, corpus: _realCorpus());
      await tester.tap(find.byTooltip('Reading settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final tile = find.text('Listen word-by-word');
      expect(tile, findsOneWidget,
          reason: 'the toggle ships in the reading settings sheet');
      // The sheet body scrolls (CPH2573 pattern); bring the tile on
      // screen before tapping (device users scroll the same way).
      await tester.ensureVisible(tile);
      await tester.pump();
      await tester.tap(tile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('quran_reading_preferences_v1_listen_word_by_word'),
          isTrue,
          reason: 'explicit user state — persisted through the repo key');
    });

    test('an unknown qari has NO timings dataset (honest-unavailable)',
        () {
      final corpus = _realCorpus();
      expect(corpus.hasTimingsFor('ar.alafasy'), isFalse);
      expect(corpus.hasTimingsFor('ar.abdurrahmaansudais'), isFalse);
      expect(corpus.hasTimingsFor('ar.minshawi'), isFalse);
      expect(corpus.hasTimingsFor('ar.abdulbasitmurattal'), isTrue);
      expect(corpus.hasTimingsFor('ar.husary'), isTrue);
    });
  });

  group('regression guards (source-level)', () {
    test('the word sheet follows the CPH2573 sheet pattern (scrollable, '
        '0.85 cap) so short screens never overflow', () {
      final src = File(
              'lib/features/quran/presentation/word_explain_sheet.dart')
          .readAsStringSync();
      expect(src, contains('isScrollControlled: true,'));
      expect(src, contains('maxHeight: MediaQuery.sizeOf(context).height * 0.85,'));
      expect(src, contains('SingleChildScrollView'));
    });

    test('playFromWord stages an intent — startQueue keeps its signature '
        'frozen for overrides and test doubles', () {
      final src =
          File('lib/features/quran/providers/quran_audio_provider.dart')
              .readAsStringSync();
      final sq = src.substring(
          src.indexOf('Future<void> startQueue({'),
          src.indexOf('}) async {', src.indexOf('Future<void> startQueue({')));
      expect(sq, isNot(contains('seekMs')),
          reason: 'no signature drift on the shared queue entry point');
      expect(sq, isNot(contains('wordSpan')));
      expect(src, contains('_wordIntentMs'));
      expect(src, contains('wordFallbackNotice'));
    });
  });
}
