// Device session 3 — quran reader fixes.
// Bug A: dispose-path persistence must not touch ref AND must actually
//        persist (purpose pin: last-read survives back-navigation, proven
//        through the real SharedPreferences store via setMockInitialValues).
// Bug B: the mode-tab strip + font pill must fit 320/360dp, pill tappable
//        at the right edge, all three tabs reachable via scroll.
// Hardening probe: SurahCard at 320dp with the longest bundled Arabic
//        name (from assets/data/quran/surah_info.json) — recorded either
//        way; currently PASSES unmodified, so the card stays untouched.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/surah_list_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};
  @override
  Future<void> checkSurah(int surah) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    testWidgets('popping the reader persists the resume position',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      // The reader's entry post-frame disk check must not write provider
      // state after our unmount at the end of this test — the override
      // keeps the whole test deterministic (no real fs).
      // (See _NoopDownloads below.)
      const surah = SurahModel(
        number: 1,
        name: 'Al-Fatihah',
        nameArabic: 'الفاتحة',
        englishNameTranslation: 'The Opening',
        revelationType: 'Meccan',
        numberOfAyahs: 2,
        ayahs: [
          AyahModel(number: 1, numberInQuran: 1, text: 'b1', juz: 1, page: 1),
          AyahModel(
              number: 2, numberInQuran: 2, text: 'b2', juz: 1, page: 1, sajdah: false),
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
      await tester.pump(); // first frame: data branch runs, _latestSurah caches
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount = dispose() — exactly the back-navigation moment the
      // device threw on. No Navigator involved: the widget's own
      // lifecycle IS the test surface (and no raw-generic route types in
      // a strict-raw-types repo).
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull,
          reason: 'no ref-after-dispose on the exit path');

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
                  arabicScale: 1.25, // widest pill label: 'Aa+25'
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
        // hitTestable() is a FINDER TRANSFORMER (not a matcher): the
        // variant only matches widgets reachable by a hit test.
        expect(pill.hitTestable(), findsOneWidget);
        // right-most: pill's right edge sits inside the strip's padding
        expect(tester.getRect(pill).right, lessThanOrEqualTo(w - 12 + 0.5));
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

  group('hardening probe — SurahCard @320dp, longest bundled Arabic name', () {
    testWidgets('current layout does NOT overflow: no fix applied',
        (tester) async {
      // Load the REAL longest nameArabic from the bundled dataset.
      final raw = File('assets/data/quran/surah_info.json').readAsStringSync();
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map((e) => e['name'] as String? ?? '')
          .toList();
      final longest = list.fold<String>(
          '', (a, b) => b.length > a.length ? b : a); // 22 chars incl. harakat
      expect(longest.isNotEmpty, isTrue);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
            width: 320,
            height: 150, // bounded height so any RenderFlex overflow trips honestly
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
      // VERDICT EVIDENCE: passes untouched — the un-flexed Arabic column
      // does not overflow at 320dp (Expanded center absorbs first). If
      // this ever trips, wrap that Column in Flexible (see seam commit).
      expect(tester.takeException(), isNull);
    });
  });
}
