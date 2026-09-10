// Device session 3 — quran reader fixes:
//  A: dispose-path persistence must not touch ref, and must actually
//     persist (purpose pinned through the real prefs store).
//  B: the mode-tab strip + font pill fit 320/360dp, pill hittable.
// Hardening probe: SurahCard @320dp with the longest bundled Arabic name
// — recorded either way; if it passes, the card stays untouched.
//
// TEMP: the four pump bodies run inside guard() which prints the real
// failure through ::error annotations (CI logs are unreachable from the
// authoring sandbox; annotations are the only readable channel).
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

Future<void> guard(String name, Future<void> Function() body) async {
  try {
    await body();
  } catch (e, st) {
    final head = st.toString().split('\n').take(3).join(' | ');
    // ignore: avoid_print
    print('::error::DIAG $name -> $e || $head');
    rethrow;
  }
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

    testWidgets('unmounting the reader persists the resume position',
        (tester) async {
      await guard('persistence', () async {
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

        // Unmount = dispose(): the exact back-navigation moment the
        // device threw on.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
        final ePost = tester.takeException();
        if (ePost != null) {
          // ignore: avoid_print
          print('::error::DIAG-EXC post-unmount -> $ePost');
        }
        expect(ePost, isNull, reason: 'no ref-after-dispose on the exit path');

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('last_read_position');
        expect(raw, isNotNull, reason: 'the exit MUST persist');
        final saved = jsonDecode(raw!) as Map<String, dynamic>;
        expect(saved['surahNumber'], 1);
        expect(saved['ayahNumber'], 2,
            reason: 'no tap/play this visit -> entry position is the resume');
      });
    });
  });

  group('bug B — mode tabs fit narrow screens', () {
    for (final w in [360.0, 320.0]) {
      testWidgets('${w.toInt()}dp: no overflow, tabs reachable, pill live',
          (tester) async {
        await guard('tabs-${w.toInt()}', () async {
          var steps = 0;
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: w,
                  // bounded cross-axis: a horizontal viewport REQUIRES it
                  // (production is bounded by the app scaffold the same way)
                  height: 72,
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
          final eTabs = tester.takeException();
          if (eTabs != null) {
            // ignore: avoid_print
            print('::error::DIAG-EXC tabs-${w.toInt()} -> $eTabs');
          }
          expect(eTabs, isNull);
          for (final label in [
            'Arabic',
            'Translation',
            'Transliteration'
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          final pill = find.text('Aa+25');
          expect(pill, findsOneWidget);
          // hitTestable() is a finder transformer (not a matcher): the
          // variant only matches widgets reachable by a hit test.
          expect(pill.hitTestable(), findsOneWidget);
          await tester.tap(pill);
          expect(steps, 1);
        });
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
      await guard('card-probe', () async {
        final raw = File('assets/data/quran/surah_info.json')
            .readAsStringSync();
        final dynamic d = jsonDecode(raw);
        final list = ((d is List ? d : (d['data'] as List)) as List)
            .map((e) => (e as Map)['name'] as String? ?? '')
            .toList();
        final longest = list.fold<String>(
            '', (a, b) => b.length > a.length ? b : a);
        expect(longest.isNotEmpty, isTrue);
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                height: 150,
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
        final eCard = tester.takeException();
        if (eCard != null) {
          // ignore: avoid_print
          print('::error::DIAG-EXC card -> $eCard');
        }
        // VERDICT EVIDENCE: passes untouched (un-flexed Arabic column is
        // safe at 320dp — Expanded center absorbs first). This pump stays
        // as the permanent tripwire if that ever changes.
        expect(eCard, isNull);
      });
    });
  });
}
