import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_guards.dart';

/// Device ANR + debug-flood guards (owner 2026-09-02). Source-level pins —
/// the ANR class and the ListTile/Chip assertion spam must not come back
/// through refactors, and they can only be judged by the runtime battery on
/// a real device. These guards make the intent executable here.
void main() {
  group('no main-thread retrieval storm on chat send', () {
    test('retrieval runs ONCE per message', () {
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('RagService.instance.retrieve('), isTrue);
      // Code-only scan: ai_provider legitimately MENTIONS the old
      // buildContextForQuery in the ANR post-mortem comment (:131-132);
      // the pin must judge CODE, not prose (Rev. 3 — shared stripper from
      // backend_ai_wiring's class D fix).
      expect(stripCommentsForGuard(provider).contains('buildContextForQuery'),
          isFalse,
          reason: 'context must be formatted from the same passages, not '
              'retrieved a second time');
      expect(provider.contains('RagService.contextFrom(_lastRetrieved)'), isTrue);
    });

    test('bridge batches into ONE off-main scan per data source', () {
      final rag =
          File('lib/features/ai/services/rag_service.dart').readAsStringSync();
      expect(rag.contains('searchBatchOffMain(terms, perQuery: topK)'), isTrue);
      expect(rag.contains('searchBatchOffMain(terms, maxPerQuery: topK)'), isTrue);
      expect(rag.contains('_retrieveOnce'), isFalse,
          reason: 'the per-term synchronous fan-out was the ANR');
    });

    test('both repos provide isolate batch scans', () {
      final quran = File('lib/features/quran/data/repository/quran_repository.dart')
          .readAsStringSync();
      final hadith =
          File('lib/features/hadith/data/services/hadith_database_service.dart')
              .readAsStringSync();
      expect(quran.contains('Future<List<List<SearchResultModel>>> searchBatchOffMain'),
          isTrue);
      expect(quran.contains('return Isolate.run(() {'), isTrue);
      expect(hadith.contains('Future<List<List<LocalSearchResult>>> searchBatchOffMain'),
          isTrue);
      expect(hadith.contains('double hadithRelevanceFor('), isTrue,
          reason: 'top-level so the isolate closure can capture it');
    });
  });

  group('hard 90s ask ceiling (Render cold start)', () {
    test('single timeout constant, applied to both stream and non-stream', () {
      final constants =
          File('lib/core/constants/app_constants.dart').readAsStringSync();
      expect(
        constants.contains('static const Duration aiAskTimeout = Duration(seconds: 90);'),
        isTrue,
      );
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('receiveTimeout: AppApi.aiAskTimeout'), isTrue);
      expect(provider.contains("extra: const {'noRetry': true},"), isTrue);
      expect(provider.contains("options: Options(extra: const {'noRetry': true}),"), isTrue);
      expect(provider.contains('.timeout(AppApi.aiAskTimeout)'), isTrue);
      expect(provider.contains('Duration(seconds: 120)'), isFalse);
    });

    test('a timeout is final — no second 90s retry stacked behind it', () {
      final client = File('lib/core/network/api_client.dart').readAsStringSync();
      expect(
        client.contains("if (e.requestOptions.extra['noRetry'] == true) return false;"),
        isTrue,
        reason: 'AI ask opts out of the 3x retry ladder — one attempt, '
            'hard 90s (retry stack would reach ~370s on a cold tier)',
      );
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('final isTimeout = e is TimeoutException ||'), isTrue);
      expect(provider.contains('DioExceptionType.receiveTimeout'), isTrue);
      expect(provider.contains('slow to respond (it may be starting up'), isTrue,
          reason: 'graceful server-slow message, per owner spec');
    });

    test('typewriter repaints are throttled, parser yields per chunk', () {
      final provider =
          File('lib/features/ai/providers/ai_provider.dart').readAsStringSync();
      expect(provider.contains('paintClock.elapsedMilliseconds >= 60'), isTrue);
      expect(provider.contains('await Future<void>.value();'), isTrue);
    });
  });

  group('ListTile/Chip ink — no decoration-above-ink patterns', () {
    test('QibraCard gives its tiles a Material ancestor even untappable', () {
      final ui = File('lib/shared/widgets/qibra_ui.dart').readAsStringSync();
      expect(ui.contains('if (onTap == null) return card;'), isFalse);
      expect('MaterialType.transparency'.allMatches(ui).length >= 1, isTrue);
    });

    test('QibraChip is a plain Material pill — no ChoiceChip-internal tile', () {
      final ui = File('lib/shared/widgets/qibra_ui.dart').readAsStringSync();
      expect(ui.contains('ChoiceChip('), isFalse);
      expect(ui.contains('child: InkWell('), isTrue);
    });

    test('the prayer-row decorated card wraps its tile in Material', () {
      final row =
          File('lib/features/prayer/presentation/prayer_times_screen.dart')
              .readAsStringSync();
      // Whitespace-tolerant (Rev. 3): the exact multiline string was brittle
      // to re-indentation; the pattern itself lives at
      // prayer_times_screen:809-811.
      expect(
        RegExp(
                r'Material\(\s*type:\s*MaterialType\.transparency,\s*child:\s*ListTile\(')
            .hasMatch(row),
        isTrue,
      );
    });

    test('no new bare Container(decoration)+ListTile without Material', () {
      // Repo-wide sweep mirroring the fix mandate: any Container whose
      // decoration wraps a ListTile must mention Material in between.
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        for (final m in RegExp(r'Container\(\s*\n\s*decoration: BoxDecoration')
            .allMatches(src)) {
          final tail = src.substring(m.end, m.end + 400);
          if (tail.contains('ListTile(') && !tail.contains('Material')) {
            fail('${f.path}@${src.substring(0, m.start).split('\n').length}: '
                'decorated Container wrapping a bare ListTile');
          }
        }
      }
    });
  });

  group('voice input hidden until Level 3', () {
    test('the mic gate switch is false and every affordance is behind it', () {
      final screen = File('lib/features/ai/presentation/ai_explain_screen.dart')
          .readAsStringSync();
      expect(
        screen.contains('static final bool _voiceInputEnabled = false;'),
        isTrue,
      );
      expect(screen.contains("'Tap mic to speak'"), isFalse);
      expect(screen.contains('Type or tap mic to speak'), isFalse);
    });

    test('RECORD_AUDIO is deliberately NOT in the manifest yet', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('RECORD_AUDIO'), isFalse,
          reason: 'owner 2026-09-02: add it WITH voice wiring, not before');
    });
  });
}
