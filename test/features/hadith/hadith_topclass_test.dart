// test/hadith_topclass_test.dart
// ============================================================
// TOP-CLASS ELEVATION PASS (2026-09-08) — pins for what the pass ADDED:
// the real Hijri today-line on the Today card, the honest per-book
// Continue chip on the Collections covers, and the reader header's
// 'Hadith N of M' position line. Micro-interaction (light-impact) and
// a11y (tooltip) deltas are pinned structurally.
//
// EVERY data source here is real, verified by reading the code before
// building: hijri ^3.0.1 package math (home_hero precedent), the
// HadithViewHistory '<slug>#<number>' LRU surfaced via
// hadithHistoryProvider (cap 50, newest-first, written ONLY by
// recordHadithView on real detail opens), and LocalBookInfo.totalHadiths
// from getBookInfo. Nothing may render state the app never recorded.
//
// Item 2 (search highlighting) and 4a (Arabic line-height) were found
// ALREADY SHIPPED + unit-tested by the world-class pass at this tip
// (hadithHighlightSpans + hadith_world_class_pass_test.dart; reader-sheet
// Arabic already at height: 1.8) — this file guards their WIRING against
// drift only. No re-implementation, no weakening of any existing pin.
// ============================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart'
    show HadithBookScreen;
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart'
    show hijriTodayLabel, lastReadForBook;

import 'support/source_guards.dart';

const _screen = 'lib/features/hadith/presentation/hadith_screen.dart';
const _book = 'lib/features/hadith/presentation/hadith_book_screen.dart';

HadithModel _model(int number, {String slug = 'bukhari'}) => HadithModel(
      id: '$slug-$number',
      hadithNumber: number,
      bookSlug: slug,
      bookName: 'Sahih al-Bukhari',
      chapterNumber: 1,
      chapterName: '',
      textArabic: '',
      textEnglish: 'Actions are but by intentions.',
      textUrdu: '',
      grade: HadithGrade.unknown,
      narrator: const HadithNarrator(name: '—'),
    );

void main() {
  group('Today card — real Hijri date line (item 1)', () {
    test('label format is exact package math on a FIXED date — no now()', () {
      // HijriCalendar.fromDate is the package's deterministic entry
      // point (islamic_calendar_screen precedent); the test never calls
      // DateTime.now through the widget path.
      final h = HijriCalendar.fromDate(DateTime(2026, 9, 7));
      expect(hijriTodayLabel(h), '${h.hDay} ${h.longMonthName} ${h.hYear} AH',
          reason: 'the formatter echoes EXACTLY the package fields');
      expect(hijriTodayLabel(h), matches(r'^\d{1,2} .+ \d{4} AH$'),
          reason: 'the visible contract shared with home_hero.dart:62-64 '
              'and prayer_times_screen.dart:49-53 — the surfaces can '
              'never drift apart in shape');
      expect(h.hYear, inInclusiveRange(1447, 1448),
          reason: 'bounded sanity only; the conversion belongs to the '
              'package, not to an assertion');
    });

    test('the card wires HijriCalendar.now() via the bundled dep', () {
      final src = File(_screen).readAsStringSync();
      expect(src.contains('hijriTodayLabel(HijriCalendar.now())'), isTrue);
      expect(
          src.contains("import 'package:hijri/hijri_calendar.dart';"), isTrue);
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(RegExp('hijri:').hasMatch(pub), isTrue,
          reason: 'existing dependency — the elevation pass added NO '
              'package (hard constraint)');
    });
  });

  group('Collections — honest per-book Continue chip (item 3)', () {
    // DATA SOURCE CITED (per the honest-absence rule): hadith_screen's
    // _collectionsPane reads hadithHistoryProvider — the HadithModel view
    // of HadithViewHistory.entries(), the persisted LRU of
    // '<bookSlug>#<hadithNumber>' refs. The store has NO timestamps and
    // NO counts, so the chip renders no 'read 2m ago'-style fiction —
    // only 'Continue · Hadith N' from a recorded entry.
    test('newest-first entry wins; absence -> null (never derived)', () {
      final history = [
        _model(4), // most recent overall
        _model(7, slug: 'muslim'),
        _model(9), // older bukhari entry the LRU already deduped front
      ];
      expect(lastReadForBook(history, 'bukhari')?.hadithNumber, 4,
          reason: 'LRU is newest-first — the FIRST match IS continue '
              '(exact contract hadith_world_class_pass_test pins for the '
              'book-screen resume)');
      expect(lastReadForBook(history, 'muslim')?.hadithNumber, 7);
      expect(lastReadForBook(const [], 'bukhari'), isNull,
          reason: 'honest absence: no history -> no chip, ever');
      expect(lastReadForBook(history, 'malik'), isNull,
          reason: 'a book without recorded position gets nothing');
    });

    test('the cover chip has exactly one guarded render path', () {
      final src = stripCommentsForGuard(File(_screen).readAsStringSync());
      expect(src.contains('lastReadForBook(history, book.slug)'), isTrue);
      expect(src.contains('if (cont != null) ...['), isTrue,
          reason: 'the ONLY path that paints the chip is the null-guarded '
              'one — an empty store cannot fabricate a position');
      expect(src.contains(r"'Continue · Hadith ${cont.hadithNumber}'"), isTrue);
      expect(src.contains('ref.watch(hadithHistoryProvider)'), isTrue);
    });
  });

  group('Reader header — real position, honest total (item 4)', () {
    test('hadithPositionLabel: the of-M part renders ONLY for real totals',
        () {
      expect(HadithBookScreen.hadithPositionLabel(4, 7563),
          'Hadith 4 of 7563');
      expect(HadithBookScreen.hadithPositionLabel(4, 0), 'Hadith 4',
          reason: 'totalHadiths == 0 means the book metadata is absent — '
              'the of-M hides instead of guessing a total');
      expect(HadithBookScreen.hadithPositionLabel(1, 1), 'Hadith 1 of 1');
    });

    test('the sheet header is the helper\'s single caller (no stale literal)',
        () {
      final src = File(_book).readAsStringSync();
      expect(src.contains('HadithBookScreen.hadithPositionLabel('), isTrue);
      expect(src.contains(r"'Hadith ${hadith.hadithNumber}'"), isFalse,
          reason: 'the old bare-N header literal must not survive beside '
              'the helper — one source for the line');
    });

    test('Arabic line-heights VERIFIED, not restacked (item 4a)', () {
      // The reader sheet already shipped the elevation target; the tab
      // sheet uses the relaxed token. Both must STAY (flattening 2.2 to
      // 1.8 would be a regression — verify-and-keep, honestly reported).
      expect(File(_book).readAsStringSync().contains('height: 1.8'), isTrue);
      expect(
          File(_screen).readAsStringSync().contains('AppArabicStyles.hadithArabic'),
          isTrue);
    });
  });

  group('micro-interactions — light impact, not novelty (item 5)', () {
    test('hadith tab: pane switch, copy success, both bookmarks fire it', () {
      final src = File(_screen).readAsStringSync();
      expect(
          RegExp(
                  r'HapticFeedback\.lightImpact\(\);\s*setState\(\(\) => _pane = index\)')
              .hasMatch(src),
          isTrue,
          reason: 'pane switch echoes the ghost-button precedent');
      expect(
          src.contains('HapticFeedback.lightImpact(); '
              '// elevation item 5: success feedback'),
          isTrue,
          reason: 'copy SUCCESS feedback sits with the clipboard write');
      expect(
          RegExp(r'HapticFeedback\.lightImpact\(\);\s*ref\s*'
                  r'\.read\(hadithBookmarksProvider')
              .allMatches(src)
              .length,
          2,
          reason: 'detail-sheet + tile bookmark — parity with the '
              'book-screen buttons that already fired');
      expect(RegExp(r'HapticFeedback\.lightImpact').allMatches(src).length,
          greaterThanOrEqualTo(4));
    });

    test('reader sheet: prev/next taps + both share-success paths', () {
      final src = File(_book).readAsStringSync();
      expect(
          RegExp(r'HapticFeedback\.lightImpact\(\);\s*openNeighbour')
              .allMatches(src)
              .length,
          2,
          reason: 'prev + next; the DISABLED end-of-corpus state must '
              'stay silent (null-able, no callback to fire)');
      expect(
          RegExp(r'Clipboard\.setData\(ClipboardData\(text: \w+\)\);\s*'
                  r'HapticFeedback\.lightImpact\(\)')
              .allMatches(src)
              .length,
          2,
          reason: 'sheet "Copy to share" + card share — feedback on '
              'success (clipboard issued), not on tap');
    });
  });

  group('a11y mini-pass + constraint sweep (item 6)', () {
    test('no icon-only IconButton in either hadith surface lacks a tooltip',
        () {
      for (final path in [_screen, _book]) {
        final src = stripCommentsForGuard(File(path).readAsStringSync());
        for (final m in RegExp(r'(?<![A-Za-z_])IconButton\(').allMatches(src)) {
          final end = m.start + 420 > src.length ? src.length : m.start + 420;
          final win = src.substring(m.start, end);
          expect(win.contains('tooltip:'), isTrue,
              reason: 'bare IconButton at offset ${m.start} in $path — '
                  'every icon-only control carries a label (elevation '
                  'a11y pass cleared 5; this pins them forever)');
        }
      }
    });

    test('search-highlight wiring survives (world-class pass owns it)', () {
      final src = File(_screen).readAsStringSync();
      expect(src.contains('highlightQuery: query.trim()'), isTrue,
          reason: 'the sheet still passes the live query to the tiles');
      expect(src.contains('SearchNormalizer.allMatches(text, query)'), isTrue,
          reason: 'fold-aware, original-coordinate matching — the truth of '
              'the emphasis comes from the SAME machinery as Quran search');
      expect(src.contains('List<TextSpan> hadithHighlightSpans('), isTrue);
    });

    test('no raw hex, no new paint layers on the elevated surfaces', () {
      for (final path in [_screen, _book]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('Color(0x'), isFalse,
            reason: 'navy tokens are single-source — the pass reuses '
                'colors.primary/textTertiary/etc, mints nothing');
        expect(src.contains('ColorFiltered'), isFalse);
      }
      expect(File(_screen).readAsStringSync().contains('Opacity('), isFalse,
          reason: 'redesign perf pin kept honest across the additions');
    });
  });
}
