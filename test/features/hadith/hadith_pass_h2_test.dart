// test/features/hadith/hadith_pass_h2_test.dart
// ============================================================
// PASS H2 — hadith section: advance arrangement + fixes.
//
// Conventions (matching hadith_redesign_test / hadith_topclass_test):
// render-pins where a painted pixel is the truth (group F), source
// guards where the bug class is grep-visible, pure units where a
// static helper carries the rule. Groups arrive with their commits:
// F (visual fixes) first; D (arrangement), I (i18n), G (global
// search) and R (comfort) extend this file later in the pass.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart';

/// Pumps [child] under an explicit palette — the SAME extension the app
/// theme installs, so QibraColors.of resolves to the tested palette and
/// never to the analyzer-legacy ivory fallback.
Future<void> pumpPaletted(WidgetTester tester, Widget child,
    QibraColors palette) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[palette],
    ),
    home: Scaffold(body: child),
  ));
  await tester.pump();
}

/// The painted decoration — TextField's own field is non-nullable, so
/// a bang or a cast here would be fatal analyzer warnings (gate: 0/0).
TextField fieldWidget(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  group('H2-F — the search field fills with the SURFACE token, F1 dead',
      () {
    testWidgets('F3 render: navy cardMuted is the fill — never a text token',
        (tester) async {
      await pumpPaletted(
          tester,
          HadithSearchField(
            controller: TextEditingController(),
            query: '',
            hint: 'Search hadith number or text in this book...',
            onChanged: (_) {},
          ),
          QibraColors.dark);
      final dec = fieldWidget(tester).decoration!;
      // The bug shipped `fillColor: QibraNavy.textPrimary` — the fill
      // literally WAS the text color. Pin both halves of the fix:
      expect(dec.fillColor, QibraColors.dark.cardMuted);
      expect(dec.fillColor, isNot(QibraNavy.textPrimary),
          reason: 'F1 regression: a text token back in the fill slot');
      // Text/hint move onto the input styles + token colors (:452/:458).
      final field = fieldWidget(tester);
      expect(field.style!.color, QibraColors.dark.textPrimary);
      expect(dec.hintStyle!.color, QibraColors.dark.textTertiary);
      expect(dec.hintStyle!.fontSize, 11.5,
          reason: 'the hint keeps its measured size — tokenizing must '
              'not silently retune the type ladder');
    });

    testWidgets('F3 render: under Paper the SAME widget fills paperDeep',
        (tester) async {
      await pumpPaletted(
          tester,
          HadithSearchField(
            controller: TextEditingController(),
            query: '',
            hint: 'x',
            onChanged: (_) {},
          ),
          QibraPaper.palette);
      // R2 preview: the field is theme-resolved, so the reading surface
      // it will sit on (book reader, Paper scope) paints the right slab.
      expect(fieldWidget(tester).decoration!.fillColor, QibraPaper.paperDeep);
    });

    testWidgets('F3b: the field is controlled — clear resets the TEXT too',
        (tester) async {
      final ctl = TextEditingController();
      var last = '';
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setSheet) => HadithSearchField(
              controller: ctl,
              query: last,
              hint: 'x',
              onChanged: (v) => setSheet(() => last = v),
            ),
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'patience');
      await tester.pump();
      expect(ctl.text, 'patience');
      expect(last, 'patience');
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();
      // The pre-H2 field left the typed text on screen after clearing
      // (uncontrolled) — the query was empty, the FIELD was not.
      expect(last, '');
      expect(ctl.text, '', reason: 'F1-zone desync: query cleared, text '
          'kept — the controlled field must empty together');
      expect(find.byIcon(Icons.clear_rounded), findsNothing,
          reason: 'the suffix disappears exactly when the query empties');
    });

    test('F2 source guard: no text token may ever fill a decoration again',
        () {
      final src = File(
              'lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      expect(RegExp(r'fillColor:\s*QibraNavy\.').hasMatch(src), isFalse,
          reason: 'F1 class: QibraNavy text/ink tokens in a fill slot');
      expect(src.contains('color: isSelected'), isFalse,
          reason: 'the chapter pills\' ternary TEXT fills (F1 twin) are '
              'gone — QibraChip owns selection painting now');
      expect(
          src.contains('fillColor: colors.cardMuted,'), isTrue,
          reason: 'the fix stays wired: the fill rides the palette token');
    });

    test('F2 sweep: only the five card-zone raw TextStyles remain (D1 owns '
        'them)', () {
      final src = File(
              'lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      final raw = RegExp(r'\bTextStyle\(').allMatches(src).length;
      // Badge, grade chip, arabic body, translation body, chapter line —
      // every other raw site (:216–:1225) moved to AppTextStyles in F.
      expect(raw, 5,
          reason: 'H2-F tokenized 19 of 24; D1 rewrites the last five '
              'with the new card anatomy — count must NOT grow here');
      for (final other in [
        'lib/features/hadith/presentation/hadith_screen.dart',
        'lib/features/hadith/presentation/hadith_related_section.dart',
      ]) {
        expect(RegExp(r'\bTextStyle\(')
            .allMatches(File(other).readAsStringSync())
            .length, 0, reason: '$other was already token-clean');
      }
    });
  });
}
