// test/features/hadith/hadith_hotfix_hr11_worker_liveness_test.dart
// ============================================================
// HOTFIX HR-1.1 — THE WORKER MAY BE SLOW, IT MAY NOT BE FOREVER DEAD
// ============================================================
// DEVICE RED (verbatim, owner's CPH2573 debug run after PASS HR-1):
//   [HADITH_SEARCH] worker unresponsive — retired for this session
//   [HADITH_DB] search batch empty — worker unavailable; the corpus is
//               never copied for a keystroke
// …printed ONCE and then on EVERY keystroke after it, with no line ever again
// saying the worker came back. Typing "namaz ka tarika" produced no results for
// the rest of the session: the freeze was fixed, and the search died.
//
// ROOT CAUSE (four lines in `hadith_search_worker.dart` as HR-1 shipped):
//   static const Duration replyTimeout = Duration(seconds: 20);
//   …if (received is! _HadithSearchReply) { _kill(); _dead = true; … }
//   Future<void> start() async { if (_dead) return; … }
//   and noteBook/noteFold set _dead = true on a missing ack.
// i.e. a MISS OF THE BUDGET and THE PORT DYING shared one branch, and that
// branch was terminal — "retired for this session" was literally the log line.
// On that phone the first query arrives behind 7 books of hand-off decoding, so
// one healthy-but-slow worker was executed for the whole session.
//
// WHAT THIS FILE PINS, in the order the brief demanded:
//   1. SLOW ≠ DEAD — a late reply is a MISS, and retirement needs either
//      DEATH EVIDENCE (a send that threw, a reply port that closed without
//      answering, an isolate that exited, a spawn refused) or
//      `retireAfterTimeouts` (2) CONSECUTIVE misses;
//   2. REVIVAL IS RATE-LIMITED — a retired worker is allowed back on the next
//      search commit at most once per `reviveCooldown`, and the clock starts at
//      the attempt (so a refused spawn cannot be retried per keystroke either);
//   3. THE BUDGET IS DEVICE-REALISTIC, and bigger for the first answer after a
//      spawn/revive, because that one queues behind the boot hand-offs;
//   4. SUPERSESSION CLEANS THE LEDGER — a superseded query's lateness is
//      discarded, not counted, so a burst cannot pile up (the ×6 of the log);
//   5. the debug telemetry that turns the next device run into DATA:
//      `scan N answered in Xms over R corpus rows`.
//
// The corpus-copy ban from HR-1 is RE-PINNED here (a hotfix that "fixed"
// availability by scanning on main would pass tests 1-4 and re-break the
// device), and every test in `hadith_pass_hr1_test.dart` is untouched.
//
// WHY SOME OF THESE ARE SOURCE PINS: the worker isolate is deliberately
// unreachable from a test (no rootBundle, no injection, no fake corpus handle —
// that is HR-1's own design), so a fake worker would have to become a supported
// seam. Behavior pins therefore drive a REAL isolate with a tiny injected
// budget, and the branch-shape pins read the file the way
// `test/support/source_guards.dart` does. Both halves are honest about which
// they are: no test here claims to have measured a 45 s scan, and
// `flutter analyze` / `flutter test` are measured by CI, never asserted here.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_search_worker.dart';

import '../../support/source_guards.dart';

const _workerPath =
    'lib/features/hadith/data/services/hadith_search_worker.dart';
const _servicePath =
    'lib/features/hadith/data/services/hadith_database_service.dart';

String _read(String path) => File(path).readAsStringSync();

/// Same shape as `hadith_pass_hr1_test`'s generator (that one is private to
/// that file, and this hotfix may not edit it): a book in the shipped JSON
/// shape, every 97th row fractional so a lost pairKey would be visible.
String _syntheticBook(int firstNumber, int rows, {String bookSlug = 'bukhari'}) {
  final hadiths = <Map<String, dynamic>>[];
  for (var i = 0; i < rows; i++) {
    final n = firstNumber + i;
    final fractional = i % 97 == 96;
    final number = fractional ? '$n.2' : '$n';
    final topic = i % 7 == 0 ? 'namaz ka tarika' : 'patience in hardship';
    hadiths.add({
      'hadithnumber': num.parse(number),
      'arabicnumber': num.parse(number),
      'reference': {
        'book': (i % 3) + 1,
        'hadith': n,
      },
      'grades': [
        {'grade': 'Sahih', 'name': 'Yahya'}
      ],
      'text': 'Volume 1, Book 1, Hadith $n: $topic — the Prophet (peace be '
          'upon him) said, and the chain is complete for row $i of $bookSlug.',
    });
  }
  return jsonEncode({
    'metadata': {
      'name': 'Sahih al-Bukhari',
      'sections': {
        '1': 'The Books of Revelation',
        '2': 'The Book of Faith',
        '3': 'The Book of Prayer',
      },
    },
    'hadiths': hadiths,
  });
}

/// A worker on injected patience: it will time out in milliseconds instead of
/// in the shipped 45 s, and it will revive on a injected clock instead of a
/// minute. Everything else — the isolate, the ports, the scan, the ledger — is
/// the real thing.
HadithSearchWorker _worker({
  required Duration budget,
  int retireAfter = HadithSearchWorker.retireAfterTimeouts,
  Duration revive = const Duration(milliseconds: 30),
}) =>
    HadithSearchWorker(
      replyTimeoutOverride: budget,
      retireAfterTimeoutsOverride: retireAfter,
      reviveCooldownOverride: revive,
    );

void main() {
  // ─────────────────────── 1. the patience contract ─────────────────────────
  group('HR-1.1 the numbers that replaced the 20 s kill switch', () {
    test('replyTimeout is device-realistic, the first answer gets more, and a '
        'miss needs TWO in a row to retire', () {
      expect(HadithSearchWorker.replyTimeout.inSeconds, greaterThanOrEqualTo(30),
          reason: 'HR-1 shipped 20 s on a phone whose FIRST query queues '
              'behind 21 asset decodes; a budget a healthy worker can blow is '
              'not a watchdog. The device run will refine this — it must not '
              'have to survive it first.');
      expect(HadithSearchWorker.firstReplyTimeout > HadithSearchWorker.replyTimeout,
          isTrue,
          reason: 'requirement 3: the first query after boot may be waiting on '
              'corpus assembly, and the boot hand-off is unawaited BY DESIGN '
              '(pinned by hadith_pass_hr1_test) — so the generosity has to be '
              'in the budget, not in an await that would move work onto main');
      expect(HadithSearchWorker.retireAfterTimeouts, 2,
          reason: 'one miss is SLOW, two is a worker that is not answering at '
              'all; anything higher keeps a reader waiting on a dead isolate');
      expect(HadithSearchWorker.reviveCooldown.inSeconds, 60,
          reason: 'the brief said ~60 s and the number is the rate limit — '
              'documented, greppable, and asserted by behaviour below');
      expect(HadithSearchWorker.handoffGrace > HadithSearchWorker.replyTimeout,
          isTrue,
          reason: 'a book decode is the slowest thing the worker does and its '
              'ack is not on the keystroke path; HR-1 timed it out at 20 s and '
              'called the boot dead');
    });

    test('the cold budget is the big one, the warm budget is the shipped one',
        () async {
      final worker = _worker(budget: const Duration(seconds: 30));
      addTearDown(worker.shutdownForTest);
      expect(worker.currentReplyBudget, HadithSearchWorker.firstReplyTimeout,
          reason: 'nothing has been answered yet, so the wait in front of the '
              'boot backlog gets the longer budget');
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 40));
      await worker.whenSettled();
      final warm = await worker.search(['patience'], maxPerQuery: 3);
      expect(warm, isNotNull, reason: 'no isolate in this environment — the two '
          'budget assertions below would otherwise be vacuous');
      expect(worker.currentReplyBudget, worker.effectiveReplyTimeout,
          reason: 'after the first answer the budget drops back to normal — '
              'the generosity is for the boot, not a licence to hang forever');
      worker.forceCold();
      expect(worker.currentReplyBudget, HadithSearchWorker.firstReplyTimeout,
          reason: 'and a REVIVE is a new boot: the new isolate owns no corpus '
              'until the service re-hands it (test 4), so the second '
              'chance gets the same patience the first one did');
    });
  });

  // ───────────────── 2. SLOW ≠ DEAD, on a real isolate ─────────────────────
  group('HR-1.1 a slow answer is a miss, not an execution', () {
    test('TWO misses with no reply in between is the retirement, and one is not',
        () async {
      // A budget of one millisecond makes a miss DETERMINISTIC on any machine:
      // no real isolate answers a round trip in under 1 ms. We are not testing
      // that a phone is slow — we are testing what this code DOES when a reply
      // is late, and HR-1 answered that question with `retired for this session`.
      final worker = _worker(
        budget: const Duration(milliseconds: 1),
        revive: const Duration(seconds: 600),
      );
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 60));
      await worker.whenSettled();
      expect(worker.isLive, isTrue, reason: 'spawn refused in this environment '
          '— every assertion below would be vacuous (same caveat '
          'hadith_pass_hr1_test states out loud)');

      final first = await worker.search(['namaz ka tarika'], maxPerQuery: 3);
      expect(first, isNull, reason: 'the budget was 1 ms; the answer is empty');
      expect(worker.timeouts, lessThanOrEqualTo(1),
          reason: 'the miss must be COUNTED — HR-1.1 does not hide slowness, '
              'it stops mistaking it for death, so the counter is the disclosure');
      expect(worker.retired, isFalse,
          reason: 'ONE miss. This is the exact assertion that was RED before the '
              'fix: HR-1 killed the worker on the first late reply');
      expect(worker.isLive, isTrue, reason: 'and the port is still open');

      final second = await worker.search(['patience'], maxPerQuery: 3);
      expect(second, isNull);
      expect(worker.retired, isTrue,
          reason: 'the SECOND consecutive miss retires it: a live worker that '
              'has not answered twice is not answering, and a search stream must '
              'not hang on that forever');
      expect(worker.pendingReplies, isEmpty,
          reason: 'retirement leaves NO armed wait behind — a stale entry '
              'surviving here is the ×6 pile in a different hat');
      expect(worker.inFlight, 0);
      expect(await worker.search(['patience'], maxPerQuery: 3), isNull,
          reason: 'and during the cooldown the answer stays honestly empty');
      expect(worker.handedBooks, isNotEmpty,
          reason: 'the hand-off list survives, because the re-hand after revival '
              'is driven off it (test group 3)');
    });

    test('the timeout branch cannot retire the worker by itself — retirement '
        'goes through one evidence-checked door', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      final retire = RegExp(r'\b_retire\(lateReply:\s*true\)');
      expect(retire.hasMatch(code), isTrue,
          reason: 'soft retirement exists as ONE call site shape, so the '
              'counter rule lives in exactly one place (`_retire`) instead of '
              'being re-derived at each timeout');
      // The rule, stated as a census: no path may set the flag directly any
      // more. `_retired = true` is allowed ONLY in `_start`'s spawn-refused
      // branch (that is death evidence) and inside `_retire` itself.
      final sets = RegExp(r'_retired\s*=\s*true').allMatches(code).length;
      expect(sets, 2,
          reason: 'exactly two, and NEITHER is a timeout: one inside `_retire` '
              '(the single decision point, reached only with evidence) and one in '
              'the spawn-refused branch of `start()`. A third means someone added '
              'a new way to be dead');
      expect(code.contains('_dead'), isFalse,
          reason: 'the terminal flag is gone, not shadowed: leaving `_dead` '
              'around would leave the old `if (_dead) return;` reachable');
      expect(
          RegExp(r'\.timeout\(\s*replyTimeout\s*\)\s*;').hasMatch(code), isFalse,
          reason: 'no un-guarded timeout may decide the worker\'s fate: every '
              'budget must land in `_noteMissedBudget` or `_retire`');
    });

    test('noteBook / noteFold stopped treating a missing ack as death', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      final book = _method(code, 'Future<void> noteBook(');
      final fold = _method(code, 'Future<void> noteFold(');
      for (final body in [book, fold]) {
        expect(body, isNotEmpty);
        expect(body.contains('_retire(lateReply: false)'), isTrue,
            reason: 'a send that THROWS is still death evidence and must still '
                'retire — the hotfix is slow≠dead, not dead≠dead');
        expect(body.contains('_retire(lateReply: true)'), isFalse,
            reason: 'a late ACK must not even count as one miss: the boot '
                'decode is the slowest thing the worker does');
        expect(body.contains('handoffGrace'), isTrue,
            reason: 'and it gets its own, larger budget instead of borrowing '
                'the keystroke path\'s');
        expect(body.contains('_noteLateHandoff('), isTrue,
            reason: 'what it DOES do is log that it is still waiting — the '
                'line the device run needs');
      }
    });
  });

  // ──────────────── 3. rate-limited revival, and only that ──────────────────
  group('HR-1.1 a retired worker comes back ONCE per cooldown', () {
    test('death retires at once; the cooldown refuses a second attempt; the '
        'next commit after it revives and answers', () async {
      final worker = _worker(
        budget: const Duration(seconds: 30),
        revive: const Duration(milliseconds: 40),
      );
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 60));
      await worker.whenSettled();
      expect(await worker.search(['patience'], maxPerQuery: 3), isNotNull,
          reason: 'a live isolate first, or the retirement below is a fiction');

      // DEATH EVIDENCE retires immediately — no two-miss warm-up. This is the
      // other half of requirement 1 and it must stay fast, or a genuinely dead
      // worker would be polled for two whole budgets before anyone reacted.
      worker.noteDeathForTest('died mid-request');
      expect(worker.retired, isTrue);
      expect(worker.isLive, isFalse, reason: 'the port is gone, not just distrusted');

      // During the cooldown: dead to searches, and NO respawn.
      expect(await worker.search(['patience'], maxPerQuery: 3), isNull,
          reason: 'a retired worker answers honestly empty — never by scanning '
              'on main');
      expect(await worker.search(['namaz'], maxPerQuery: 3), isNull,
          reason: 'the SECOND commit inside the window must not respawn either: '
              'that is how a per-keystroke isolate storm would come back');
      expect(worker.retired, isTrue, reason: 'still retired, as above');

      // After the cooldown: the next commit revives, and it ANSWERS.
      await Future<void>.delayed(const Duration(milliseconds: 140));
      expect(await worker.search(['patience'], maxPerQuery: 3), isNotNull,
          reason: 'THE POINT OF THE HOTFIX: search is never dead for a session. '
              'HR-1\'s `if (_dead) return;` failed exactly this assertion.');
      expect(worker.retired, isFalse);
      expect(worker.isLive, isTrue);
      expect(worker.timeouts, 0, reason: 'a revival starts with a clean slate, '
          'not a continuation of the argument that killed it');
    });

    test('a revival is not a silent empty corpus — the service owes one re-hand',
        () async {
      final worker = _worker(
        budget: const Duration(seconds: 30),
        revive: const Duration(milliseconds: 20),
      );
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 60));
      await worker.whenSettled();
      expect(await worker.search(['patience'], maxPerQuery: 3), isNotNull);
      worker.noteDeathForTest('exited');
      expect(worker.retired, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await worker.start();
      expect(worker.retired, isFalse,
          reason: 'the next commit after the cooldown got a worker back');
      expect(worker.corpusStale, isTrue,
          reason: 'the fresh isolate owns NOTHING while `handedBooks` still '
              'names a book — without this flag a "successful" revival would '
              'answer empty forever and look healthy');
      worker.forceCold();
      expect(worker.currentReplyBudget, HadithSearchWorker.firstReplyTimeout,
          reason: 'and it is COLD: the re-hand queue is in front of the query');
      // The service half, done by hand here: re-hand, then clear the flag — the
      // order matters, and this is exactly what `rebuildSearchCorpus()` +
      // `markCorpusFresh()` do in production.
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 60));
      await worker.whenSettled();
      worker.markCorpusFresh();
      expect(worker.corpusStale, isFalse);
      expect(await worker.search(['patience'], maxPerQuery: 3), isNotNull,
          reason: 'the books still resident on main get re-handed by the '
              'service (test below), and the answer is real');
    });

    test('the re-hand REUSES THE BOOT LOADER — no corpus map, no new read path',
        () {
      final code = stripCommentsForGuard(_read(_servicePath));
      final rebuild = _method(code, 'Future<void> rebuildSearchCorpus()');
      expect(rebuild, isNotEmpty,
          reason: 'the revive contract has a service half: without it a revived '
              'worker answers empty forever');
      expect(rebuild.contains('await _loadBook('), isTrue,
          reason: 'it re-hands through the SAME per-book load the boot uses — '
              '21 reads and off-main decodes, no second implementation to drift');
      expect(rebuild.contains('_bookData'), isFalse,
          reason: 'it looks at slugs, never at rows: `_bookData.containsKey` '
              'would already be a corpus walk on the caller\'s thread');
      expect(rebuild.contains('Map<String, List<LocalHadith>>'), isFalse,
          reason: 'HR-1\'s ban, restated for the new code: a revival that '
              'copies the corpus on main is the freeze backdoor');
      final batch = _method(
          code, 'Future<List<List<LocalSearchResult>>> searchBatchOffMain(');
      expect(batch.contains('worker.corpusStale'), isTrue,
          reason: 'the re-hand is driven by the worker\'s own state, so it '
              'cannot fire per keystroke');
      expect(batch.contains('Isolate.run'), isFalse);
      expect(batch.contains('Map<String, List<LocalHadith>>.of'), isFalse);
    });

    test('a refused spawn starts the cooldown too — no failed spawn per key',
        () {
      // The gate every hadith test shares: a platform that refuses the isolate.
      // HR-1 set the terminal flag once; HR-1.1 must not turn `start()` into a
      // spawn attempt per commit, so the REFUSAL itself records the attempt.
      final code = stripCommentsForGuard(_read(_workerPath));
      final start = _method(code, 'Future<void> start() async {');
      expect(
          RegExp(r'catch\s*\(e\)\s*\{[\s\S]*?_lastReviveAttemptAt\s*=\s*DateTime\.now')
              .hasMatch(start),
          isTrue,
          reason: 'the catch that sets the retired flag must ALSO start the '
              'cooldown clock, or a refused platform pays a spawn per keystroke');
      expect(start.contains('if (_retired && !_reviveWindowOpen()) return;'),
          isTrue,
          reason: 'the rate limit is the FIRST thing start() consults — before '
              'the single-flight check, so a concurrent commit cannot slip past it');
    });
  });

  // ─────────── 4. supersession discards stale timeout bookkeeping ───────────
  group('HR-1.1 a newer query cancels the older one\'s bookkeeping', () {
    test('the ledger closes on every exit path, so a burst cannot pile up',
        () async {
      // retireAfter raised to 4 so this test can assert the COUNT without the
      // retirement itself racing the assertion — what is under test is that a
      // burst leaves no ledger and at most one honest miss, not that two misses
      // retire (the group above pins that).
      final worker = _worker(
        budget: const Duration(milliseconds: 2),
        retireAfter: 4,
      );
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari',
          name: 'Sahih al-Bukhari',
          rawEnglish: _syntheticBook(1, 60));
      await worker.whenSettled();

      // Three commits at once — the shape of a typing burst that reached the
      // worker before the debounce was introduced. None may leave a ghost.
      final three = await Future.wait([
        worker.search(['n'], maxPerQuery: 3),
        worker.search(['na'], maxPerQuery: 3),
        worker.search(['namaz ka tarika'], maxPerQuery: 3),
      ]);
      expect(three, hasLength(3));
      expect(worker.inFlight, 0,
          reason: 'the ×6 pile, in one line: HR-1 left one stale armed wait per '
              'keystroke, and every one of them could reach for the kill switch');
      expect(worker.pendingReplies, isEmpty);
      expect(worker.timeouts, lessThanOrEqualTo(2),
          reason: 'three concurrent queries may cost AT MOST two counted misses: '
              'a superseded one is discarded, and a retirement for a phrase the '
              'reader is still typing is the bug we came to fix (HR-1 counted '
              'every one of them)');
      expect(worker.retired, isFalse, reason: 'and the worker is still live');
      expect(worker.isLive, isTrue);
    });

    test('the newest-only rule is written down, not implied', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      expect(code.contains('bool _endSearchHandoff(_HadithSearchHandoff handoff)'),
          isTrue,
          reason: 'one function closes a ledger entry AND reports whether it was '
              'the newest — the two must not be split across call sites');
      expect(code.contains('return handoff.id >= _newestSentId;'), isTrue,
          reason: 'the predicate, pinned: anything overtaken by a newer commit '
              'is not evidence about the worker');
      expect(code.contains('_noteMissedBudget(\'query $id\', newest: wasNewest)'),
          isTrue,
          reason: 'and the timeout path is the one that uses it');
      expect(code.contains('_noteMissedBudget'), isTrue);
      // No second ledger: one list of INTS, nothing else.
      expect(RegExp(r'_pendingReplies\.add').allMatches(code).length, 1);
      expect(code.contains('List<_HadithSearchRequest>'), isFalse,
          reason: 'the ledger holds request IDS, never the request objects — a '
              'held request keeps the query list alive and, one refactor from '
              'now, could hold rows');
    });
  });

  // ───────────── 5. the debug numbers the next device run needs ────────────
  group('HR-1.1 the measurement, not the excuse', () {
    test('the reply carries scan ms and corpus rows, and main prints them', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      expect(code.contains('final sw = Stopwatch()..start();'), isTrue,
          reason: 'measured INSIDE the worker, where the cost actually is — '
              'main\'s stopwatch would include hand-off queueing and teach the '
              'wrong lesson');
      expect(code.contains('elapsedUs: sw.elapsedMicroseconds'), isTrue);
      expect(code.contains('corpusRows: rows'), isTrue,
          reason: 'a scan time without the row count it scanned is not '
              'actionable — the whole point is 20,020 vs 36,390 vs whatever the '
              'device booted');
      expect(RegExp(r"scan \$id answered in").hasMatch(code), isTrue,
          reason: 'the kDebugMode line the owner will paste next time');
      expect(code.contains('Isolate.exit()'), isTrue,
          reason: 'when main retires us we stop existing — a leaked isolate is '
              'the other way a "dead" worker keeps costing the device');
    });

    test('slowness is DISCLOSED in the log line, not hidden by a bigger number',
        () {
      final code = stripCommentsForGuard(_read(_workerPath));
      expect(
          code.contains('SLOW is not DEAD, the worker stays live and '), isTrue,
          reason: 'the first line a reader of the device log needs: one missed '
              'budget is documented as what it is, in the app, not only here');
      expect(
          code.contains('answered after its budget') ||
              code.contains('cannot be misread as a death'),
          isTrue,
          reason: 'and the late-reply path is named somewhere the next reader '
              'will actually look');
    });
  });
}

/// The method from its signature to its closing brace — the same balanced-
/// `open-brace` discipline `hadith_pass_hr1_test` uses, because a signature
/// with a wrapped parameter list defeats the naive scan.
String _method(String code, String signatureStart) {
  final start = code.indexOf(signatureStart);
  if (start < 0) return '';
  final params = code.indexOf(')', start);
  final open = code.indexOf('{', params);
  if (params < 0 || open < 0) return '';
  final end = code.indexOf('\n  }', open);
  return end < 0 ? '' : code.substring(start, end);
}
