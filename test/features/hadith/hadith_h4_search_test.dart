// test/features/hadith/hadith_h4_search_test.dart
// ============================================================
// WORLD-CLASS HADITH PASS H4 — SEARCH, BRIDGE-EXPANDED & CURATED
// ============================================================
// P1  hadithSearchTerms: the RAW query always first (additive rule) and
//     the bridge variants VERBATIM from RagService.expandQuery — the
//     hadith side owns no second lexicon, so the two surfaces can never
//     drift apart.
// P2  rankHadithSearchMerge: matched-token density first, then relevance,
//     then kitab weight (bukhari, muslim, rest), then canonical hadith
//     number; capped at 50.
// P3  the curated quick-picks are proven REAL against the shipped JSON
//     assets themselves (SearchNormalizer folded contains, bukhari's own
//     en/ar/ur files) — a decorative chip must not ship. Tapping one
//     opens the sheet PRE-RUN on that query.
// P4  results UI: token-level highlights (a two-word query whose words
//     sit apart lights BOTH words, never the whole phrase), a tap opens
//     the hadith INSIDE its book via focusHadithNumber (the shipped
//     bookmark-jump parameter — no dead-end toast), the grade renders
//     only where the data rule allows (no fabricated Sahih), and the
//     sheet's book chips narrow the merged rows for real.
// P5  the search entry is sticky chrome OUTSIDE the scroll view (source-
//     pinned) and survives pane switches (behavior-pinned) — the future
//     H3 strip removals can never take it down with them.
//
// Wiring reuses HadithDatabaseService.testFixture (ai_revival precedent):
// a warm honest corpus stand-in; no plugin, no network, no real-corpus
// boot. ALL lib imports are package-form (battery G2 rule).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/ai/domain/rag_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart'
    show HadithBookScreen;
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart'
    show HadithScreen, hadithHighlightSpans;
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';
import 'package:qibra_ai/shared/widgets/qibra_ui.dart' show QibraCard;
import 'package:shared_preferences/shared_preferences.dart';

// ─── fixture corpus (three books, overlapping terms) ───────────────────
const _bukhari7 = LocalHadith(
  hadithNumber: 7,
  arabicNumber: 7,
  textArabic: '',
  textEnglish:
      'The prayer of the congregation is superior to the prayer of the '
      'lone one, and patience guards it',
  textUrdu: '',
  bookSlug: 'bukhari',
  bookName: 'Sahih al-Bukhari',
  bookNumber: 1,
  chapterHadithNumber: 1,
  chapterName: 'Faith',
  grade: '',
);
const _muslim12 = LocalHadith(
  hadithNumber: 12,
  arabicNumber: 12,
  textArabic: '',
  textEnglish: 'A believer who thanks and has patience',
  textUrdu: '',
  bookSlug: 'muslim',
  bookName: 'Sahih Muslim',
  bookNumber: 2,
  chapterHadithNumber: 1,
  chapterName: 'Asceticism',
  grade: '',
);
const _malik3 = LocalHadith(
  hadithNumber: 3,
  arabicNumber: 3,
  textArabic: '',
  textEnglish: 'Patience is light, water purifies, charity shields',
  textUrdu: '',
  bookSlug: 'malik',
  bookName: 'Muwatta Malik',
  bookNumber: 3,
  chapterHadithNumber: 1,
  chapterName: 'Purification',
  grade: '',
);

LocalSearchResult _hit(
  LocalHadith h, {
  double rel = 0.8,
  String channel = 'english',
}) =>
    LocalSearchResult(hadith: h, relevance: rel, matchedIn: channel);

/// Warm, honest stand-in: one folded contains-scan per term over the tiny
/// fixture corpus — mirroring the real service's matching rule — while
/// recording every batch it was asked for (the bridge plan is then
/// visible to assertions).
class _FakeDb extends HadithDatabaseService {
  _FakeDb() : super.testFixture();

  final List<List<String>> calls = [];
  static const corpus = [_bukhari7, _muslim12, _malik3];

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<List<LocalSearchResult>>> searchBatchOffMain(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    calls.add(List.of(queries));
    return [
      for (final q in queries)
        corpus
            .where((h) =>
                SearchNormalizer.contains(h.textEnglish, q) ||
                SearchNormalizer.contains(h.textArabic, q) ||
                SearchNormalizer.contains(h.textUrdu, q))
            .map((h) => _hit(h))
            .take(maxPerQuery)
            .toList(),
    ];
  }
}

ProviderContainer _container(_FakeDb db) => ProviderContainer(
      overrides: [hadithDatabaseProvider.overrideWithValue(db)],
    );

Future<void> _beat(WidgetTester tester, [int steps = 8]) async {
  // Fixed beats, no pumpAndSettle (QH lesson: timers keep that alive).
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<ProviderContainer> _pumpHome(WidgetTester tester, _FakeDb db) async {
  final container = _container(db);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: HadithScreen()),
  ));
  await _beat(tester);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ───────────────────────────── P1 ─────────────────────────────
  group('P1 — bridge expansion, raw-first and lexicon-free', () {
    test("'namaz' is searched raw FIRST, then with the bridge verbatim", () {
      final terms = hadithSearchTerms('namaz');
      expect(terms.first, 'namaz',
          reason: 'the additive rule: the raw query is always in the plan');
      expect(terms, containsAll(<String>['prayer', 'salah', 'صلاة']));
      // Reuse, not duplication: the expansion is EXACTLY what
      // RagService.expandQuery answers — inventing a hadith-side copy of
      // the table (or new Arabic guesses) would break this pin.
      expect(terms, equals(['namaz', ...RagService.expandQuery('namaz')]));
    });

    test('trimming, unknown words and non-latin scripts pass through', () {
      expect(hadithSearchTerms('  namaz '), hadithSearchTerms('namaz'));
      expect(hadithSearchTerms('qwertyuiop'), ['qwertyuiop'],
          reason: 'no bridge entry -> the raw scan alone (never dropped)');
      expect(hadithSearchTerms('صلاة'), ['صلاة'],
          reason: 'Arabic-script queries need no bridge — passthrough');
      expect(hadithSearchTerms('   '), isEmpty);
      expect(hadithSearchTerms(''), isEmpty);
    });

    test('provider e2e — a hit ONLY reachable through the bridge arrives',
        () async {
      final db = _FakeDb();
      final container = _container(db);
      addTearDown(container.dispose);
      container.read(hadithSearchQueryProvider.notifier).state = 'namaz';
      final results =
          await container.read(hadithSearchResultsProvider.future);
      expect(db.calls, hasLength(1));
      expect(db.calls.single.first, 'namaz');
      expect(results, isNotEmpty,
          reason: '"namaz" matches no fixture text — the bridge\'s '
              '"prayer" variant is the ONLY route to the bukhari hit');
      expect(results.single.hadith.id, 'bukhari_7');
      expect(results.single.matchedText, 'namaz',
          reason: 'the tile still echoes what the USER typed, not a '
              'bridge variant');
    });

    test('additive — a raw query keeps every hit it had before the bridge',
        () async {
      final db = _FakeDb();
      final container = _container(db);
      addTearDown(container.dispose);
      container.read(hadithSearchQueryProvider.notifier).state = 'patience';
      final results =
          await container.read(hadithSearchResultsProvider.future);
      expect(results.map((r) => r.hadith.id),
          containsAll(<String>['bukhari_7', 'muslim_12', 'malik_3']));
    });
  });

  // ───────────────────────────── P2 ─────────────────────────────
  group('P2 — density ranking with honest tie-breaks', () {
    test('matched-token density beats a lone higher relevance', () {
      final ranked = rankHadithSearchMerge(termResults: [
        [_hit(_bukhari7, rel: 0.95)], // one term, strong
        [_hit(_muslim12)],
        [_hit(_muslim12, rel: 0.4)], // muslim: TWO terms, weaker each
      ]);
      expect(ranked.first.hadith.id, 'muslim_12',
          reason: 'two bridge terms hit it — that is the signal');
    });

    test('a hadith hit by several terms collapses to ONE row carrying the '
        'best-scoring channel', () {
      final ranked = rankHadithSearchMerge(termResults: [
        [_hit(_bukhari7, rel: 0.5)],
        [_hit(_bukhari7, rel: 0.9, channel: 'arabic')],
      ]);
      expect(ranked, hasLength(1));
      expect(ranked.single.relevance, 0.9);
      expect(ranked.single.matchedIn, 'arabic');
    });

    test('ties fall to relevance, then bukhari/muslim first, then number',
        () {
      final ranked = rankHadithSearchMerge(termResults: [
        [
          _hit(_malik3, rel: 0.7),
          _hit(_muslim12, rel: 0.7),
          _hit(_bukhari7, rel: 0.7),
        ],
      ]);
      expect(ranked.map((r) => r.hadith.id),
          ['bukhari_7', 'muslim_12', 'malik_3']);
      expect(hadithBookWeight('bukhari'), lessThan(hadithBookWeight('nasai')));
      expect(hadithBookWeight('tirmidhi'), hadithBookWeight('malik'),
          reason: 'no fabricated tiering beyond the two Sahih books');
    });

    test('the result list is capped at 50 by default', () {
      final many = [
        for (var n = 1; n <= 60; n++)
          _hit(LocalHadith(
            hadithNumber: n,
            arabicNumber: n,
            textArabic: '',
            textEnglish: 'patience $n',
            textUrdu: '',
            bookSlug: 'nasai',
            bookName: 'Sunan an-Nasa\'i',
            bookNumber: 1,
            chapterHadithNumber: 1,
            chapterName: '',
            grade: '',
          )),
      ];
      expect(rankHadithSearchMerge(termResults: [many]), hasLength(50));
      expect(rankHadithSearchMerge(termResults: [many], maxResults: 7),
          hasLength(7));
    });
  });

  // ───────────────────────────── P3 ─────────────────────────────
  group('P3 — curated quick-picks are real, not decorative', () {
    test('every chip label exists (folded) in the SHIPPED bukhari data, '
        'in its own language file', () {
      // The pass rule: chips must be actual hadith strings. The only
      // proof that counts is against the asset the app actually reads.
      final byLang = {
        'english': {
          AppStrings.forCode('en').hadithQuickPrayer,
          AppStrings.forCode('en').hadithQuickPatience,
          AppStrings.forCode('en').hadithQuickCharity,
          AppStrings.forCode('en').hadithQuickWater,
        },
        'arabic': {
          AppStrings.forCode('ar').hadithQuickPrayer,
          AppStrings.forCode('ar').hadithQuickPatience,
          AppStrings.forCode('ar').hadithQuickCharity,
          AppStrings.forCode('ar').hadithQuickWater,
        },
        'urdu': {
          AppStrings.forCode('ur').hadithQuickPrayer,
          AppStrings.forCode('ur').hadithQuickPatience,
          AppStrings.forCode('ur').hadithQuickCharity,
          AppStrings.forCode('ur').hadithQuickWater,
        },
      };
      for (final entry in byLang.entries) {
        final lang = entry.key;
        final raw = File('assets/data/hadith/bukhari/$lang.json')
            .readAsStringSync();
        final texts = ((jsonDecode(raw)['hadiths'] ?? []) as List)
            .map((h) => (h as Map)['text'])
            .whereType<String>()
            .toList();
        for (final label in entry.value) {
          expect(
            texts.where((t) => SearchNormalizer.contains(t, label)).length,
            greaterThan(0),
            reason: 'decorative chip: "$label" hits no $lang hadith text',
          );
        }
      }
    });

    testWidgets('the four chips render under the home entry and PRE-RUN '
        'the sheet on their query', (tester) async {
      final db = _FakeDb();
      final container = await _pumpHome(tester, db);
      for (final label in ['Prayer', 'Patience', 'Charity', 'Water']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Patience'));
      await _beat(tester);
      // Sheet open, field pre-filled, provider already on the query.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Patience');
      expect(container.read(hadithSearchQueryProvider), 'Patience');
      // The pre-run query ALREADY answered when the sheet arrived —
      // asserted on the provider state (deterministic), not on painted
      // tile text: the sheet's tile preview is a RichText with a
      // maxLines:2 clip, and painting is not the contract.
      final state = container.read(hadithSearchResultsProvider);
      expect(state.hasValue, isTrue, reason: '$state');
      expect(state.valueOrNull!.map((r) => r.hadith.id).toSet(),
          containsAll(<String>['bukhari_7', 'muslim_12', 'malik_3']),
          reason: 'fake corpus holds one patience row per book — all '
              'three ride through the sheet provider');
    });
  });

  // ───────────────────────────── P4 ─────────────────────────────
  group('P4 — result UI: token highlights, book jump, honest grade, '
      'book filter', () {
    test('highlight is TOKEN-level: words apart light BOTH, phrase never',
        () {
      const style = TextStyle(fontSize: 12);
      const accent = Color(0xFF010203);
      const text = 'patience and water';
      final spans = hadithHighlightSpans(text, 'patience water', style, accent);
      final emphasized = spans
          .where((sp) => sp.style?.fontWeight == FontWeight.w800)
          .map((sp) => sp.text)
          .toList();
      expect(emphasized, ['patience', 'water']);
      expect(spans.map((sp) => sp.text).join(), text,
          reason: 'a partition — emphasis never rewrites or reorders');
      // The overlapping tokens 'water'/'wat' must highlight ONE span.
      final overlap =
          hadithHighlightSpans('water works', 'water wat', style, accent);
      expect(
          overlap
              .where((sp) => sp.style?.fontWeight == FontWeight.w800)
              .length,
          1);
      // Single-term behavior is byte-for-byte the old contract.
      expect(
        hadithHighlightSpans(text, 'patience', style, accent)
            .first
            .text,
        'patience',
      );
    });

    testWidgets('a result row opens the hadith INSIDE its book at its '
        'number (no dead-end)', (tester) async {
      final db = _FakeDb();
      await _pumpHome(tester, db);
      await tester.tap(find.text('Patience'));
      await _beat(tester);
      // bukhari leads (density tie -> kitab weight).
      await tester.tap(find.text('Sahih al-Bukhari 7'));
      await _beat(tester, 10);
      final screen =
          tester.widget<HadithBookScreen>(find.byType(HadithBookScreen));
      expect(screen.focusHadithNumber, 7);
      expect(screen.book.slug, 'bukhari');
      // The cold singleton behind HadithBookScreen's focus-lookup answers
      // honestly-empty (a snackbar, no fabricated detail) — let its
      // auto-dismiss timer COMPLETE so the test ends with zero pending
      // timers.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('grade renders where the data rule allows — and is NEVER '
        'fabricated', (tester) async {
      final db = _FakeDb();
      await _pumpHome(tester, db);
      await tester.tap(find.text('Patience'));
      await _beat(tester);
      // The fixture rows all carry grade: '' — bukhari/muslim legitimately
      // show the DISCLOSED collection grade; malik (unknown) must render
      // NO grade text at all.
      expect(find.text('Sahih'), findsNWidgets(2),
          reason: 'exactly the two collection-grade books — the rule from '
              'gradeForLocalHadith, surfaced once per row');
      // Scope to the malik TILE (walk up to the QibraCard the tile builds)
      // — a bare find.text('Muwatta Malik 3') descendant search would be
      // vacuously true.
      final malikTile = find.ancestor(
        of: find.text('Muwatta Malik 3'),
        matching: find.byType(QibraCard),
      );
      expect(malikTile, findsOneWidget);
      expect(
        find.descendant(of: malikTile, matching: find.text('Sahih')),
        findsNothing,
        reason: 'an ungraded row never borrows a grade',
      );
      // ...while the two collection-grade books DO show the disclosed
      // label inside their tiles.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Sahih al-Bukhari 7'),
            matching: find.byType(QibraCard),
          ),
          matching: find.text('Sahih'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the sheet\'s book chips really narrow the merged hits',
        (tester) async {
      final db = _FakeDb();
      final container = await _pumpHome(tester, db);
      await tester.tap(find.text('Patience'));
      await _beat(tester);
      expect(find.text('Sahih al-Bukhari 7'), findsOneWidget);
      expect(find.text('Muwatta Malik 3'), findsOneWidget);
      // The rail behind the sheet shows the same book NAMES (static
      // fallback when the fake db has no loaded books), so the chip
      // finder is scoped to the sheet — exact-text finders on the whole
      // tree would match two.
      final sheet = find.byType(ModalBottomSheet);
      expect(find.descendant(of: sheet, matching: find.text('All collections')),
          findsOneWidget);
      await tester.tap(
          find.descendant(of: sheet, matching: find.text('Sahih Muslim')));
      await _beat(tester);
      expect(container.read(hadithSearchBookFilterProvider), 'muslim');
      expect(find.text('Sahih Muslim 12'), findsOneWidget);
      expect(find.text('Sahih al-Bukhari 7'), findsNothing);
      expect(find.text('Muwatta Malik 3'), findsNothing);
      // Closing the sheet resets the session state (no silently-narrowed
      // next open).
      // Close the sheet the way the barrier does (pageBack needs a back
      // button the bottom sheet never had).
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await _beat(tester);
      expect(container.read(hadithSearchBookFilterProvider), isNull);
      expect(container.read(hadithSearchQueryProvider), '');
    });
  });

  // ───────────────────────────── P5 ─────────────────────────────
  group('P5 — the entry is sticky chrome, not strip', () {
    test('source pin: the pill+chips live OUTSIDE the ListView, before '
        'the pane switch', () {
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      final header = src.indexOf('child: Column(');
      final pill = src.indexOf(
          "_SearchPill(onTap: () => _showSearchSheet(context))", header);
      final list = src.indexOf('child: ListView(', header);
      final pane = src.indexOf('...switch (_pane)', header);
      expect(header, greaterThan(-1));
      expect(pill, greaterThan(-1),
          reason: 'exactly one pill — the sticky one (the hero copy was '
              'removed by this pass)');
      expect(pill, lessThan(list),
          reason: 'the entry must be above the scroll view');
      expect(pane, greaterThan(list),
          reason: 'panes (and any future strip removal) live INSIDE the '
              'scroll view — they can never host or take the entry');
      expect(
          RegExp('_SearchPill\\(onTap').allMatches(src).length, 1,
          reason: 'one and only one search pill CALL in the screen (the '
              'class definition itself does not carry onTap( )');
    });

    testWidgets('the entry survives switching panes (and reopens fine)',
        (tester) async {
      final db = _FakeDb();
      await _pumpHome(tester, db);
      expect(find.text('Search hadith…'), findsOneWidget);
      await tester.tap(find.text('Collections').first, warnIfMissed: false);
      await _beat(tester);
      expect(find.text('Search hadith…'), findsOneWidget,
          reason: 'pane 1 swapped the whole scroll content — the sticky '
              'header is untouched');
      await tester.tap(find.text('My Library'));
      await _beat(tester);
      expect(find.text('Patience'), findsOneWidget);
      // And the pill still opens a working sheet from a non-Discover pane.
      await tester.tap(find.text('Search hadith…'));
      await _beat(tester);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
