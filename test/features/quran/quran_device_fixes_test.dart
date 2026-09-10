// Device session 3 — quran reader fixes (BISECT PROBE 2: source guards
// only; widget groups removed temporarily to isolate the analyze error).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/surah_list_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';

void main() {
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
  });

  group('bug B — mode tabs fit narrow screens', () {
    for (final w in [360.0, 320.0]) {
      testWidgets('${w.toInt()}dp: no overflow, tabs reachable, pill live',
          (tester) async {
        var steps = 0;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: w,
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
        expect(pill, hitTestable);
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
      final raw = File('assets/data/quran/surah_info.json').readAsStringSync();
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map((e) => e['name'] as String? ?? '')
          .toList();
      final longest =
          list.fold<String>('', (a, b) => b.length > a.length ? b : a);
      expect(longest.isNotEmpty, isTrue);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SurahCard(
              surah: const SurahInfoModel(
                number: 3,
                name: 'Aal-i-Imraan',
                nameArabic: '',
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
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
