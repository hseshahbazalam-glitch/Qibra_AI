// test/perf_pass_test.dart
// ============================================================
// QIBRA AI — PERFORMANCE & RENDERING PASS PINS (owner 2026-09-05)
// "laggy + dead-pixel-like glitches" — every item of the owner's
// deep-audit gets an executable guard here, so a future refactor cannot
// silently re-block the first frame, re-materialize the saveLayer, or
// drop the isolate decode. Where an item was an AUDIT with a "no change
// needed" finding, the pin freezes the audited GOOD state.
// ============================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

import 'support/source_guards.dart';

void main() {
  group('item 1 — hadith boot decodes OFF the UI isolate', () {
    test('decodeHadithAsset is the pure isolate body (fixture, no spawns)',
        () {
      const raw = '{"hadiths":['
          '{"hadithnumber":402,"arabicnumber":402,"text":"parent"},'
          '{"hadithnumber":"402.2","arabicnumber":8,"text":"citation"}],'
          '"metadata":{"name":"x"}}';
      final data = HadithDatabaseService.decodeHadithAsset(raw);
      expect(data, isNotNull);
      final hadiths = data!['hadiths'] as List<dynamic>;
      expect(hadiths.length, 2);
      // The base loader also consumes metadata — shape preserved.
      expect((data['metadata'] as Map)['name'], 'x');
      // Never throws across the isolate boundary: malformed or wrong
      // top-level types degrade to null, exactly like the old main-thread
      // try/catch did.
      expect(HadithDatabaseService.decodeHadithAsset('['), isNull);
      expect(HadithDatabaseService.decodeHadithAsset('[1,2]'), isNull);
      // Decoding feeds the SAME pinned pairTextIndex join semantics.
      final idx = HadithDatabaseService.pairTextIndex(hadiths);
      expect(idx['402|402'], 'parent');
      expect(idx['402.2|8'], 'citation',
          reason: 'fractional keys survive decode+join untouched (Rev. 2)');
    });

    test('the service holds exactly ONE jsonDecode — inside the pure entry',
        () {
      final src = File(
              'lib/features/hadith/data/services/hadith_database_service.dart')
          .readAsStringSync();
      final code = stripCommentsForGuard(src);
      expect(RegExp(r'jsonDecode').allMatches(code).length, 1,
          reason: 'any second main-thread decode re-introduces the lag '
              'this pass removed');
      final pure = RegExp(
              r'static Map<String, dynamic>\? decodeHadithAsset[\s\S]*?\n  \}')
          .firstMatch(code)!;
      expect(RegExp(r'jsonDecode').hasMatch(pure.group(0)!), isTrue,
          reason: 'the only jsonDecode lives in the pure static that only '
              'ever runs inside Isolate.run closures');
      expect(src.contains("import 'dart:isolate';"), isTrue); // G12 pair
      expect(src.contains('Isolate.run('), isTrue);
      // The per-book batch shape (one Future.wait over base+languages) is
      // what the owner's suggested design keeps.
      expect(src.contains('Future.wait<Object?>(['), isTrue);
    });

    test('boot measurement + aggregate timing log stay wired', () {
      final src = File(
              'lib/features/hadith/data/services/hadith_database_service.dart')
          .readAsStringSync();
      expect(src.contains('static bool debugLogLoadTiming = !kReleaseMode;'),
          isTrue,
          reason: 'per-file decode stopwatches ride the debug flag');
      expect(src.contains('[HADITH_DB] Initialized in'), isTrue,
          reason: 'the phase-progression line main() printed stays intact');
    });
  });

  group('item 2 — runApp-first boot order', () {
    test('main() awaits NO data before runApp', () {
      final src = File('lib/main.dart').readAsStringSync();
      final runAppAt = src.indexOf('runApp(');
      expect(runAppAt, greaterThan(0));
      final before = src.substring(0, runAppAt);
      expect(before.contains('.initialize()'), isFalse,
          reason: 'the Quran + notification await blocks must live in the '
              'bootstrap provider, not ahead of the first frame');
      expect(before.contains('quranRepo'), isFalse);
      expect(src.contains('tz_data.initializeTimeZones()'), isTrue,
          reason: 'timezone table registration STAYS pre-runApp by design '
              '(synchronous, in-memory; prayer math needs it from its own '
              'first frame — documented at the call site)');
    });

    test('the bootstrap provider owns the heavy init; splash shows real state',
        () {
      final boot =
          File('lib/core/providers/app_providers.dart').readAsStringSync();
      expect(boot.contains('dataBootstrapProvider'), isTrue);
      expect(boot.contains('QuranRepository().initialize()'), isTrue);
      expect(boot.contains('NotificationService().initialize()'), isTrue);
      final splash = File(
              'lib/features/splash/presentation/splash_screen.dart')
          .readAsStringSync();
      expect(splash.contains('ref.watch(dataBootstrapProvider)'), isTrue,
          reason: 'the splash STARTS the bootstrap and mirrors its real '
              'loading→ready state — never a decorative spinner');
      expect(splash.contains('_buildBootStatus('), isTrue);
      expect(splash.contains('boot.isLoading'), isTrue,
          reason: 'navigation waits on genuine readiness when the timeline '
              'finishes first (no fixed-length lie)');
    });
  });

  group('item 3 — PatternBackdrop: saveLayer gone, wash baked in', () {
    test('no fade wrapper, no ColorFiltered; baked asset + cacheWidth', () {
      // CODE-ONLY: the header comment legitimately NAMES the removed APIs.
      final raw = File('lib/shared/widgets/media/pattern_backdrop.dart')
          .readAsStringSync();
      final src = stripCommentsForGuard(raw);
      expect(src.contains('Opacity('), isFalse,
          reason: 'the full-screen widget-level fade was the per-frame '
              'saveLayer (artifact + jank source on Impeller/Vulkan)');
      expect(src.contains('ColorFiltered'), isFalse);
      expect(src.contains('AppAssets.patternTileFaded'), isTrue);
      expect(src.contains('cacheWidth: 256'), isTrue);
      // The note lives in the header comment BY DESIGN — it is pinned
      // against the RAW source (the stripped src above stays the
      // authority for the API-absence checks; nothing weakened).
      expect(raw.contains('ARTIFACT NOTE'), isTrue,
          reason: 'the why travels with the file');
    });

    test('the faded tile exists and carries the baked wash', () {
      final f = File('assets/images/hero/pattern_tile_faded.png');
      expect(f.existsSync(), isTrue,
          reason: 'regenerate via scripts/make_faded_tile.py if missing');
      final bytes = f.readAsBytesSync();
      expect(bytes.sublist(0, 8),
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      // 256x256 per IHDR.
      final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      expect(w, 256);
      expect(h, 256);
      expect(bytes.lengthInBytes, lessThan(120000),
          reason: 'the point was a SMALLER committed artifact than the '
              '218 KB source — flag if a regen balloons it');
    });
  });

  group('items 4+5 — lazy hot lists + decode budgets (audits frozen)', () {
    test('hot lists are lazy AND the Continue anchor survives', () {
      final surah = File(
              'lib/features/quran/presentation/surah_list_screen.dart')
          .readAsStringSync();
      expect(surah.contains('SliverList.separated('), isTrue,
          reason: 'the 114-surah list builds on demand — audit found the '
              'plain ListView(children:) only in fixed skeletons');
      final book = File(
              'lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      expect(book.contains('SliverChildBuilderDelegate('), isTrue);
      expect(book.contains('KeyedSubtree(key: _resumeKey, child: card)'),
          isTrue,
          reason: 'the Continue ensureVisible anchor must survive any '
              'future list conversion');
      expect(book.contains('_resumeKey.currentContext'), isTrue);
    });

    test('every non-fullscreen SafeImage site carries a decode budget', () {
      const sites = {
        'lib/features/ai/presentation/ai_explain_screen.dart':
            'cacheWidth: 300',
        // Hadith redesign (reference pass): the tab's art band moved onto
        // QibraHeroCard — the dpr-aware hero entry at the bottom of this
        // map — so the screen owns no raw SafeImage and no fixed hint.
        // Its former 'cacheWidth: 512' tile strip is gone BY DESIGN.
        'lib/features/onboarding/presentation/onboarding_screen.dart':
            'cacheWidth: 450',
        'lib/features/settings/presentation/user_profile_screen.dart':
            'cacheWidth: 300',
        'lib/features/splash/presentation/splash_screen.dart':
            'cacheWidth: 288',
        // The generic hero card is dpr-aware (item 5), not a fixed hint.
        'lib/shared/widgets/qibra_ui.dart': 'devicePixelRatioOf(context)',
      };
      sites.forEach((path, needle) {
        expect(File(path).readAsStringSync().contains(needle), isTrue,
            reason: 'decode budget missing from $path');
      });
      // splashBackground renders FULL-screen: exempt by the rule itself
      // (cacheWidth only helps sub-native display sizes — pinned as a
      // decision, not an oversight).
      final ui = File('lib/shared/widgets/qibra_ui.dart').readAsStringSync();
      expect(ui.contains('.clamp(320, 1536)'), isTrue,
          reason: 'the hero hint must stay clamped (never upscales decode)');
    });
  });
}
