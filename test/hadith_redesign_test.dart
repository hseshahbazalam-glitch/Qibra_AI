// test/hadith_redesign_test.dart
// ============================================================
// HADITH SCREEN REDESIGN (reference image, 2026-09-05) — ANTI-DRIFT PINS
// ============================================================
// Unit pins for the two PURE helpers the redesign introduced (the hero
// quote trimmer and the reader's prev/next neighbour walk), plus source
// scans locking the new structure: the hero is REAL data (the stable
// daily hadith — never an invented aphorism), the segment rail has
// exactly the three panes whose content exists (Discover / Collections /
// My Library), and every reference element with NO feature behind it in
// Qibra (Topics tab, Sort dropdown, Listen, narrator chain, "View
// details") is asserted ABSENT so it can never creep back as chrome.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart';
import 'package:qibra_ai/shared/widgets/buttons/app_button.dart';

HadithModel _model({String en = '', String ar = ''}) => HadithModel(
      id: 'bukhari-1',
      hadithNumber: 1,
      bookSlug: 'bukhari',
      bookName: 'Sahih al-Bukhari',
      chapterNumber: 1,
      chapterName: 'Revelation',
      textArabic: ar,
      textEnglish: en,
      textUrdu: '',
      grade: HadithGrade.sahih,
      narrator: const HadithNarrator(name: '—'),
    );

void main() {
  group('HadithBookScreen.neighbourNumber — real walk, honest ends', () {
    test('neighbours follow the PUBLISHED sequence, not arithmetic', () {
      // A gap between 3 and 5 is real corpus structure: next(3) is 5.
      expect(HadithBookScreen.neighbourNumber(const [1, 2, 3, 5], 2, -1), 1);
      expect(HadithBookScreen.neighbourNumber(const [1, 2, 3, 5], 3, 1), 5);
    });

    test('ends return null — no wrap, no invented record', () {
      expect(HadithBookScreen.neighbourNumber(const [1, 2, 3], 1, -1), isNull);
      expect(HadithBookScreen.neighbourNumber(const [1, 2, 3], 3, 1), isNull);
    });

    test('unknown/empty corpus -> null (buttons disable, nothing faked)', () {
      expect(HadithBookScreen.neighbourNumber(const [1, 2, 3], 4, 1), isNull);
      expect(HadithBookScreen.neighbourNumber(const [], 1, 1), isNull);
    });
  });

  group('hadithQuotePreview — the hero never invents text', () {
    test('short text passes through VERBATIM (whitespace collapsed)', () {
      expect(
        hadithQuotePreview(_model(en: 'Actions  are   by intentions.')),
        'Actions are by intentions.',
      );
    });

    test('long text truncates at a WORD boundary with ONE ellipsis', () {
      final long = ('word ' * 100).trim();
      final out = hadithQuotePreview(_model(en: long));
      expect(out.endsWith('…'), isTrue);
      expect(out.length, lessThanOrEqualTo(221));
      // The emitted body is a verbatim prefix of the corpus text —
      // truncation must never rewrite or reorder a single character.
      expect(long.startsWith(out.substring(0, out.length - 1)), isTrue);
    });

    test('empty translation falls back to the REAL reference', () {
      final hadith = _model();
      expect(hadithQuotePreview(hadith), hadith.displayReference);
    });

    test('Arabic mode quotes the Arabic text, not an English default', () {
      final out = hadithQuotePreview(
        _model(en: 'English only', ar: 'العربية'),
        translation: 'العربية',
      );
      expect(out, 'العربية');
    });
  });

  group('hadith tab — reference structure with zero fake affordances', () {
    final home =
        File('lib/features/hadith/presentation/hadith_screen.dart')
            .readAsStringSync();

    test('hero, rail and panes exist and are wired to real surfaces', () {
      expect(home.contains('QibraHeroCard('), isTrue);
      expect(home.contains('backgroundAsset: AppAssets.hadithArt'), isTrue);
      expect(home.contains('hadithQuotePreview('), isTrue);
      // Exactly the three REAL views — no fourth pane, no dead tab.
      expect(home.contains("'Discover'"), isTrue);
      expect(home.contains("'Collections'"), isTrue);
      expect(home.contains("'My Library'"), isTrue);
      expect(home.contains('...switch (_pane) {'), isTrue);
      // CTA + search pill reuse the existing handlers.
      expect(home.contains("label: 'Read Full Hadith'"), isTrue);
      expect(home.contains('_SearchPill(onTap: () => _showSearchSheet(context))'),
          isTrue);
      // My Library renders the REAL bookmark store; See-all routes to
      // the real bookmarks screen; rows re-open real corpus data.
      expect(home.contains('final saved = ref.watch(hadithBookmarksProvider);'),
          isTrue);
      expect(home.contains('context.go(AppRoutes.bookmarks)'), isTrue);
      expect(home.contains('.getHadith(bookmark.bookSlug, bookmark.hadithNumber)'),
          isTrue);
    });

    test('reference chrome WITHOUT a feature behind it stays absent', () {
      for (final banned in [
        'Listen',
        'Sort:',
        'Explore by Topic',
        "'Topics'",
        'View full chain',
        'Comment',
        'carousel',
      ]) {
        expect(home.contains(banned), isFalse,
            reason: '"$banned" has no real feature behind it — the '
                'redesign must not fake it');
      }
      // Perf-pass: no saveLayer wrappers may come back with the hero.
      expect(home.contains('Opacity('), isFalse);
      expect(home.contains('ColorFiltered'), isFalse);
    });

    test('behavior pins survive the redesign', () {
      expect(home.contains('recordHadithView(ref, hadith)'), isTrue);
      expect(home.contains('HadithMoreFromChapter('), isTrue);
      expect(home.contains("'Recently Read'"), isTrue);
      expect(
          home.contains(
              'final previewText = translation ?? hadith.textEnglish;'),
          isTrue);
    });
  });

  group('book reader sheet — reference header, honest navigation', () {
    final book =
        File('lib/features/hadith/presentation/hadith_book_screen.dart')
            .readAsStringSync();

    test('header/bottom-rail actions all exist on real state', () {
      expect(book.contains('void openNeighbour(int number) {'), isTrue);
      expect(book.contains('HadithBookScreen.neighbourNumber('), isTrue);
      expect(book.contains("tooltip: 'Previous hadith'"), isTrue);
      expect(book.contains("tooltip: 'Next hadith'"), isTrue);
      expect(book.contains("tooltip: 'Text size & language'"), isTrue);
      // Aa opens the EXISTING quick-settings sheet (single source of the
      // split scales AND the Language row) — never a forked control.
      expect(book.contains('_showQuickSettingsSheet(context);'), isTrue);
      expect(book.contains("isHadithBookmarkedProvider(hadith.id)"), isTrue);
    });

    test('authenticity banner is grade data only', () {
      expect(book.contains('if (hadith.grade != HadithGrade.unknown) ...['),
          isTrue);
      expect(book.contains("'Grade: \${hadith.grade.label}'"), isTrue);
      expect(
          book.contains(
              "'Source: \${hadith.bookName} (\${hadith.hadithNumber})'"),
          isTrue);
      // No fake affordances copied from the reference right screen.
      expect(book.contains('Listen'), isFalse);
      expect(book.contains('View details'), isFalse);
      expect(book.contains('Narrator Chain'), isFalse);
    });

    test('one-block language semantics + Continue anchor survive', () {
      expect(book.contains('showTranslation: _showTranslation'), isTrue);
      expect(book.contains('showUrdu'), isFalse);
      expect(book.contains('showEnglish'), isFalse);
      expect(
          book.contains(
              "'Verified translation unavailable for this language.'"),
          isTrue);
      expect(book.contains('KeyedSubtree(key: _resumeKey, child: card)'),
          isTrue);
      expect(book.contains('HadithAvailability.selectorOptions()'), isTrue);
    });
  });

  group('today-card CTA row — narrow-viewport overflow guard', () {
    // Device regression (2026-09-06): 'Read Full Hadith' + two LABELED
    // QibraSoftButtons (each also Expanded) squeezed the gold label to
    // ~135dp on ~392dp screens — a 34px RenderFlex overflow. The fix:
    // icon-only ghost secondaries. This pumps the EXACT real
    // composition (public HadithGhostIconButton + AppGoldButton) in a
    // hard width box; 320 is the app's narrowest supported width.
    Future<void> pumpRow(WidgetTester tester, double width) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: Row(
                  children: [
                    Expanded(
                      child: AppGoldButton(
                        label: 'Read Full Hadith',
                        size: AppButtonSize.small,
                        fullWidth: true,
                        suffixIcon: Icons.arrow_forward_rounded,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    HadithGhostIconButton(
                      icon: Icons.bookmark_border_rounded,
                      tooltip: 'Bookmark',
                      onPressed: () {},
                    ),
                    HadithGhostIconButton(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Share',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('320dp renders the CTA row without RenderFlex overflow',
        (tester) async {
      await pumpRow(tester, 320);
      expect(tester.takeException(), isNull);
      // The CTA still renders (ellipsis-degrade is allowed, absence is
      // not) and the ghost actions are present.
      expect(find.text('Read Full Hadith'), findsOneWidget);
      expect(find.byType(HadithGhostIconButton), findsNWidgets(2));
    });

    testWidgets('360dp renders the CTA row without RenderFlex overflow',
        (tester) async {
      await pumpRow(tester, 360);
      expect(tester.takeException(), isNull);
      expect(find.text('Read Full Hadith'), findsOneWidget);
    });

    test('CTA row sources carry the fixed composition + ellipsis path', () {
      final home =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      expect(home.contains('HadithGhostIconButton('), isTrue);
      expect(home.contains("tooltip: 'Bookmark'"), isTrue);
      expect(home.contains("tooltip: 'Share'"), isTrue);
      // The labeled soft-button pair must NOT come back into this row.
      expect(
          home.contains("label: bookmarked ? 'Saved' : 'Bookmark'"), isFalse,
          reason: 'labeled siblings in the gold-CTA row overflow at '
              'narrow widths — keep the ghosts icon-only');
      final btn = File(
              'lib/shared/widgets/buttons/app_button.dart')
          .readAsStringSync();
      final content = btn.substring(btn.indexOf('_buildContent'));
      expect(content.contains('Flexible('), isTrue,
          reason: 'the gold label must degrade, never strip');
      expect(content.contains('overflow: TextOverflow.ellipsis'), isTrue);
    });
  });
}
