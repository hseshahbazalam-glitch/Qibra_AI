// PASS QH — surah-reader quick reading handle (+ tasbih switcher).
// Harness shape mirrors quran_reading_pass_q3_test.dart: real corpus
// decoded from shipped assets, real fonts first (Ahem metrics fabricate
// overflow in the Arabic card), noop downloads.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/data/word/quran_word_data.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reading_handle.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_word_provider.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';
import 'package:qibra_ai/features/tasbih/providers/tasbih_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _glossAsset = 'assets/data/quran/word_gloss_en.json';
const _abmAsset = 'assets/data/quran/word_timings_ar.abdulbasitmurattal.json';
const _husaryAsset = 'assets/data/quran/word_timings_ar.husary.json';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync(encoding: utf8))
        as Map<String, dynamic>;

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
      text: '\uFEFFبِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      juz: 1,
      page: 1,
      translation: 'In the name of Allah, the Entirely Merciful,',
    ),
    AyahModel(
      number: 2,
      numberInQuran: 2,
      text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
      juz: 1,
      page: 1,
      translation: 'All praise is due to Allah, Lord of the worlds',
    ),
  ],
);

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

Future<void> _pumpReader(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      surahDetailProvider(1).overrideWith((ref) async => surah1),
      quranDownloadProvider.overrideWith(_NoopDownloads.new),
      quranWordCorpusProvider
          .overrideWith((ref) async => _realCorpus()),
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

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('qrah-tab')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 240));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpTasbih(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: const AppStringsScope(
        locale: Locale('en'),
        child: TasbihScreen(),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

List<String> _dartFiles(String dir) {
  final out = <String>[];
  for (final e in Directory(dir).listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) out.add(e.path);
  }
  return out..sort();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);

  group('QH — screen scope, tokens, rest-quiet (source)', () {
    test('the handle renders on the surah reader ONLY', () {
      final def = 'lib/features/quran/presentation/surah_reading_handle.dart';
      final host = 'lib/features/quran/presentation/surah_reader_screen.dart';
      for (final path in _dartFiles('lib')) {
        if (path == def) continue;
        final src = File(path).readAsStringSync(encoding: utf8);
        final uses = RegExp('SurahReadingHandle\\(').allMatches(src).length;
        if (path == host) {
          expect(uses, 1, reason: 'exactly one host site (the Stack child)');
        } else {
          expect(uses, 0, reason: 'screen-scoped: no other file mounts it — '
              '$path');
        }
      }
    });

    test('token discipline: no raw hex, no blur, no alphas, one easing', () {
      final src = File(
              'lib/features/quran/presentation/surah_reading_handle.dart')
          .readAsStringSync(encoding: utf8);
      expect(src.contains('Color(0x'), isFalse);
      expect(src.contains('BackdropFilter'), isFalse);
      expect(src.contains('withValues'), isFalse,
          reason: 'zero alphas written here — the blocker is invisible and '
              'the shadows come from the house elevation helper');
      expect(RegExp('QibraNavy\\.navyCard').allMatches(src).length, 2);
      expect(RegExp('Duration\\(milliseconds: 220\\)').allMatches(src)
          .length, 2, reason: 'open AND reverse share the 220ms beat');
      expect(RegExp('Curves\\.easeOutCubic')
          .allMatches(src), isNotEmpty);
    });

    test('tasbih switcher reuses the ONE existing selector', () {
      final src = File('lib/features/tasbih/presentation/tasbih_screen.dart')
          .readAsStringSync(encoding: utf8);
      expect(src.contains("key: const ValueKey('tasbih-switch-dhikr')"),
          isTrue);
      expect(src.contains('_showDhikrSelector(keepCount: true)'), isTrue);
      // The bubble rides the keepCount path; the card keeps the reset.
      expect(src.contains('onTap: _showDhikrSelector,'), isTrue);
      // no second list builder was invented: the sheet class stays at the
      // single usage it had before this pass.
      expect(RegExp('_DhikrSelectorSheet')
          .allMatches(src)
          .length, 1);
    });

    test('mid-run switch keeps the count; card path still resets', () async {
      SharedPreferences.setMockInitialValues({});
      final n = TasbihNotifier();
      await pumpEventQueue();
      final first = Dhikrs.subhanAllah;
      expect(n.state.currentDhikr.id, first.id);
      for (var i = 0; i < 3; i++) {
        n.increment();
      }
      n.switchDhikr(Dhikrs.alhamdulillah);
      expect(n.state.currentDhikr.id, Dhikrs.alhamdulillah.id);
      expect(n.state.count, 3);
      n.setDhikr(first);
      expect(n.state.count, 0);
    });
  });

  group('QH — handle render', () {
    testWidgets('isolated rest-quiet: the closed handle adds no ticker',
        (tester) async {
      // The reader screen's own machinery schedules one transient callback
      // at rest (its async boot) — an absolute-zero assert on that harness
      // measured the page, not the handle. Isolated + compared against a
      // bare-harness baseline, the pin measures exactly what THIS pass
      // mounts: a closed handle must add nothing.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> pumpHandle(bool withHandle) => tester.pumpWidget(
            ProviderScope(
              overrides: [quranDownloadProvider.overrideWith(_NoopDownloads.new)],
              child: MaterialApp(
                home: AppStringsScope(
                  locale: const Locale('en'),
                  child: Scaffold(
                    body: withHandle
                        ? const Stack(children: [SurahReadingHandle()])
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
      await pumpHandle(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final bare = tester.binding.transientCallbackCount;
      await pumpHandle(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('qrah-tab')), findsOneWidget);
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
      expect(tester.binding.transientCallbackCount, bare,
          reason: 'mounted-but-closed handle schedules nothing extra');
      await tester.tap(find.byKey(const ValueKey('qrah-tab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qrah-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
      expect(tester.binding.transientCallbackCount, bare,
          reason: 'after close, nothing lingers');
    });

    testWidgets('closed tab opens the panel; barrier and close dismiss',
        (tester) async {
      await _pumpReader(tester);
      expect(find.byKey(const ValueKey('qrah-tab')), findsOneWidget);
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('qrah-tab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const ValueKey('qrah-barrier')), findsOneWidget,
          reason: 'mid-flight the blocker is already under the sliding '
              'panel (220ms beat)');
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsOneWidget);
      await tester.tapAt(const Offset(340, 400)); // outside — barrier
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
      // reopen + the explicit close control
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('qrah-close')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
    });

    testWidgets('swipe-left on the panel and the back button dismiss',
        (tester) async {
      await _pumpReader(tester);
      await _open(tester);
      await tester.drag(
          find.byKey(const ValueKey('qrah-panel')), const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing,
          reason: 'swipe-close');
      await _open(tester);
      // Back while open: PopScope swallows the route pop and closes the
      // panel instead — the reader stays on screen.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('qrah-panel')), findsNothing);
      expect(find.byKey(const ValueKey('qrah-tab')), findsOneWidget,
          reason: 'the reader itself survived the back press');
    });

    testWidgets('panel controls drive the REAL shared reading store',
        (tester) async {
      await _pumpReader(tester);
      await _open(tester);
      // Night → Paper on the persisted store, rendered as the selected
      // segment (the M4-P rendered-level discipline — no private-state
      // peeking).
      await tester.tap(find.text('Paper'));
      for (var f = 0; f < 3; f++) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byKey(const ValueKey('qrah-theme')), findsOneWidget,
          reason: 'DBG theme=${find.byKey(const ValueKey('
                  'qrah-theme')).evaluate().length} '
                  'tab=${find.byKey(const ValueKey('
                  'qrah-tab')).evaluate().length} '
                  'panel=${find.byKey(const ValueKey('
                  'qrah-panel')).evaluate().length}');
      final seg = tester.widget<SegmentedButton<QibraReadingTheme>>(
          find.byKey(const ValueKey('qrah-theme')));
      expect(seg.selected, contains(QibraReadingTheme.paper));
      // Scales: two Arabic plus-steps move the readout to 1.20× and the
      // reader body repaints (no crash, no duplicated readout).
      await tester.tap(find.byKey(const ValueKey('qrah-arabic-plus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('qrah-arabic-plus')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1.20\u00d7'), findsOneWidget);
      // Edition: pick the row that does NOT carry the check; it gains it.
      final entries = EditionResolver.pickerEntries();
      String? unselected;
      for (final e in entries) {
        final k = find.byKey(ValueKey('qrah-edition-${e.id}'));
        if (k.evaluate().length == 1 &&
            find
                    .descendant(
                        of: k, matching: find.byIcon(Icons.check_rounded))
                    .evaluate()
                    .isEmpty) {
          unselected = e.id;
          break;
        }
      }
      expect(unselected, isNotNull,
          reason: 'the picker list is the loadable set — ≥1 unselected row');
      await tester.tap(find.byKey(ValueKey('qrah-edition-$unselected')));
      for (var f = 0; f < 3; f++) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(
          find.descendant(
              of: find.byKey(ValueKey('qrah-edition-$unselected')),
              matching: find.byIcon(Icons.check_rounded)),
          findsOneWidget);
    });

    testWidgets('semantics labels ride the tab and the close control',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpReader(tester);
      final strings = AppStrings.forCode('en');
      expect(
          tester
              .getSemantics(find.byKey(const ValueKey('qrah-tab')))
              .label,
          contains(strings.tooltipReadingSettings));
      await _open(tester);
      expect(
          tester
              .getSemantics(find.byKey(const ValueKey('qrah-close')))
              .label,
          contains(strings.close));
      handle.dispose();
    });
  });

  group('QH — tasbih bubble', () {
    testWidgets('the bubble opens the existing selector in place',
        (tester) async {
      await _pumpTasbih(tester);
      expect(find.byKey(const ValueKey('tasbih-switch-dhikr')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tasbih-switch-dhikr')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Select Dhikr'), findsOneWidget,
          reason: 'the SAME sheet the dhikr card opens — no new list');
      await tester.tap(find.text('Select Dhikr'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
