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
                  child: SingleChildScrollView(
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
                  ), // SingleChildScrollView — the 600px test viewport must
                ),    // never fight a tall collapsed card (RenderFlex
              );      // overflow is a LAYOUT failure, not a pin)
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
      // The divider's breathing room lives INSIDE its vertical Padding, so
      // the padding box abuts BOTH neighbours exactly (282 == 282). The
      // honest strict pins therefore straddle the ornament: Arabic bottom
      // under its BOTTOM edge, translation top over its TOP edge — every
      // comparison keeps zero-tolerance strictness with zero flake.
      final ornament =
          tester.getRect(find.byKey(const ValueKey('hadith-card-ornament')));
      final trans =
          tester.getRect(find.byKey(const ValueKey('hadith-card-translation'))).top;
      final meta = tester.getRect(find.byKey(const ValueKey('hadith-card-meta'))).top;
      expect(badge, lessThan(arabic));
      expect(arabic, lessThan(ornament.bottom));
      expect(ornament.top, lessThan(trans));
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
  group('H2-D3/D5/D6 — sticky controls row, merged meta line, honest '
      'states', () {
    const book =
        'lib/features/hadith/presentation/hadith_book_screen.dart';

    test('D3: the controls row is sticky, singular, and holds its trio',
        () {
      final src = File(book).readAsStringSync();
      final checks = <String, bool>{
        'sticky-bottom': src.contains('bottom: PreferredSize('),
        'row-wired': src
            .contains('child: _buildStickyControlsRow(context, chapters),'),
        'controls-bar-gone': !src.contains('Widget _buildControlsBar'),
        'single-search':
            'query: _searchQuery,'.allMatches(src).length == 1,
        'search-flexes': RegExp(
                r'Expanded\(\s*child: HadithSearchField\(')
            .hasMatch(src),
        'filter-dropdown': src.contains('PopupMenuButton<String>('),
        'settings-on-row': src.contains('tooltipReadingSettings'),
        'filter-a11y':
            src.contains('tooltip: strings.tooltipFilterChapters'),
        'stat-chips-gone': !src.contains('_buildStatChip'),
        'no-grade-prop': !src.contains("'UNKNOWN'"),
        'meta-line': src.contains(r'hadiths \u00b7'),
      };
      expect(checks.entries.where((e) => !e.value).map((e) => e.key).toList(),
          isEmpty,
          reason: 'failed H2-D3 pins — the sticky row must carry '
              '[search | chapter filter | settings] and the hero must '
              'state only honest totals');
    });

    test('D5: the quick-settings sheet remains the single organized place',
        () {
      final src = File(book).readAsStringSync();
      expect(src.contains('void _showQuickSettingsSheet'), isTrue,
          reason: 'language, showArabic and both scales in ONE sheet '
              '(already true pre-H2 — audit verdict: organize, do not '
              'reinvent; pinned so a future split fails here)');
      expect(src.contains('_showReadingLanguageSheet(sheetContext)'), isTrue,
          reason: 'language row stays wired INTO the sheet (its own sheet '
              'context, not the caller\'s — the pin rides reality)');
      expect(src.contains('hadithReadingPreferencesProvider'), isTrue);
    });

    test('D6: loading/empty/error ride QibraStatus — no shimmer, and '
        'errors carry a REAL retry', () {
      final src = File(book).readAsStringSync();
      expect(src.contains('QibraStatus('), isTrue,
          reason: 'shared status widget renders loading');
      expect(src.contains('QibraStatus.empty('), isTrue);
      expect(src.contains('QibraStatus.error('), isTrue);
      expect(src.contains('CircularProgressIndicator('), isFalse,
          reason: 'the lone spinner is REPLACED by the shared widget');
      expect(src.contains('ref.invalidate(hadithsProvider(params));'),
          isTrue, reason: 'the retry actually refetches');
      expect(src.contains('ref.invalidate(hadithChaptersProvider'), isTrue);
      // Restraint lock, feature-wide: no skeleton shimmer vocabulary.
      for (final f in [
        book,
        'lib/features/hadith/presentation/hadith_screen.dart',
        'lib/features/hadith/presentation/hadith_related_section.dart',
      ]) {
        expect(RegExp(r'[Ss]himmer').hasMatch(File(f).readAsStringSync()),
            isFalse,
            reason: '$f grew shimmer — D6 forbids it');
      }
    });
  });
  group('H2-D4 — home flow order, honest continue/native/coverage lines',
      () {
    const home = 'lib/features/hadith/presentation/hadith_screen.dart';

    test('discover pane runs hero → collections → continue → recently '
        'read → featured, in order', () {
      final src = File(home).readAsStringSync();
      final i0 = src.indexOf('List<Widget> _discoverPane(');
      final i1 = src.indexOf('/// D4: the per-book continue row', i0);
      final seg = src.substring(i0, i1);
      var at = -1;
      for (final m in [
        '_TodaysHadithCard(',
        '..._collectionsSection(',
        '_continueStrip(',
        '_buildRecentlyRead(',
        'featured.when(',
      ]) {
        final p = seg.indexOf(m);
        expect(p, greaterThan(at), reason: '$m out of order');
        at = p;
      }
    });

    test('collection card: native name only when the data ships one; '
        'coverage badge only under 100', () {
      final src = File(home).readAsStringSync();
      expect(src.contains('if (book.nameArabic.isNotEmpty)'), isTrue,
          reason: 'D4 honesty: never an invented translation of a kitab '
              'name — the metadata ships it or the line does not render');
      expect(
          src.contains('.hadithCoverageOfBook('), isTrue,
          reason: 'the coverage line reuses the H1 helper, not a new one');
      expect(RegExp(r'total\) <\s*100\)').hasMatch(src), isTrue,
          reason: 'full coverage must NOT badge itself');
    });

    test('continue section is history-driven and vanishes when empty', () {
      final src = File(home).readAsStringSync();
      expect(src.contains('if (continues.isNotEmpty) ...['), isTrue);
      expect(src.contains("const QibraSectionHeader(title: 'Continue "
          "reading'),"), isTrue,
          reason: 'sections speak through QibraSectionHeader (design '
              'rule) — never hand-rolled rows');
      expect(src.contains('lastReadForBook(history, c[\'slug\']!)'), isTrue,
          reason: 'one source for continue — the same LRU reader the '
              'collection cards and the book screen use');
    });

    test('rhythm: the pre-D4 strays (14 and 20) are gone from the home '
        'flow', () {
      final src = File(home).readAsStringSync();
      expect(src.contains('const SizedBox(height: 14)'), isFalse,
          reason: '24 between sections, 12 within — 14 was neither');
      expect(src.contains('const SizedBox(height: 20)'), isFalse,
          reason: '20 -> 24 (section gap) as part of the same rhythm');
    });
  });

    test('I — migrated labels stay migrated (no raw literals return)', () {
      final home =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      final book =
          File('lib/features/hadith/presentation/hadith_book_screen.dart')
              .readAsStringSync();
      // 'All Chapters' lives in AppStrings only (D3's popup); the chip
      // rail's 'Ch N' labels go through hadithChapterShort (D6); the
      // today-card CTA reads its label from AppStrings too (I proper).
      expect(book.contains("'All Chapters'"), isFalse,
          reason: 'must come from AppStrings.hadithAllChapters');
      expect(book.contains('AppStrings.hadithAllChapters(context)'), isTrue);
      expect(book.contains("label: 'Ch '"), isFalse);
      expect(book.contains('hadithChapterShort(context, n)'), isTrue,
          reason: 'chip labels must route through the l10n builder');
      expect(home.contains("label: 'Read Full Hadith'"), isFalse);
      expect(home.contains('label: AppStrings.readFullHadith(context)'), isTrue);
    });
  }
}
