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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
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

    test('F2 sweep: the WHOLE book screen is raw-text-style free', () {
      final src = File(
              'lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      // Re-pinned in the D1 commit (disclosed): F left exactly the five
      // card-zone sites; D1 rebuilt the card and deleted the LAST raw
      // style too — the 24-site ledger is now closed at zero.
      final raw = RegExp(r'\bTextStyle\(').allMatches(src).length;
      expect(raw, 0,
          reason: 'every text style on the book screen rides '
              'AppTextStyles/AppArabicStyles copyWith — no raw sites');
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

  group('H2-D1/D2 — card anatomy in order; long bodies collapse honestly',
      () {
    HadithModel mkHadith({
      required String english,
      int number = 4,
      int chapter = 3,
      HadithGrade grade = HadithGrade.sahih,
    }) =>
        HadithModel(
          id: 'bukhari#$number',
          hadithNumber: number,
          bookSlug: 'bukhari',
          bookName: 'Sahih al-Bukhari',
          chapterNumber: chapter,
          chapterName: 'Revelation',
          textArabic: '\u0639\u0628\u0627\u0631\u0627\u062a \u0642\u0635\u064a\u0631\u0629',
          textEnglish: english,
          textUrdu: '',
          grade: grade,
          narrator: const HadithNarrator(name: 'Abu Huraira'),
        );

    // A REAL StatefulBuilder drives expansion — a bare closure variable
    // flipped by onToggleExpand never rebuilds the tree (that harness bug
    // was one of the two CI reds; the assertion passed pre-tap and died
    // post-tap exactly as a stale build should).
    Future<void> pump(WidgetTester tester, HadithModel h) async {
      SharedPreferences.setMockInitialValues({});
      late StateSetter setSheet;
      var exp = false;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            extensions: <ThemeExtension<dynamic>>[QibraColors.dark],
          ),
          home: StatefulBuilder(
            builder: (context, setter) {
              setSheet = setter;
              return Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    child: HadithCard(
                      hadith: h,
                      showArabic: true,
                      showTranslation: true,
                      positionLabel: HadithBookScreen.hadithPositionLabel(
                          h.hadithNumber, 7563),
                      expanded: exp,
                      onToggleExpand: () =>
                          setSheet(() => exp = !exp),
                      onTap: () {},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ));
      await tester.pump();
    }


    
    Text bodyText(WidgetTester tester, String key) => tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(ValueKey(key)), matching: find.byType(Text)))
        .last;

    test('D2 unit: the budget is MORE than 8 laid lines, no more no less',
        () {
      expect(HadithCard.collapseFor(8), isFalse);
      expect(HadithCard.collapseFor(9), isTrue);
      expect(HadithCard.kHadithCollapseLineBudget, 8);
    });

    testWidgets('D1 anatomy: badge → arabic → ornament → translation → '
        'meta, in that vertical order', (tester) async {
      await pump(tester, mkHadith(english: 'Short body of the hadith.'));
      for (final k in [
        'hadith-card-badge',
        'hadith-card-arabic',
        'hadith-card-ornament',
        'hadith-card-translation',
        'hadith-card-meta',
      ]) {
        expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
      }
      final badge = tester.getRect(find.byKey(const ValueKey('hadith-card-badge'))).bottom;
      final arabic = tester.getRect(find.byKey(const ValueKey('hadith-card-arabic'))).bottom;
      final ornament = tester.getRect(find.byKey(const ValueKey('hadith-card-ornament'))).top;
      final trans =
          tester.getRect(find.byKey(const ValueKey('hadith-card-translation'))).top;
      final meta = tester.getRect(find.byKey(const ValueKey('hadith-card-meta'))).top;
      expect(badge, lessThan(arabic));
      expect(arabic, lessThan(ornament));
      expect(ornament, lessThan(trans));
      expect(trans, lessThan(meta));
    });

    testWidgets('D1 typography: arabic in the 1.85-2.0 band, translation '
        'at 1.6, both on palette tokens', (tester) async {
      await pump(tester, mkHadith(english: 'x y z'));
      final ar = bodyText(tester, 'hadith-card-arabic');
      expect(ar.style!.height, inInclusiveRange(1.85, 2.0));
      expect(ar.style!.color, QibraColors.dark.textPrimary,
          reason: 'the matn rides the ink token — navy textPrimary now, '
              'paper ink under R2\u0027s scope, same code');
      expect(ar.textDirection, TextDirection.rtl);
      final tr = bodyText(tester, 'hadith-card-translation');
      expect(tr.style!.height, 1.6);
      expect(tr.style!.color, QibraColors.dark.textSecondary);
    });

    testWidgets('D1 meta row: chapter pill, position, grade; tooltips on '
        'both actions', (tester) async {
      await pump(tester, mkHadith(english: 'short one'));
      expect(find.text('Ch 3'), findsOneWidget);
      expect(find.text('Hadith 4 of 7563'), findsOneWidget);
      expect(find.text('Sahih'), findsOneWidget);
      expect(find.text('4'), findsOneWidget,
          reason: 'the badge number, not a second position echo');
      final strings = AppStrings.forCode('en');
      expect(find.byTooltip(strings.tooltipBookmark), findsOneWidget);
      expect(find.byTooltip(strings.tooltipCopyToShare), findsOneWidget);
    });

    testWidgets('D1 honest-null: an ungraded hadith says so — no silent '
        'Sahih default', (tester) async {
      await pump(tester,
          mkHadith(english: 'short one', grade: HadithGrade.unknown));
      expect(
          find.text(AppStrings.forCode('en').hadithGradeNotRecorded),
          findsOneWidget);
      expect(find.text('Sahih'), findsNothing);
    });

    testWidgets('D2: >8 lines collapses both blocks at 4 with the '
        'localized expander; tapping expands and offers Show less',
        (tester) async {
      final long =
          List.filled(60, 'patience is a habit of the heart').join(' ');
      await pump(tester, mkHadith(english: long));
      final strings = AppStrings.forCode('en');
      expect(find.text(strings.readFullHadith), findsOneWidget);
      expect(bodyText(tester, 'hadith-card-arabic').maxLines, 4);
      expect(bodyText(tester, 'hadith-card-translation').maxLines, 4);
      await tester.tap(find.text(strings.readFullHadith));
      await tester.pump();
      expect(find.text(strings.showLessHadith), findsOneWidget);
      expect(find.text(strings.readFullHadith), findsNothing);
      expect(bodyText(tester, 'hadith-card-translation').maxLines, isNull);
      // A SHORT body never earns the expander:
      await pump(tester, mkHadith(english: 'tiny body', number: 5));
      expect(find.text(strings.readFullHadith), findsNothing);
    });

    testWidgets('D2 honesty: copy carries the FULL hadith even while '
        'collapsed', (tester) async {
      final long =
          List.filled(60, 'gratitude anchors the believer').join(' ');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (m) async {
        calls.add(m);
        return null;
      });
      await pump(tester, mkHadith(english: long, number: 7));
      final strings = AppStrings.forCode('en');
      expect(find.text(strings.readFullHadith), findsOneWidget,
          reason: 'precondition — the card IS collapsed');
      await tester.tap(find.byTooltip(strings.tooltipCopyToShare));
      await tester.pump(); // the SnackBar appears...
      await tester.pump(const Duration(seconds: 2)); // ...its 1s timer
      // must EXPIRE inside the test — a pending SnackBar timer is the
      // teardown failure that was red CI #2.
      await tester.pumpAndSettle(); // dismissal animation ends
      final data = calls
          .firstWhere((c) => c.method == 'Clipboard.setData')
          .arguments as Map<Object?, Object?>;
      expect(data['text'], contains(long),
          reason: 'collapsed DISPLAY must never shrink the copied TEXT');
    });
  });
}
