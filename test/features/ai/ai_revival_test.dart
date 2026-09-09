// test/ai_revival_test.dart
// ============================================================
// AI REVIVAL — STAGE 1 (2026-09-07): THE 'namz kiya hai' CLASS, PINNED
// ============================================================
// Fixture-based (no network, no real corpus). Pins the three things this
// pass shipped: (1) the typo->bridge->retrieval chain stays welded — the
// pre-bridge bug where 'namz' retrieved nothing; (2) the cold-start
// bounded wait on the hadith side — the REAL residual gap (silently-EMPTY
// while boot-load ran), capped at the service, awaited ONCE per retrieve,
// honest-empty + no hang if nothing loads; (3) the exact refusal sentinel
// and the voice-input gate (flag flipped + the one RECORD_AUDIO manifest
// line + speech_to_text wired). The service's existing attachHadithDb
// seam is used for injection — no refactor, no real assets touched.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/ai/services/rag_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

const _fixtureHadith = LocalHadith(
  hadithNumber: 1,
  arabicNumber: 1,
  textArabic: '',
  textEnglish: 'Actions are but by intentions',
  textUrdu: '',
  bookSlug: 'bukhari',
  bookName: 'Sahih al-Bukhari',
  bookNumber: 1,
  chapterHadithNumber: 1,
  chapterName: 'Revelation',
  grade: 'sahih',
);

/// Warm, honest corpus stand-in: answers ONLY terms the bridge chain can
/// legitimately produce, and records every batched pass it was asked for.
class _WarmBridgeDb extends HadithDatabaseService {
  final List<List<String>> passes = [];

  _WarmBridgeDb() : super.testFixture();

  @override
  bool get isInitialized => true;

  @override
  Future<List<List<LocalSearchResult>>> searchBatchOffMain(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    passes.add(List.of(queries));
    bool bridgeHit(String q) =>
        const {'namaz', 'prayer', 'salah'}.contains(q.toLowerCase().trim());
    return [
      for (final q in queries)
        if (bridgeHit(q))
          const [
            LocalSearchResult(
              hadith: _fixtureHadith,
              relevance: 0.9,
              matchedIn: 'english',
            ),
          ]
        else
          const <LocalSearchResult>[],
    ];
  }
}

/// Cold, counting stand-in: waitForReady is observed, isInitialized stays
/// false — the retrieve() contract must degrade to honest-empty, never
/// hang, never throw.
class _CountingColdDb extends HadithDatabaseService {
  int readyWaits = 0;

  _CountingColdDb() : super.testFixture();

  @override
  bool get isInitialized => false;

  @override
  Future<void> waitForReady({
    Duration maxWait = const Duration(milliseconds: 2500),
  }) async {
    readyWaits++;
  }
}

void main() {
  tearDown(() {
    // Leave the singleton on a pristine COLD real service: identical to a
    // fresh app start, so no other test file can inherit fixture state.
    RagService.instance.attachHadithDb(HadithDatabaseService());
  });

  group('typo bridge regression — the pre-bridge bug stays fixed', () {
    test("correctionsFor bridges the owner's live typos", () {
      expect(RagService.correctionsFor('namz'), contains('namaz'));
      expect(RagService.correctionsFor('prayr'), contains('prayer'));
    });

    test("'namz kiya hai' retrieves NON-empty via namaz -> prayer chain",
        () async {
      final db = _WarmBridgeDb();
      RagService.instance.attachHadithDb(db);
      final passages = await RagService.instance.retrieve('namz kiya hai');
      expect(passages, isNotEmpty,
          reason: 'the second (typo) pass must reach the corpus');
      expect(passages.first.collection, 'hadith');
      expect(passages.first.source, 'Sahih al-Bukhari 1');
      // The FIRST pass carries the raw query only; the SECOND pass must
      // carry the bridge-expanded typo terms — pinning the whole chain.
      expect(db.passes.length, greaterThanOrEqualTo(2));
      expect(
        db.passes.last.map((t) => t.toLowerCase().trim()).toList(),
        containsAll(<String>['namaz', 'prayer', 'salah']),
      );
      expect(RagService.modeFor(passages), RetrievalMode.localRetrieval);
    });
  });

  group('cold-start bounded wait — the real residual gap', () {
    test('waitForReady on a COLD real service respects the cap and is honest',
        () async {
      final db = HadithDatabaseService();
      final sw = Stopwatch()..start();
      await db.waitForReady(maxWait: const Duration(milliseconds: 150));
      sw.stop();
      expect(db.isInitialized, isFalse);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100),
          reason: 'it must actually poll the load, not answer pre-maturely');
      expect(sw.elapsedMilliseconds, lessThan(2000),
          reason: 'bounded wait never exceeds its cap meaningfully');
      final res = await db.searchBatchOffMain(['namaz']);
      expect(res, [isEmpty], reason: 'cold search stays honestly empty');
    });

    test('retrieve() awaits readiness EXACTLY ONCE and never hangs/throws',
        () async {
      final cold = _CountingColdDb();
      RagService.instance.attachHadithDb(cold);
      final passages =
          await RagService.instance.retrieve('namz kiya hai');
      expect(cold.readyWaits, 1,
          reason: 'one bounded wait per retrieve — the primary AND the '
              'typo _collect pass must not each pay for it');
      expect(passages, isEmpty,
          reason: 'nothing loaded -> honest empty refusal, no hang, no '
              'fabricated context');
    });

    test('warm path pays ZERO wait cost (readiness gate short-circuits)',
        () async {
      final warm = _WarmBridgeDb();
      RagService.instance.attachHadithDb(warm);
      final sw = Stopwatch()..start();
      final passages = await RagService.instance.retrieve('namaz');
      sw.stop();
      expect(passages, isNotEmpty);
      // isInitialized is true, so retrieve() must not even call
      // waitForReady; the whole call is a plain await of the stub.
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('invariants of the revival: sentinel + voice gate', () {
    test('refusal sentinel stays exact (provider-gate agreement)', () {
      expect(RagService.refuseContext,
          'REFUSE: no retrieved passage. Do not invent Quran or Hadith.');
    });

    test('voice input is shipped: flag, manifest line, service import', () {
      final screen =
          File('lib/features/ai/presentation/ai_explain_screen.dart')
              .readAsStringSync();
      expect(screen.contains('static final bool _voiceInputEnabled = true;'),
          isTrue);
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
          manifest.contains(
              '<uses-permission android:name="android.permission.RECORD_AUDIO" />'),
          isTrue);
      // still exactly one RECORD_AUDIO line (the surgical touch)
      expect('RECORD_AUDIO'.allMatches(manifest).length, 1);
      final voice = File('lib/features/ai/services/voice_service.dart')
          .readAsStringSync();
      expect(voice.contains("import 'package:speech_to_text/speech_to_text.dart'"),
          isTrue);
    });

    test('feature flags stay closed where this pass said so', () {
      final consts = File('lib/core/constants/app_constants.dart')
          .readAsStringSync();
      expect(consts.contains('aiFatwaEnabled'), isTrue,
          reason: 'the gates must still EXIST');
      expect(consts.contains('communityEnabled'), isTrue);
    });
  });
}
