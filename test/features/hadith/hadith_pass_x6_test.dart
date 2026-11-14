// test/features/hadith/hadith_pass_x6_test.dart
// ============================================================
// PASS X6 — HOTFIX pins. Two owner-device findings (profile mode, CPH2573,
// ccd52cd) that no CI run could have caught:
//
// R1  "a search result does nothing, the sheet stays right there". The tap
//     popped through the BuildContext of its OWN ListView item; after the
//     debounced search rebuilt the list that element can already be gone, and
//     any Navigator lookup on it throws BEFORE the pop. Widget tests tap a
//     settled tree with asserts ON, so the class is CI-invisible — kDebugMode
//     is a const and cannot be overridden from a test, which is why half of
//     this file is source-pinned: code-review-shaped pins are the only
//     profile-parity tool available here.
// R2  "bahut sare hadith blank" while reading Urdu. The data's truth (the
//     nasai/urdu edition carries nothing for 1,890 of 5,765 hadiths — measured
//     from the shipped files below, and the bytes are base-identical), but the
//     UI answered that emptiness with an English sentence, i.e. with nothing
//     a reader of that book can use. The fix is a state, not a blank: the
//     honest line in the reader's language, the Arabic body always, and a chip
//     that reveals the English of the SAME hadith.
//
// Conventions match hadith_pass_h2_test / hadith_multilang_test: render-pins
// where a painted pixel is the truth, source pins where the bug class is
// grep-visible, pure units where a helper carries the rule.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/hadith/data/hadith_availability.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart'
    show localToHadithModel;
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart'
    show HadithBookScreen, HadithCard, HadithTranslationFallback;

import 'package:shared_preferences/shared_preferences.dart';

const _parent = LocalHadith(
  hadithNumber: 402,
  arabicNumber: 402,
  textEnglish: 'parent text',
  textUrdu: '',
  bookSlug: 'bukhari',
  bookName: 'Sahih al-Bukhari',
  bookNumber: 4,
  chapterHadithNumber: 1,
  chapterName: 'Knowledge',
  grade: '',
  pairKey: '402|402',
);

/// The dataset's own fractional row: SAME truncated int, different hadith.
const _fraction = LocalHadith(
  hadithNumber: 402,
  arabicNumber: 402,
  textEnglish: 'fraction text',
  textUrdu: '',
  bookSlug: 'bukhari',
  bookName: 'Sahih al-Bukhari',
  bookNumber: 4,
  chapterHadithNumber: 2,
  chapterName: 'Knowledge',
  grade: '',
  pairKey: '402.2|402.2',
);

/// Only the corpus view is overridden: [HadithDatabaseService.getHadithByKey]
/// reads through getHadiths (which IS `_bookData[slug] ?? []`), so the exact
/// key lookup is testable without a 108 MB boot.
class _KeyedDb extends HadithDatabaseService {
  _KeyedDb() : super.testFixture();

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  List<LocalHadith> getHadiths(String bookSlug) =>
      bookSlug == 'bukhari' ? const [_parent, _fraction] : const [];
}

HadithModel _model({
  String english = 'parent text',
  String urdu = '',
  String hadithKey = '',
  int number = 402,
}) =>
    HadithModel(
      id: 'bukhari_$number',
      hadithNumber: number,
      bookSlug: 'bukhari',
      bookName: 'Sahih al-Bukhari',
      chapterNumber: 4,
      chapterName: 'Knowledge',
      textEnglish: english,
      textUrdu: urdu,
      hadithKey: hadithKey,
      grade: HadithGrade.unknown,
      narrator: const HadithNarrator(name: ''),
    );

Future<void> _pumpCard(
  WidgetTester tester,
  HadithModel hadith, {
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: <ThemeExtension<dynamic>>[QibraColors.dark],
      ),
      home: AppStringsScope(
        locale: locale,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 360,
                child: HadithCard(
                  hadith: hadith,
                  showTranslation: true,
                  positionLabel:
                      HadithBookScreen.hadithPositionLabel(hadith.hadithNumber, 7589),
                  expanded: false,
                  onToggleExpand: () {},
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ───────────────── R1 / H1c — a fractional hit stays ITS hadith ─────────
  group('X6 H1c — the pair key is what a fractional row is identified by', () {
    test('the reader-facing number is the edition\'s, not the truncated int',
        () {
      expect(_parent.numberLabel, '402');
      expect(_fraction.numberLabel, '402.2',
          reason: 'bukhari carries 26 of these and tirmidhi 42; the int field '
              'cannot hold one, so the label must come from the pair key');
      expect(_fraction.displayReference, 'Sahih al-Bukhari 402.2');
      // The id STAYS int-derived on purpose: it is the key of persisted
      // bookmarks, prefs and the expand set — silently widening it would
      // orphan what is already on a device. Documented limitation, not an
      // oversight.
      expect(_fraction.id, 'bukhari_402');
    });

    test('HadithModel keeps the key it was loaded with and labels from it', () {
      expect(_model().hadithKey, isEmpty);
      expect(_model().numberLabel, '402');
      final keyed = _model(hadithKey: '402.2|402.2');
      expect(keyed.numberLabel, '402.2');
      expect(keyed.displayReference, contains('402.2'));
      expect(keyed.copyWith(textEnglish: 'x').numberLabel, '402.2',
          reason: 'copyWith must not drop the identity of the row');
    });

    test('localToHadithModel carries the loader\'s key through', () {
      expect(localToHadithModel(_fraction).hadithKey, '402.2|402.2');
      expect(localToHadithModel(_fraction).numberLabel, '402.2');
    });

    test('getHadithByKey resolves the exact row; a miss is a miss', () {
      final db = _KeyedDb();
      // The ambiguity this fix exists for, stated from the fixture: BOTH rows
      // carry the same int, so the int lookup's answer is load order rather
      // than the reader's intent — a hit on 402.2 opens 402 and shows the
      // wrong hadith under a number that looks right. (hadith_pass_h1_test
      // already mirrors the int path's last/first-wins rule against the real
      // files; X6 does not change it, it stops trusting it for identity.)
      expect(_parent.hadithNumber, _fraction.hadithNumber);
      // Exact key → exact row.
      expect(db.getHadithByKey('bukhari', '402.2|402.2')!.textEnglish,
          'fraction text');
      expect(db.getHadithByKey('bukhari', '402|402')!.textEnglish,
          'parent text');
      // An empty key is not "look for anything", and an unknown key must not
      // degrade to a neighbour — the caller falls back to the chapter (H1d).
      expect(db.getHadithByKey('bukhari', ''), isNull);
      expect(db.getHadithByKey('bukhari', '904|904'), isNull);
      expect(db.getHadithByKey('muslim', '402.2|402.2'), isNull);
    });
  });

  // ──────────────── R1 / H1a+b+d — the tap and the landing point ──────────
  group('X6 H1 — the search tap cannot silently do nothing', () {
    test('the pop happens on the SHEET element, never on a list-item context',
        () {
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      // The result row's whole handler is now one call on the sheet's State.
      expect(src.contains('onTap: () => _openHadith(hadith)'), isTrue);
      // The negative has to be about the HANDLER, not about that text pair:
      // `pop();` followed by `widget.onOpenInBook` is exactly what _openHadith
      // now contains (asserted two lines below), so a bare substring scan fails
      // on the fix itself — that was red round 2, CI-only. What R1 forbids is a
      // pop issued FROM THE ROW, on an element that can already be recycled when
      // the tap fires on touch-up. `[^;]*` cannot cross the end of an
      // `onTap: () => …;` line, so this matches only a row popping itself.
      expect(
          RegExp(r"onTap:[^;]*Navigator\.of\(context\)\.pop").hasMatch(src),
          isFalse,
          reason: 'R1: no search-result row may pop on its own itemBuilder context');
      final start = src.indexOf('void _openHadith(HadithModel hadith)');
      expect(start, greaterThan(0));
      final body = src.substring(start, src.indexOf('\n  }', start));
      expect(body.contains('if (!mounted) return;'), isTrue,
          reason: 'the sheet guards its own element before touching the Navigator');
      expect(body.contains('Navigator.of(context).pop();'), isTrue,
          reason: 'context here is _HadithSearchSheetState\'s — alive for the '
              'whole life of the sheet');
      expect(body.contains('widget.onOpenInBook(hadith);'), isTrue,
          reason: 'and the push stays the screen\'s job (it owns the position)');
    });

    test('_openHadithInBook guards the mount and hands over key + chapter', () {
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      final start =
          src.indexOf('void _openHadithInBook(BuildContext context, HadithModel hadith) {');
      expect(start, greaterThan(0));
      final body = src.substring(start, src.indexOf('\n  }', start));
      expect(body.contains('if (!mounted) return;'), isTrue,
          reason: 'a fast back-swipe can retire the screen in the same frame '
              'as the sheet pop that asked for this push');
      expect(body.contains('focusHadithKey: hadith.hadithKey'), isTrue);
      expect(body.contains('focusChapterNumber: hadith.chapterNumber'), isTrue);
    });

    test('the book resolves focus key-first and lands on the chapter on a miss',
        () {
      final book =
          File('lib/features/hadith/presentation/hadith_book_screen.dart')
              .readAsStringSync();
      expect(book.contains('final String focusHadithKey;'), isTrue,
          reason: 'typed field with a non-null String type — the shape that '
              'leaves every pre-X6 (int-only) entry point compiling unchanged');
      expect(book.contains("this.focusHadithKey = '',"), isTrue,
          reason: 'int-only entry points (bookmarks) keep working untouched');
      expect(book.contains('focusChapterNumber = 0,'), isTrue);
      expect(
          book.contains('getHadithByKey(widget.book.slug, widget.focusHadithKey)'),
          isTrue);
      expect(book.contains('getHadith(widget.book.slug, widget.focusHadithNumber)'),
          isTrue,
          reason: 'the int path survives for requests that carry no key');
      // The dead-end rule: a miss must move the reader somewhere real, not
      // just toast. Before X6 the null branch was `showSnackBar(...); return;`.
      expect(book.contains('if (local == null) {\n      _landOnFocusTarget();'),
          isTrue);
      final jump = book.indexOf('void _landOnFocusTarget()');
      expect(jump, greaterThan(0));
      final body = book.substring(jump, book.indexOf('\n  }', jump));
      expect(body.contains('setState(() => _selectedChapterNumber = chapter)'),
          isTrue,
          reason: 'the list is filtered to the chapter the hit came from');
      expect(body.contains('AppStrings.of(context)'), isTrue,
          reason: 'the footnote is copy from the strings table, like every '
              'other surface in this app');
      expect(body.contains('thatHadithNotBundled'), isTrue,
          reason: 'a search hit must not be called a bookmark');
      expect(body.contains('thatBookmarkNotBundled'), isTrue,
          reason: 'and the bookmark wording stays for bookmarks');
      expect(RegExp(r"if \(!mounted\) return;\s*\n\s*_showHadithDetailSheet")
          .hasMatch(book),
          isTrue,
          reason: 'and the sheet opens only if this route is still there');
    });
  });

  // ────────────────────── R2 / H2a — blank becomes a state ────────────────
  group('X6 H2a — a missing translation renders an honest state', () {
    testWidgets('no English-to-reveal: the state shows and no chip promises '
        'it', (tester) async {
      // Reader language 'en' + textEnglish '' is the reachable shape of
      // "the bundle has nothing for this hadith in your language" without a
      // provider override — and it is exactly the muslim/abudawud blank-text
      // shape in the shipped data.
      await _pumpCard(tester, _model(english: ''));
      expect(
          find.text(AppStrings.forCode('en').translationNotInThisLanguage),
          findsOneWidget,
          reason: 'a hadith card must never render an empty translation area');
      expect(find.byType(ActionChip), findsNothing,
          reason: 'no bundled English, so no promise of it either');
      // HR-2.1 re-pin. This test used to end by proving the Arabic body was
      // still painted above the fallback line ("the fallback never replaces
      // text"). The Arabic edition is unbundled, so there is no body above —
      // and the two assertions that matter to X6 are unchanged: the honest
      // state still renders, and it now renders as the card's whole body,
      // which is exactly the case the chip exists for.
      expect(find.byType(HadithTranslationFallback), findsOneWidget,
          reason: 'the honest state is a real widget, not a comment');
    });

    testWidgets('the state follows the APP locale — an Urdu reader reads Urdu',
        (tester) async {
      await _pumpCard(tester, _model(english: ''), locale: const Locale('ur'));
      expect(
          find.text(AppStrings.forCode('ur').translationNotInThisLanguage),
          findsOneWidget,
          reason: 'R2 was an English apology inside an Urdu book — the wording '
              'must arrive in the language the reader is in');
      expect(find.text(AppStrings.forCode('en').translationNotInThisLanguage),
          findsNothing);
    });

    testWidgets('the chip reveals the English of the SAME hadith, and puts it '
        'away', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          extensions: <ThemeExtension<dynamic>>[QibraColors.dark],
        ),
        home: const Scaffold(
          body: Center(
            child: HadithTranslationFallback(
              englishText: 'the english body of this very hadith',
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('the english body of this very hadith'), findsNothing);

      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(find.text('the english body of this very hadith'), findsOneWidget,
          reason: 'the way out of the state, on the card that hit it');
      expect(find.byType(ActionChip), findsNothing,
          reason: 'no second prompt once it is open');
      expect(find.text(HadithAvailability.label('en')), findsOneWidget,
          reason: 'the revealed block says which language it is — the matrix '
              'supplies the name, never a literal here');

      await tester.tap(find.text(AppStrings.forCode('en').close));
      await tester.pump();
      expect(find.text('the english body of this very hadith'), findsNothing);
      expect(find.byType(ActionChip), findsOneWidget);
    });

    test('the English-only apology is gone from every reader surface — and '
        'only from those', () {
      const lit = "'Verified translation unavailable for this language.'";
      for (final p in [
        'lib/features/hadith/presentation/hadith_book_screen.dart',
        'lib/features/hadith/presentation/hadith_screen.dart',
      ]) {
        expect(File(p).readAsStringSync().contains(lit), isFalse,
            reason: '$p still hardcodes the fallback copy');
      }
      // The Quran surface keeps the generic key on purpose (it is not this
      // bug, and it was already localized through AppStrings).
      final quran =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync();
      expect(quran.contains('strings.translationUnavailable'), isTrue);
      // Hadith surfaces now route through the hadith-specific key.
      final book =
          File('lib/features/hadith/presentation/hadith_book_screen.dart')
              .readAsStringSync();
      expect(book.contains('AppStrings.of(context).translationNotInThisLanguage'),
          isTrue);
      expect(book.contains('HadithTranslationFallback('), isTrue);
    });

    test('the two new keys carry all three languages (i18n census, same '
        'commit)', () {
      // Not `const`: forCode() is a static method, so the analyzer rejects a
      // const initializer here (this was red round 1 — CI caught what no local
      // SDK could).
      final en = AppStrings.forCode('en');
      for (final code in ['ar', 'ur']) {
        final s = AppStrings.forCode(code);
        expect(s.translationNotInThisLanguage.trim().isNotEmpty, isTrue);
        expect(s.viewEnglishInstead.trim().isNotEmpty, isTrue);
        expect(s.translationNotInThisLanguage == en.translationNotInThisLanguage,
            isFalse,
            reason: '$code fell through to English');
        expect(s.viewEnglishInstead == en.viewEnglishInstead, isFalse);
      }
      // The point of the wording, not just its presence: 'tarjuma … maujood
      // nahin' is what the owner asked the reader to be told.
      expect(AppStrings.forCode('ur').translationNotInThisLanguage,
          contains('موجود نہیں'));
      expect(AppStrings.forCode('ur').viewEnglishInstead, contains('انگریزی'));
    });
  });

  // ──────────────── R2 / H2b — the coverage line stays honest ─────────────
  group('X6 H2b — coverage below 100% is measured, shown and pinned', () {
    // Computed HERE, from the shipped files, with the loader's own rule
    // (urdu joined onto the english rows by hadithnumber, int map, last wins,
    // blanks included) — so this fails if the data moves and cannot be
    // quietly re-pinned to a number that looks nicer.
    Map<String, dynamic> bookJson(String slug, String edition) => jsonDecode(
        File('assets/data/hadith/$slug/$edition.json').readAsStringSync())
        as Map<String, dynamic>;
    // The loader's own tolerant parse, mirrored (HadithDatabaseService
    // ._parseHadithNumber) — a different rule here would pin a number the
    // app never actually computes.
    int numberKey(dynamic v) {
      if (v is num) return v.toInt();
      final m = RegExp(r'^(\d+)').firstMatch((v ?? '').toString());
      return m == null ? 0 : (int.tryParse(m.group(1)!) ?? 0);
    }
    String text(Map<String, dynamic> r) => '${r['text'] ?? ''}'.trim();

    ({int nonEmpty, int total}) coverage(String slug) {
      final en = (bookJson(slug, 'english')['hadiths'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final ur = <int, String>{};
      for (final r in (bookJson(slug, 'urdu')['hadiths'] as List<dynamic>)
          .cast<Map<String, dynamic>>()) {
        ur[numberKey(r['hadithnumber'])] = text(r);
      }
      var nonEmpty = 0;
      for (final r in en) {
        if ((ur[numberKey(r['hadithnumber'])] ?? '').isNotEmpty) nonEmpty++;
      }
      return (nonEmpty: nonEmpty, total: en.length);
    }

    test('nasai/urdu is the 67% the reader is told — and malik the 86%', () {
      final nasai = coverage('nasai');
      expect(nasai.total, 5765);
      expect(HadithAvailability.coveragePercent(nasai.nonEmpty, nasai.total), 67,
          reason: 'nasai/urdu is the book behind R2; if this moves, the data '
              'moved and every fallback expectation must be re-read');
      final malik = coverage('malik');
      expect(HadithAvailability.coveragePercent(malik.nonEmpty, malik.total), 86);
      // And a full book must NOT get a note anywhere.
      final bukhari = coverage('bukhari');
      expect(HadithAvailability.coveragePercent(bukhari.nonEmpty, bukhari.total),
          greaterThan(90),
          reason: 'bukhari/urdu sits above the disclosure threshold, which is '
              'why R2 reads as ONE book being broken rather than all of them');
    });

    test('both coverage lines render only below 100%, from the same math', () {
      final book = File('lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      expect(book.contains('pct >= 100 ? null : sheetStrings.hadithCoverageOfBook(pct)'),
          isTrue,
          reason: "the book's language sheet: no claim of partial coverage "
              'when the edition is complete');
      final home = File('lib/features/hadith/presentation/hadith_screen.dart')
          .readAsStringSync();
      expect(home.contains('HadithAvailability.coveragePercent('), isTrue);
      expect(home.contains('hadithCoverageOfBook('), isTrue,
          reason: 'the home tab carries the same line for the active language');
    });
  });
}
