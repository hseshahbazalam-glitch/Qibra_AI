// Device session 3 — quran reader fixes.
//
// Bug A: dispose-path persistence must not touch `ref` (field-capture
// pattern) AND must actually persist — pinned through the REAL prefs
// store ("store received the record" is the fix's purpose).
// Bug B: mode-tab strip + font pill fit narrow screens (320/360dp),
// pill hittable at the right edge, all tabs reachable via scroll.
// Hardening (conditional, evidence-first): SurahCard @320dp with the
// longest bundled Arabic name OVERFLOWED (+35px under real font
// metrics) -> Arabic column is now Flexible + single-line ellipsis,
// with the 'N Ayahs' label flexed as its mate. This file carries the
// permanent 320dp tripwire for that layout.
//
// Harness facts worth keeping in mind:
//  * The app's REAL fonts (Inter/Amiri, flutter/services FontLoader —
//    NOT exported by material/widgets) must be loaded: flutter test's
//    Ahem placeholder has no glyph metrics and manufactures overflow
//    "bugs" that don't exist on device (measured: +256 vs real +35).
//  * A horizontal viewport needs a bounded cross axis (72dp box for
//    ModeTabs mirrors the reader scaffold's bounded row).
//  * hitTestable() is a FINDER TRANSFORMER (Finder.hitTestable()), not
//    a matcher.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/surah_list_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// The reader's post-frame disk check must not do real fs work (or write
/// provider state after our deliberate unmount) inside tests.
class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};
  @override
  Future<void> checkSurah(int surah) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);

  group('bug A — ref-free dispose persistence', () {
    test('source guard: _persistLastRead uses zero ref; dispose keeps it', () {
      final src =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync();
      final a = src.indexOf('void _persistLastRead() {');
      final b = src.indexOf('\n  }', a);
      expect(a, greaterThan(0));
      final body = src.substring(a, b);
      expect(body.contains('ref.read'), isFalse);
      expect(body.contains('ref.watch'), isFalse);
      expect(body, contains('_lastReadStore.record('));
      expect(body, contains('_latestSurah'));
      final disp = src.substring(
          src.indexOf('void dispose() {'), src.indexOf('super.dispose();'));
      expect(disp, contains('_persistLastRead();'));
      expect(disp, contains('removeObserver(this)'));
      expect(src, contains('_lastReadStore = ref.read(')); // initState capture
    });

    testWidgets('unmounting the reader persists the resume position',
        (tester) async {
      // Phone-shaped viewport: the default 800x600 test window crops the
      // reader's vertical stack (real devices are ~844 tall).
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      const surah = SurahModel(
        number: 1,
        name: 'Al-Fatihah',
        nameArabic: 'الفاتحة',
        englishNameTranslation: 'The Opening',
        revelationType: 'Meccan',
        numberOfAyahs: 2,
        ayahs: [
          AyahModel(number: 1, numberInQuran: 1, text: 'b1', juz: 1, page: 1),
          AyahModel(number: 2, numberInQuran: 2, text: 'b2', juz: 1, page: 1),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          surahDetailProvider(1).overrideWith((ref) async => surah),
          quranDownloadProvider.overrideWith(_NoopDownloads.new),
        ],
        child: const MaterialApp(
          home: AppStringsScope(
            locale: Locale('en'),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SurahReaderScreen(surahNumber: 1, initialAyah: 2),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull,
          reason: 'reader lays out clean at 390dp');

      // Unmount = dispose(): the exact back-navigation moment the device
      // threw 'Cannot use ref after the widget was disposed' on.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull,
          reason: 'no ref-after-dispose on the exit path');

      // PURPOSE pin (not just absence of a throw): the store received the
      // record — verified through the real prefs JSON the notifier writes.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_read_position');
      expect(raw, isNotNull, reason: 'the exit MUST persist');
      final saved = jsonDecode(raw!) as Map<String, dynamic>;
      expect(saved['surahNumber'], 1);
      expect(saved['ayahNumber'], 2,
          reason: 'no tap/play this visit -> entry position is the resume');
    });
  });

  group('bug B — mode tabs fit narrow screens', () {
    for (final w in [360.0, 320.0]) {
      testWidgets('${w.toInt()}dp: no overflow, tabs reachable, pill live',
          (tester) async {
        var steps = 0;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w,
                height: 72, // bounded cross-axis for the horizontal viewport
                child: ModeTabs(
                  tabs: const ['Arabic', 'Translation', 'Transliteration'],
                  active: 'Arabic',
                  arabicScale: 1.25,
                  onSelect: (_) {},
                  onSizeStep: () => steps++,
                ),
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
        for (final label in ['Arabic', 'Translation', 'Transliteration']) {
          expect(find.text(label), findsOneWidget);
        }
        final pill = find.text('Aa+25');
        expect(pill, findsOneWidget);
        // hitTestable(): the transformer variant only matches widgets
        // reachable by a hit test — proves the pill is truly tappable,
        // not just painted.
        expect(pill.hitTestable(), findsOneWidget);
        await tester.tap(pill);
        expect(steps, 1);
      });
    }

    test('source guard: Spacer is gone from the tab strip', () {
      final src =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync();
      final strip = src.substring(
          src.indexOf('class ModeTabs extends'), src.indexOf('Aa+'));
      expect(strip.contains('Spacer()'), isFalse);
      expect(strip, contains('SingleChildScrollView'));
      expect(strip, contains('Expanded('));
    });
  });

  group('hardening — SurahCard @320dp, longest bundled Arabic name', () {
    testWidgets('widest name does NOT overflow: Flexible wrap holds',
        (tester) async {
      final raw = File('assets/data/quran/surah_info.json')
          .readAsStringSync();
      final Object? decoded = jsonDecode(raw);
      final List<dynamic> data = decoded is Map<String, dynamic>
          ? decoded['data'] as List<dynamic>
          : decoded as List<dynamic>;
      final list = data
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .toList();
      final longest = list.fold<String>(
          '', (a, b) => b.length > a.length ? b : a);
      expect(longest.isNotEmpty, isTrue);
      // FULL-height box (320x800), width pinned: constraining the axis
      // under test is how a no-fix verdict was wrongly made once already
      // (150dp-tall harness box manufactured its own overflow).
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              height: 800,
              child: SurahCard(
                surah: SurahInfoModel(
                  number: 3,
                  name: 'Aal-i-Imraan',
                  nameArabic: longest,
                  englishNameTranslation: 'The Family of Imran',
                  revelationType: 'Medinan',
                  numberOfAyahs: 200,
                ),
                revelationColor: const Color(0xFF2ED39A),
                revelationLabel: 'Medinan',
                onTap: () {},
              ),
            ),
          ),
        ),
      ));
      // HISTORY: pre-hardening this threw 'RenderFlex overflowed by 35
      // pixels on the right' (real fonts). The Flexible + ellipsis wrap
      // (Arabic column + 'N Ayahs' label) is what this now guards.
      expect(tester.takeException(), isNull);
    });
  });
}
