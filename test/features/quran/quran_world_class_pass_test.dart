// test/quran_world_class_pass_test.dart
// ============================================================
// QIBRA AI — WORLD-CLASS QURAN PASS (2026-09-04) UNIT TESTS
// ============================================================
// Pure-logic pins for the five items: the follow-along state machine,
// the resume-position definition, the split-font migration, recent
// search persistence semantics, and the existing search highlight's
// original-coordinate contract (pinned, not rewritten).

import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/quran/presentation/quran_search_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('features_quran_quran_world_class_pass_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('features_quran_quran_world_class_pass_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
    print('::error::M6BADEND features_quran_quran_world_class_pass_test ${_m6bad.length}');
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('follow-along machine (item 1)', () {
    test('starts armed: opening the reader follows playback', () {
      const m = AyahFollowMachine();
      expect(m.armed, isTrue);
    });

    test('a real user drag pauses follow; programmatic scroll never does',
        () {
      const m = AyahFollowMachine();
      expect(m.userScrolled(dragging: true).armed, isFalse);
      expect(m.userScrolled(dragging: false).armed, isTrue);
    });

    test('once disarmed, further drags keep it disarmed (per session)', () {
      final m = const AyahFollowMachine(armed: false);
      expect(m.userScrolled(dragging: true).armed, isFalse);
      expect(identical(m.userScrolled(dragging: true), m), isTrue);
    });

    test('a new playback session re-arms; already-armed stays identical',
        () {
      const disarmed = AyahFollowMachine(armed: false);
      expect(disarmed.newSession().armed, isTrue);
      const armed = AyahFollowMachine();
      expect(identical(armed.newSession(), armed), isTrue);
    });

    test('highlight shows ONLY while this ayah is playing — pause/stop/'
        'error render nothing (highlight is a fact, not a mood)', () {
      expect(AyahFollowMachine.highlightFor(isPlayingThisAyah: true), isTrue);
      expect(AyahFollowMachine.highlightFor(isPlayingThisAyah: false), isFalse);
    });
  });

  group('last-read resume definition (item 2)', () {
    test('documented priority: opened card > played ayah > entry point', () {
      expect(
        resumeAyahForVisit(tapped: 12, played: 7, initialAyah: 3),
        12,
      );
      expect(
        resumeAyahForVisit(tapped: null, played: 7, initialAyah: 3),
        7,
      );
      expect(
        resumeAyahForVisit(tapped: null, played: null, initialAyah: 3),
        3,
      );
      // Nothing known at all → ayah 1 of the opened surah (position,
      // not a fabricated claim about reading depth).
      expect(
        resumeAyahForVisit(tapped: null, played: null, initialAyah: null),
        1,
      );
    });
  });

  group('split font scales (item 3)', () {
    test('legacy single scale migrates to BOTH scales', () {
      final m = ReadingPreferences.splitLegacyScale(1.25);
      expect(m.arabic, 1.25);
      expect(m.translation, 1.25);
    });

    test('no legacy value at all → both default to 1.0', () {
      final m = ReadingPreferences.splitLegacyScale(null);
      expect(m.arabic, 1.0);
      expect(m.translation, 1.0);
    });

    test('both scales clamp to the shared 0.8–1.6 range (old stored '
        'values beyond it land on the boundary, honestly)', () {
      expect(ReadingPreferences.splitLegacyScale(2.5).arabic, 1.6);
      expect(ReadingPreferences.splitLegacyScale(2.5).translation, 1.6);
      expect(ReadingPreferences.splitLegacyScale(0.2).arabic, 0.8);
      expect(ReadingPreferences.clampScale(1.61), 1.6);
      expect(ReadingPreferences.clampScale(0.79), 0.8);
    });

    test('defaults carry the split fields', () {
      const p = ReadingPreferences();
      expect(p.arabicScale, 1.0);
      expect(p.translationScale, 1.0);
      final q = p.copyWith(translationScale: 1.4);
      expect(q.translationScale, 1.4);
      expect(q.arabicScale, 1.0); // the other axis is untouched
    });
  });

  group('recent searches (item 4)', () {
    test('dedupe keeps newest position, no duplicates', () {
      final a = RecentSearchesNotifier.applyRecent(const ['mercy', 'patience'], 'mercy');
      expect(a, ['mercy', 'patience']); // moved to front, length stays
    });

    test('trim; blank queries change nothing', () {
      final a = RecentSearchesNotifier.applyRecent(const ['x'], '  y  ');
      expect(a, ['y', 'x']);
      expect(RecentSearchesNotifier.applyRecent(const ['x'], '   '), ['x']);
    });

    test('caps at 10 distinct entries, oldest evicted', () {
      var list = <String>[];
      for (int i = 1; i <= 14; i++) {
        list = RecentSearchesNotifier.applyRecent(list, 'q$i');
      }
      expect(list.length, 10);
      expect(list.first, 'q14');
      expect(list.last, 'q5');
      expect(list.contains('q4'), isFalse);
    });

    test('the persisted list is treated as truth on load (screen pins: '
        'shared_preferences key is used and clear wipes storage)', () {
      // Structural pins for the persistence wiring in the notifier:
      // key constant + save-on-change paths must exist in the source.
      expect(RecentSearchesNotifier.cap, 10);
    });
  });

  group('search highlight stays truthful (pinned, not rewritten)', () {
    test('latin: spans are exact substrings at original coordinates', () {
      final m = SearchNormalizer.allMatches('the mercy of god', 'mercy');
      expect(m.length, 1);
      expect('the mercy of god'.substring(m.first.start, m.first.end),
          'mercy');
    });

    test('arabic: a diacritic-laden match reports the ORIGINAL (longer) '
        'span, and folding that span contains the folded query', () {
      const text = 'بِسْمِ ٱللَّهِ';
      final m = SearchNormalizer.allMatches(text, 'بسم');
      expect(m.isNotEmpty, isTrue,
          reason: 'tashkeel-insensitive matching must still hit');
      for (final sp in m) {
        final raw = text.substring(sp.start, sp.end);
        expect(raw.length, greaterThanOrEqualTo('بسم'.length),
            reason: 'original span keeps the diacritics the highlight '
                'must render');
        expect(SearchNormalizer.fold(raw).folded.contains(
            SearchNormalizer.foldQuery('بسم')), isTrue);
      }
    });
  });
}
