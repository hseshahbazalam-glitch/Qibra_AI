// Device session 3 — quran reader fixes (BISECT PROBE 2: source guards
// only; widget groups removed temporarily to isolate the analyze error).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
