// test/hadith_world_class_pass_test.dart
// ============================================================
// QIBRA AI — WORLD-CLASS HADITH PASS (2026-09-04) UNIT TESTS
// ============================================================
// Pure-logic pins for the five items: the split reading scales, the
// persisted recent-search semantics, the bookmarks-manager dedupe,
// today's-hadith determinism (the selection was ALREADY stable — these
// tests pin it per the owner's "if already stable, pin it" rule), the
// resume derivation from the real HadithViewHistory LRU, and the
// search-highlight span builder's original-coordinate contract.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_view_history.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart'
    show hadithHighlightSpans;
import 'package:qibra_ai/features/hadith/providers/hadith_preferences_provider.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('split reading scales (item 1)', () {
    test('defaults are 1.0/1.0 — nothing is pre-scaled', () {
      const prefs = HadithReadingPreferences();
      expect(prefs.arabicScale, 1.0);
      expect(prefs.translationScale, 1.0);
    });

    test('clamp matches the Quran split-scale range 0.8–1.6', () {
      // No legacy single-scale key ever existed for hadith (text sizes
      // were hardcoded before this pass), so the only migration rule
      // is: whatever a foreign store holds lands inside the clamped
      // range on load.
      expect(HadithReadingPreferences.clampScale(0.5), 0.8);
      expect(HadithReadingPreferences.clampScale(3.0), 1.6);
      expect(HadithReadingPreferences.clampScale(0.8), 0.8);
      expect(HadithReadingPreferences.clampScale(1.6), 1.6);
      expect(HadithReadingPreferences.clampScale(1.35), 1.35);
    });
  });

  group('recent searches (item 2)', () {
    test('trim, dedupe-to-front, cap 10, blank no-op', () {
      var list = const <String>[];
      list = HadithRecentSearchesNotifier.applyRecent(list, '  patience  ');
      expect(list, ['patience']);
      list = HadithRecentSearchesNotifier.applyRecent(list, 'patience');
      expect(list, ['patience']); // dedupe keeps exactly one
      list = HadithRecentSearchesNotifier.applyRecent(list, 'prayer');
      expect(list, ['prayer', 'patience']); // newest first
      for (var n = 0; n < 12; n++) {
        list = HadithRecentSearchesNotifier.applyRecent(list, 'q$n');
      }
      expect(list.length, HadithRecentSearchesNotifier.cap);
      expect(list.first, 'q11');

      final same =
          HadithRecentSearchesNotifier.applyRecent(list, '   ');
      expect(same, list); // blank queries never enter the list
    });

    test('the store is hadith-owned: separate key from the Quran pass', () {
      final hadithProvider =
          File('lib/features/hadith/providers/hadith_provider.dart')
              .readAsStringSync();
      final quranSearch =
          File('lib/features/quran/presentation/quran_search_screen.dart')
              .readAsStringSync();
      expect(
          hadithProvider.contains("'hadith_recent_searches_v1'"), isTrue);
      expect(hadithProvider.contains("'quran_recent_searches_v1'"), isFalse,
          reason: 'one key per surface — recents never cross-contaminate');
      expect(
          quranSearch.contains("'quran_recent_searches_v1'"), isTrue);
    });
  });

  group('bookmarks manager dedupe (item 5)', () {
    HadithBookmark bm(String bookmarkId, String hadithId) => HadithBookmark(
          id: bookmarkId,
          hadithId: hadithId,
          bookSlug: 'bukhari',
          bookName: 'Sahih al-Bukhari',
          hadithNumber: 1,
          chapterName: '',
          textPreview: 'preview',
          createdAt: DateTime(2026, 9, 4),
        );

    test('same hadith id never double-adds; new ids append', () {
      final one =
          HadithBookmarksNotifier.addIfAbsent(const [], bm('bm_1', 'h1'));
      expect(one.length, 1);
      final two = HadithBookmarksNotifier.addIfAbsent(one, bm('bm_2', 'h2'));
      expect(two.length, 2);
      expect(two.last.hadithId, 'h2');
      // Different bookmark id, SAME hadith id — the dedupe key is the
      // hadith, and the unchanged-list contract lets addBookmark skip
      // the pointless persist.
      final same =
          HadithBookmarksNotifier.addIfAbsent(two, bm('bm_9', 'h2'));
      expect(identical(same, two), isTrue);
    });
  });

  group("today's hadith determinism (item 4)", () {
    test('same date, same index — stable across opens and restarts', () {
      const pool = 7455;
      final a = HadithDatabaseService.todayIndexFor(
          DateTime(2026, 9, 4, 8, 0), pool);
      final b = HadithDatabaseService.todayIndexFor(
          DateTime(2026, 9, 4, 22, 30), pool);
      expect(a, b, reason: 'hour of day must not move the pick');
      expect(
          a, DateTime(2026, 9, 4).difference(DateTime(2026, 1, 1)).inDays % pool);
    });

    test('new year resets to the pool head; consecutive days advance by 1',
        () {
      expect(HadithDatabaseService.todayIndexFor(DateTime(2026, 1, 1), 100),
          0);
      final d1 =
          HadithDatabaseService.todayIndexFor(DateTime(2026, 5, 10), 100);
      final d2 =
          HadithDatabaseService.todayIndexFor(DateTime(2026, 5, 11), 100);
      expect((d1 + 1) % 100, d2);
      // Any date, any pool size, stays inside [0, pool) — mod math by
      // construction, pinned so a future refactor cannot drift it.
      const pool = 7455;
      final late2027 =
          HadithDatabaseService.todayIndexFor(DateTime(2027, 12, 31), pool);
      expect(late2027, inInclusiveRange(0, pool - 1));
    });
  });

  group('book resume from the real view-history LRU (item 3)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('the first entry matching the slug IS the continue position',
        () async {
      await HadithViewHistory.record('bukhari', 3);
      await HadithViewHistory.record('muslim', 7);
      await HadithViewHistory.record('bukhari', 4);
      final entries = await HadithViewHistory.entries();

      ({String bookSlug, int hadithNumber})? resumeFor(String slug) {
        for (final raw in entries) {
          final parsed = HadithViewHistory.parseRef(raw);
          if (parsed != null && parsed.bookSlug == slug) return parsed;
        }
        return null;
      }

      expect(resumeFor('bukhari'),
          (bookSlug: 'bukhari', hadithNumber: 4)); // newest per book
      expect(resumeFor('muslim'),
          (bookSlug: 'muslim', hadithNumber: 7));
      expect(resumeFor('nasai'), isNull,
          reason: 'no real position -> no Continue chip, ever');
    });

    test('Continue reflects detail opens, never scrolling — the record '
        'seam is the single writer', () {
      // The book screen derives from HadithViewHistory.entries(), which
      // only changes through record()/clear(). Pin that no scroll
      // listener feeds the store from the UI.
      final book =
          File('lib/features/hadith/presentation/hadith_book_screen.dart')
              .readAsStringSync();
      expect(book.contains('HadithViewHistory.record('), isFalse,
          reason: 'the screen must not write the LRU directly — the '
              'recordHadithView seam is the single writer');
      expect(book.contains('recordHadithView(ref, hadith)'), isTrue);
      expect(book.contains('.addListener('), isFalse,
          reason: 'resume is last-opened-detail, not last-scrolled — no '
              'scroll listener may touch persistence in this screen');
    });
  });

  group('search-highlight span builder (item 2)', () {
    const base = TextStyle(fontSize: 12);
    const accent = Color(0xFF010203);

    test('no folded match -> ONE verbatim span, nothing emphasized', () {
      const text = 'Actions are but by intentions';
      final spans = hadithHighlightSpans(text, 'zzz-nothing', base, accent);
      expect(spans.length, 1);
      expect(spans.single.text, text);
      expect(spans.single.style, base);
    });

    test('latin: match keeps ORIGINAL case; spans partition the text', () {
      const text = 'Patience is half of faith';
      final spans = hadithHighlightSpans(text, 'patience', base, accent);
      expect(spans.map((sp) => sp.text).join(), text,
          reason: 'a partition — emphasis never rewrites or reorders');
      final hit =
          spans.firstWhere((sp) => sp.style?.fontWeight == FontWeight.w800);
      expect(hit.text, 'Patience',
          reason: 'query was lowercase; the corpus casing is untouched');
    });

    test('Arabic: diacritic-folded query highlights verbatim diacritized '
        'originals at original coordinates', () {
      const text = 'الصَّبْرُ ضِيَاءٌ';
      final m = SearchNormalizer.allMatches(text, 'الصبر');
      expect(m, isNotEmpty,
          reason: 'the folded query must match the diacritized corpus');
      final spans = hadithHighlightSpans(text, 'الصبر', base, accent);
      expect(spans.map((sp) => sp.text).join(), text);
      final hit =
          spans.firstWhere((sp) => sp.style?.fontWeight == FontWeight.w800);
      // The original slice at those coordinates keeps its diacritics —
      // the fold is for matching only, never for display.
      const fathah = '\u064E'; // َ
      expect(hit.text.contains(fathah), isTrue);
      expect(text.contains(hit.text), isTrue);
    });
  });
}
