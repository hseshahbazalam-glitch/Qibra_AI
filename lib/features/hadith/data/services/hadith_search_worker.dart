// lib/features/hadith/data/services/hadith_search_worker.dart
// ============================================================
// QIBRA AI — PERSISTENT HADITH SEARCH WORKER (PASS HR-1)
//
// WHY THIS FILE EXISTS (owner device finding, CPH2573, profile mode):
// typing "namaz ka tarika" into the hadith search froze the whole app. The
// hadith tab committed a query on EVERY keystroke, and each keystroke reached
// HadithDatabaseService.searchBatchOffMain, whose body was
//     final booksSnapshot = Map<String, List<LocalHadith>>.of(_bookData);
//     return Isolate.run(() { ...scan booksSnapshot... });
// `Map.of` is only a shallow map copy — the cost is the NEXT line: Isolate.run
// spawns a fresh isolate and SENDS it the closure, and a message copy is a DEEP
// copy of the captured object graph. So every keystroke copied all 36,390
// LocalHadith rows out of the main isolate, on the main isolate, before any
// matching started. 14 keystrokes = 14 corpus copies = a multi-second block per
// character. CI could not see it: every hadith search test drives a _FakeDb
// that OVERRIDES searchBatchOffMain, so the capture never ran there.
//
// THE CONTRACT NOW: one long-lived worker isolate OWNS its own decoded copy of
// the corpus, built once from the same raw asset strings the boot already
// reads, with the same pure assembler the main isolate uses (so a worker hit and
// a main-isolate render can never disagree). Search is "query strings in ->
// relevance-ranked top-N out". Nothing on the typing path captures the corpus
// graph, so the per-call copy is structurally zero, and a newer query discards
// an older queued one instead of paying for it.
//
// RAM, stated plainly: this is the FALLBACK shape the brief pre-authorizes, not
// the single-residency ideal. The corpus is resident twice — main keeps
// `_bookData` for rendering (book lists, chapter filters, the detail sheet), the
// worker keeps its copy for scanning. One static second copy is bought to get
// zero per-keystroke copies: the second costs memory, the per-call ones cost the
// UI thread. The paged/chunked render refactor that would retire the main copy
// is a disclosed follow-up, not a silent ship.
//
// ------------------------------------------------------------
// HOTFIX HR-1.1 (owner device re-run after HR-1 shipped): the worker existed
// but search stayed dead for the rest of the session. Four lines in the HR-1
// shape caused it, and every one of them is fixed HERE, in this file, because
// a device cannot tell slow from dead and a session-long retirement is worse
// than a late answer:
//
//   1. SLOW WAS TREATED AS DEAD. Any reply that missed the 20 s budget fell
//      into `received is! _HadithSearchReply` — the branch that also catches
//      garbage — and that branch killed the isolate and set `_dead = true`
//      FOREVER. On the CPH2573 (Android 15, mid/low tier, debug JIT) a boot
//      backlog of 7 books plus a cold first scan is comfortably over 20 s, so
//      the reader's very first query retired the worker and every keystroke
//      after it answered EMPTY for the rest of the app's life.
//   2. THERE WAS NO RESPAWN PATH. `start()` opened with `if (_dead) return;`,
//      so retirement was terminal by construction.
//   3. THE BUDGET WAS NOT DEVICE-REALISTIC and did not care that the FIRST
//      query may queue behind corpus assembly.
//   4. SUPERSEDED QUERIES STILL HELD THEIR HANDOFF LEDGERS, so a burst piled
//      stale timeout bookkeeping on top of the live one (the ×6 the debug log
//      showed: six retirements' worth of waits for one typed phrase).
//
// The rules now, stated so a reviewer can grep for them:
//   * retirement needs EVIDENCE OF DEATH — a send that threw, a reply port
//     that died without answering, an isolate that exited, a spawn refused —
//     or TWO consecutive missed budgets (one miss is "slow", logged and kept);
//   * a retired worker REVIVES, at most once per `reviveCooldown`, on the next
//     search commit, because a retired worker used to mean "no search until
//     the app restarts";
//   * `replyTimeout` is device-realistic and the first reply after boot gets
//     `firstReplyTimeout`, because the boot handoff is deliberately unawaited;
//   * a query superseded by a newer one drops its pending handoff ledger
//     entry without touching the timeout counter.
// What this fix does NOT do: it never copies the corpus on main (HR-1's ban is
// untouched and re-pinned), and it never hides the slowness — in a DEBUG build
// an answer may legitimately take longer than the old 20 s; that is now
// honest, measured, debugPrint'ed slowness with the UI still responding, not a
// hang and not a dead session.
// ============================================================

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'hadith_database_service.dart';

/// One book's raw asset text, handed to the worker once per book per session.
/// Strings only: copying a String into an isolate message is a memcpy of that
/// file, not a walk over 36k objects — which is the whole asymmetry this design
/// buys.
class _HadithBookPayload {
  const _HadithBookPayload({
    required this.slug,
    required this.name,
    required this.rawEnglish,
    required this.rawArabic,
    required this.rawUrdu,
    required this.langIndices,
  });

  final String slug;
  final String name;
  final String? rawEnglish;
  final String? rawArabic;
  final String? rawUrdu;

  /// Pass H1/X1 pair-keyed indices for editions folded in late (the FOLD SEAM:
  /// empty while `HadithAvailability.newLanguageFiles` is empty, exactly like
  /// the main isolate's own `langIndices`).
  final Map<String, Map<String, String>> langIndices;
}

/// Queued behind every payload sent so far: the worker's reply IS the ack,
/// because a ReceivePort delivers in FIFO order.
class _HadithFlushRequest {
  const _HadithFlushRequest(this.replyTo);

  final SendPort replyTo;
}

/// A late-folded language for ONE book: the pair-keyed index, not the rows.
/// Sending the index (a few MB on a user action, never on a keystroke) and
/// re-running the shared fold keeps the two copies of the corpus derived from
/// the same rules instead of shipping a whole row list across.
class _HadithFoldRequest {
  const _HadithFoldRequest({
    required this.slug,
    required this.code,
    required this.index,
  });

  final String slug;
  final String code;
  final Map<String, String> index;
}

/// One search request in flight, answered on its own [replyTo] port.
class _HadithSearchRequest {
  const _HadithSearchRequest({
    required this.id,
    required this.queries,
    required this.maxPerQuery,
    required this.replyTo,
  });

  final int id;
  final List<String> queries;
  final int maxPerQuery;
  final SendPort replyTo;
}

/// Either the ranked batches, or the marker saying a newer query had already
/// arrived and this one was answered without touching the corpus.
///
/// HR-1.1 adds the two telemetry fields. The worker CANNOT reach `debugPrint`
/// (no Flutter binding in this isolate), so the measurement is smuggled back on
/// the reply main is already waiting for, and main logs it: the device run then
/// yields the real number for a low-end phone instead of this file guessing one.
/// `int`s only — nothing here is a corpus handle, so the HR-1 capture ban is
/// structurally unaffected by the extra fields.
class _HadithSearchReply {
  const _HadithSearchReply(
    this.superseded,
    this.batches, {
    this.elapsedUs = 0,
    this.corpusRows = 0,
  });

  final bool superseded;
  final List<List<LocalSearchResult>> batches;

  /// Whole time the worker spent inside this scan, microseconds.
  final int elapsedUs;

  /// Rows resident in the worker when the scan ran.
  final int corpusRows;
}

class HadithSearchWorker {
  /// HR-1.1 seams. Every knob has a DEFAULT that is what the app uses, so
  /// production construction (`HadithSearchWorker()`, `instance`) is unchanged
  /// in behaviour; a test can drive the patience state machine without waiting
  /// 45 s per timeout. There is deliberately NO corpus-injection seam: the one
  /// thing HR-1 forbids is a second way to get rows onto the main isolate.
  HadithSearchWorker({
    this.replyTimeoutOverride,
    this.retireAfterTimeoutsOverride,
    this.reviveCooldownOverride,
  });

  /// The app has exactly one hadith corpus, so exactly one worker owns it.
  static final HadithSearchWorker instance = HadithSearchWorker._shared();

  // The shared singleton takes no overrides: it MUST run the shipped numbers,
  // and an optional parameter nobody on this path can pass is a test seam
  // leaking into production (CI's `unused_element_parameter` warning, twice
  // over — the fields still need their initializers, which is what the
  // `final_not_initialized_constructor` error said after the first cut).
  HadithSearchWorker._shared()
      : replyTimeoutOverride = null,
        retireAfterTimeoutsOverride = null,
        reviveCooldownOverride = null;

  /// The budget for ONE reply before the worker is treated as possibly-wedged
  /// (HR-1.1: 45 s, not HR-1's 20 s).
  ///
  /// The old number was set from a desktop guess — "a whole-corpus scan of 36k
  /// rows is a few hundred ms on a mid phone" — and the device disagreed: the
  /// first query after boot does not just scan, it waits behind SEVEN books of
  /// hand-off decoding (the boot hands them over unawaited on purpose, see
  /// `HadithDatabaseService._loadBook`), on a CPH2573 running DEBUG/JIT. A
  /// budget that a healthy worker can blow is not a watchdog, it is a kill
  /// switch, and killing it cost the reader their whole session's search.
  ///
  /// Missing this budget is therefore NOT death any more: see
  /// [retireAfterTimeouts]. The measured cost of a real scan is logged
  /// (kDebugMode) with the reply's own numbers, so the next device run replaces
  /// this guess with data instead of another guess.
  static const Duration replyTimeout = Duration(seconds: 45);

  /// The budget for the FIRST reply a fresh worker answers. Boot hands books
  /// over WITHOUT awaiting them (first-frame priority, pinned by
  /// `hadith_pass_hr1_test`), so a query typed the moment the tab paints is
  /// queued behind up to 21 asset decodes. Generous on purpose: the alternative
  /// is answering empty while the worker is about to be fine.
  static const Duration firstReplyTimeout = Duration(seconds: 90);

  /// Consecutive missed reply budgets needed before the worker is retired.
  /// ONE is a slow answer, not a wedged one; TWO says a live worker is not
  /// making progress at all while its port stays open.
  static const int retireAfterTimeouts = 2;

  /// How often a retired worker may try to come back. Rate-limited because the
  /// failure HR-1.1 is fixing is the opposite of a respawn storm: never search
  /// dead for a whole session, and never spawn per keystroke either. One
  /// attempt per minute per worker, on the next search COMMIT (not on a
  /// keystroke), is the middle.
  static const Duration reviveCooldown = Duration(seconds: 60);

  /// The boot hand-off grace: a book's decode is the slowest thing the worker
  /// ever does, and the ack is NOT on the keystroke path, so this budget is
  /// allowed to be boring. Beating it does not retire the worker either — it
  /// just stops `whenSettled()` from waiting forever on a hand-off that will
  /// land later.
  static const Duration handoffGrace = Duration(seconds: 120);

  /// How long the handover port may take to appear before the spawn counts as
  /// refused. Boot must never wait on the worker beyond this.
  static const Duration handshakeTimeout = Duration(seconds: 5);

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _toWorker;
  Future<void>? _starting;
  int _requestSeq = 0;

  /// HR-1.1: `_dead` becomes `_retired`, and retirement is a STATE, not a
  /// verdict — [start] may leave it once per [reviveCooldown].
  bool _retired = false;
  final List<Future<void>> _handoffs = [];

  /// Hand-offs whose reply main is still waiting for (request ids, newest
  /// last). This is the ledger supersession prunes, and what a stale timeout
  /// is attributed through. It holds INTS only — never rows, never the corpus.
  final List<int> _pendingReplies = <int>[];

  /// Missed reply budgets in a row. Cleared by any successful round trip.
  int _timeouts = 0;

  /// Missed budgets that were DISCARDED because a newer query had already
  /// overtaken them (the half of HR-1.1's ledger that `[timeouts]` deliberately
  /// does not count). Cumulative, and deliberately NOT cleared by a late reply
  /// arriving: a refunded miss still happened, and "the burst was really armed"
  /// is a fact a test must be able to read even after the refund.
  int _supersededMisses = 0;

  /// Highest request id main has sent: a reply for anything below it was
  /// already overtaken, so its lateness says nothing about the worker's health.
  int _newestSentId = 0;

  /// True once this worker has answered anything. Until then every wait runs on
  /// [firstReplyTimeout] because the boot backlog is in front of the queue.
  bool _everAnswered = false;

  DateTime? _lastReviveAttemptAt;

  /// Bumped on every successful spawn. The `onExit` listener carries the
  /// generation it was armed for, so the exit of a worker we already replaced
  /// cannot retire the NEW one — without this, `shutdownForTest()` between two
  /// tests would let a stale exit message poison the next spawn.
  int _generation = 0;

  /// HR-1.1 test seams (see the constructor). Null = the shipped value.
  final Duration? replyTimeoutOverride;
  final int? retireAfterTimeoutsOverride;
  final Duration? reviveCooldownOverride;

  /// Book names handed over. Deliberately a Set of Strings and nothing more:
  /// a stray debug call must not be able to grow a second corpus reference on
  /// the main side.
  final Set<String> _handed = <String>{};

  /// The budget in force for THIS worker, injected override or shipped default.
  /// Named `effective…` because a static and an instance member may not share
  /// a name in Dart (CI caught `conflicting_static_and_instance` the first time
  /// this was `replyTimeout`) — and because the distinction is the whole point:
  /// the CONSTANT is what the app ships, this is what this worker enforces.
  Duration get effectiveReplyTimeout =>
      replyTimeoutOverride ?? HadithSearchWorker.replyTimeout;

  /// The budget for the wait about to be made: the long one while the boot
  /// backlog is still ahead of the queue, the normal one afterwards. Public
  /// because "the first query after boot gets a bigger budget" is a claim a
  /// test must be able to read, not just a comment that says it.
  Duration get currentReplyBudget =>
      _everAnswered ? effectiveReplyTimeout : firstReplyBudget;

  /// The cold-start patience, override-aware: an injected `replyTimeout` REPLACES
  /// both budgets, because a test that asks for a 1 ms miss must get one on the
  /// first query too. With no injection the shipped `firstReplyTimeout` applies —
  /// the number the device actually runs with.
  Duration get firstReplyBudget =>
      replyTimeoutOverride ?? HadithSearchWorker.firstReplyTimeout;

  int get effectiveRetireAfterTimeouts =>
      retireAfterTimeoutsOverride ?? HadithSearchWorker.retireAfterTimeouts;

  Duration get effectiveReviveCooldown =>
      reviveCooldownOverride ?? HadithSearchWorker.reviveCooldown;

  bool get isLive => _toWorker != null && !_retired;

  /// Consecutive missed budgets, and the moment the last revival was tried.
  /// Plain fields (a getter/setter pair over one field is noise the analyzer
  /// flags) because the patience state machine has to be readable from a test
  /// — and settable, so the state machine can be tested without waiting 45 s
  /// per timeout. App code never writes either.
  int get timeouts => _timeouts;

  /// See [timeouts]: a test seam, documented as one.
  set timeouts(int value) => _timeouts = value;

  /// See [timeouts]: the discard ledger, as a seam. Pinned by the HR-1.1 burst
  /// test because a COUNTED miss is not observable there — the late reply that
  /// HR-1.1 delivers refunds it (`_refundLateReply`) — while the discards are.
  int get supersededMisses => _supersededMisses;

  bool get retired => _retired;

  DateTime? get lastReviveAttemptAt => _lastReviveAttemptAt;

  /// See [lastReviveAttemptAt]: a test seam, documented as one.
  set lastReviveAttemptAt(DateTime? value) => _lastReviveAttemptAt = value;

  /// Request ids main is still holding a wait open for.
  List<int> get pendingReplies =>
      List<int>.unmodifiable(_pendingReplies);

  /// Slugs the worker has been asked to hold (not a claim that it has decoded
  /// them yet — [whenSettled] is the claim).
  List<String> get handedBooks => _handed.toList(growable: false);

  /// The re-hand is done: stop asking the service to rebuild. Called by
  /// `HadithDatabaseService.rebuildSearchCorpus`, and by nothing else — the
  /// worker cannot fetch its own corpus (no rootBundle in here), which is the
  /// same reason it can never be handed the corpus map.
  void markCorpusFresh() => _corpusStale = false;

  /// HR-1.1: set when this worker's isolate is FRESH relative to the books it
  /// has been told about — i.e. it revived after a retirement and its corpus is
  /// empty while `handedBooks` still lists the boot hand-offs. The service owes
  /// it ONE re-hand (see `HadithDatabaseService.rebuildSearchCorpus`); that is
  /// the whole revival contract, and it never means "scan on main instead".
  bool get corpusStale => _corpusStale;
  bool _corpusStale = false;

  /// Spawn (idempotent, single-flight) and wait for the worker's command port.
  /// Never throws: a platform that refuses the spawn retires the worker and the
  /// service then answers honestly EMPTY — it must never copy the corpus
  /// instead, because that copy is the freeze HR-1 exists to remove.
  ///
  /// HR-1.1 changed the exit conditions: `if (_dead) return;` (a terminal door
  /// that never reopened) is now a RATE-LIMITED pause on a retired worker, so a
  /// retirement costs at most one search commit and one `reviveCooldown`, not
  /// the rest of the session.
  Future<void> start() async {
    if (_toWorker != null && !_retired) {
      _timeouts = 0;
      return;
    }
    if (_retired && !_reviveWindowOpen()) return;
    final pendingStart = _starting;
    if (pendingStart != null) {
      await pendingStart;
      return;
    }
    final reviving = _retired;
    if (reviving) {
      _lastReviveAttemptAt = DateTime.now();
    }
    final completer = Completer<void>();
    _starting = completer.future;
    final inbox = ReceivePort();
    final exitSignal = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
        _hadithSearchWorkerEntry,
        inbox.sendPort,
        debugName: 'hadith-search-worker',
        // `onExit` fires for a clean exit AND for a crash, which is precisely
        // the difference HR-1.1 had to learn the hard way: the only signal that
        // may retire a worker without a budget is the VM saying it is gone.
        onExit: exitSignal.sendPort,
      );
      // Typed `Object?` on purpose: `ReceivePort` delivers `dynamic`, and under
      // this repo's `strict-casts: true` handing that straight to a `SendPort`
      // field is an error, not a lint.
      final Object? announced = await inbox.first
          .timeout(handshakeTimeout, onTimeout: () => null);
      if (announced is! SendPort) {
        // Genuine death evidence, not slowness: the process that was supposed
        // to announce a port never did. Drain first — a ReceivePort left
        // undelivered when the handshake fails would surface as an unhandled
        // async error on main, replacing a clean retirement with a crash.
        unawaited(inbox.drain<void>());
        unawaited(exitSignal.drain<void>());
        isolate.kill(priority: Isolate.immediate);
        throw StateError('worker never announced its port');
      }
      _toWorker = announced;
      _isolate = isolate;
      _inbox = inbox;
      _generation++;
      // HR-1.1: an isolate that exits or dies is DEATH, told to us by the VM —
      // the one signal that retires without waiting for the budget twice. The
      // channel is the `onExit` port handed to `Isolate.spawn` (a ReceivePort
      // has NO `.errors` getter on this SDK — CI's `undefined_getter` taught me
      // that), drained exactly once below so an exit never becomes an unhandled
      // async error on main.
      final armedFor = _generation;
      unawaited(
          exitSignal.first.whenComplete(() => _retireOnIsolateExit(armedFor)));
      if (reviving) {
        // The new isolate owns NOTHING while `handedBooks` still names the
        // boot hand-offs, so the service has one re-hand to make. Forgetting
        // this is how a revival would silently become "search answers nothing".
        _corpusStale = _handed.isNotEmpty;
        _handoffs.clear();
        _pendingReplies.clear();
        _timeouts = 0;
      }
      _retired = false;
      _everAnswered = reviving ? false : _everAnswered;
      if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] worker live${reviving ? ' (revived)' : ''} '
            '— search answers off-main, corpus owned there');
      }
    } catch (e) {
      // Death evidence: the spawn was refused. Retirement is rate-limited, not
      // terminal — the next commit after `reviveCooldown` tries again. Recording
      // the attempt HERE is what stops a platform that refuses the isolate
      // (some CI sandboxes) from paying a failed spawn per keystroke.
      _lastReviveAttemptAt = DateTime.now();
      _toWorker = null;
      _isolate = null;
      _corpusStale = false;
      _retired = true;
      try {
        exitSignal.close();
        inbox.close();
      } catch (_) {
        // The inbox may already be closed on the path that got us here, and a
        // failure while retiring a worker must not turn a search miss into a
        // crash. Deliberately silent, deliberately said out loud (P3-7 wants
        // every empty catch in lib to explain itself).
      }
      if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] spawn refused ($e) — hadith search '
            'answers empty rather than copying the corpus on the main isolate; '
            'revive allowed again after ${effectiveReviveCooldown.inSeconds}s');
      }
    } finally {
      _starting = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// The rate limit on coming back. With no attempt on record the window is
  /// open; afterwards it opens once `reviveCooldown` has passed. This is why a
  /// wedged worker costs one commit, not a respawn per keystroke.
  bool _reviveWindowOpen() {
    final last = _lastReviveAttemptAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= effectiveReviveCooldown;
  }

  /// The ONE place retirement is decided. Callers hand it evidence: a
  /// [lateReply] is a missed budget (soft — it needs [retireAfterTimeouts] of
  /// them in a row), anything else here is death (a refused spawn, a send that
  /// threw, a reply port that died without answering, an isolate that exited).
  void _retire({required bool lateReply}) {
    if (lateReply) {
      _timeouts++;
      if (_timeouts < effectiveRetireAfterTimeouts) {
        if (kDebugMode) {
          final patience = effectiveRetireAfterTimeouts;
          debugPrint('[HADITH_SEARCH] reply $_timeouts/$patience '
              'missed its budget — SLOW is not DEAD, the worker stays live and '
              'the UI kept responding');
        }
        return;
      }
    }
    _kill();
    _retired = true;
    // The cooldown is measured from the DEATH, not from the last spawn attempt
    // before it. Without this stamp the first commit after a retirement revived
    // instantly (CI run 43573107259: `worker retired (death evidence)` followed
    // immediately by `worker live (revived)`), which made the debug line below a
    // promise the code did not keep and turned "at most once per
    // `reviveCooldown`" into "once per death, plus one free go".
    _lastReviveAttemptAt = DateTime.now();
    _pendingReplies.clear();
    _handoffs.clear();
    if (kDebugMode) {
      final evidence = lateReply
          ? '$_timeouts consecutive missed budgets'
          : 'death evidence';
      final wait = effectiveReviveCooldown.inSeconds;
      debugPrint('[HADITH_SEARCH] worker retired ($evidence) — search answers '
          'empty until the next commit after ${wait}s, and '
          'the corpus is never scanned on main meanwhile');
    }
  }

  /// The VM told us the worker's port stream ended — it crashed, it exited, or
  /// main itself retired it a moment ago. Only the first two are news: the
  /// guard keeps `_kill`'s own inbox close from re-entering retirement (which
  /// would double-count and, worse, reset a revive clock that just started).
  void _retireOnIsolateExit(int armedFor) {
    if (_retired || _isolate == null) return;
    if (armedFor != _generation) return;
    _retire(lateReply: false);
  }

  /// Hand one book's raw text to the worker. Fire-and-forget by contract: the
  /// boot must not await the worker's decode (that is first-screen latency on
  /// the main isolate), so the returned future only exists for callers that
  /// genuinely need the worker caught up.
  ///
  /// HR-1.1: a missing ack used to set the terminal dead flag, which meant a
  /// device still decoding book 3 of 7 at the 20 s mark lost hadith search for
  /// the session. The ack now gets the dedicated [handoffGrace], and beating it
  /// only releases [whenSettled] — retirement still needs death evidence, which
  /// a `send` that throws genuinely is.
  Future<void> noteBook({
    required String slug,
    required String name,
    required String? rawEnglish,
    String? rawArabic,
    String? rawUrdu,
    Map<String, Map<String, String>> langIndices = const {},
  }) async {
    if (rawEnglish == null && rawArabic == null && rawUrdu == null) return;
    await start();
    if (_retired) return;
    final port = _toWorker;
    if (port == null) return;
    final done = Completer<void>();
    _handoffs.add(done.future);
    _handed.add(slug);
    try {
      port.send(_HadithBookPayload(
        slug: slug,
        name: name,
        rawEnglish: rawEnglish,
        rawArabic: rawArabic,
        rawUrdu: rawUrdu,
        langIndices: langIndices,
      ));
      final ack = ReceivePort();
      port.send(_HadithFlushRequest(ack.sendPort));
      unawaited(() async {
        try {
          final Object? acked = await ack.first
              .timeout(handoffGrace, onTimeout: () => null);
          if (acked == null) {
            // Slow, not dead — say so, and keep the worker.
            _noteLateHandoff('$slug ack');
          }
        } catch (e) {
          _retire(lateReply: false);
          if (kDebugMode) {
            debugPrint('[HADITH_SEARCH] handoff for $slug errored ($e)');
          }
        } finally {
          ack.close();
          if (!done.isCompleted) done.complete();
        }
      }());
    } catch (e) {
      // A send that throws is death evidence: the port is gone.
      _retire(lateReply: false);
      if (!done.isCompleted) done.complete();
      if (kDebugMode) debugPrint('[HADITH_SEARCH] handoff failed: $e');
    }
  }

  /// A hand-off that missed its grace: worth a log line and nothing more. The
  /// book is still queued in the worker's mailbox and will land; the reader's
  /// next query may simply be answered from a corpus that is one book short,
  /// which is exactly the boot behaviour HR-1 already shipped.
  /// A reply that arrives AFTER its budget: the miss it cost is refunded, and
  /// the answer is delivered. This is the other half of SLOW ≠ DEAD — HR-1 could
  /// only see lateness as a timeout, never as a late ANSWER.
  void _refundLateReply() {
    if (_timeouts > 0) _timeouts--;
    if (kDebugMode) {
      debugPrint('[HADITH_SEARCH] reply answered after its budget — late is '
          'not dead: the miss is refunded and the reader gets the results');
    }
  }

  void _noteLateHandoff(String what) {
    if (kDebugMode) {
      debugPrint('[HADITH_SEARCH] no ack for $what after '
          '${handoffGrace.inSeconds}s — still waiting, not retired');
    }
  }

  /// Fold one late-selected language into the worker's copy of one book
  /// (PASS HR-1's mirror of `HadithDatabaseService.warmLanguage`). Same pure
  /// [foldLanguageIntoRows] the main isolate just ran, same index map, so a
  /// reader who switches language mid-session searches exactly what they read.
  /// Unreachable while `HadithAvailability.newLanguageFiles` is empty — wired
  /// so the FOLD SEAM cannot open without the worker following along.
  Future<void> noteFold({
    required String slug,
    required String code,
    required Map<String, String> index,
  }) async {
    await start();
    if (_retired) return;
    final port = _toWorker;
    if (port == null) return;
    final done = Completer<void>();
    _handoffs.add(done.future);
    final ack = ReceivePort();
    try {
      port.send(_HadithFoldRequest(slug: slug, code: code, index: index));
      port.send(_HadithFlushRequest(ack.sendPort));
      unawaited(() async {
        try {
          final Object? acked = await ack.first
              .timeout(handoffGrace, onTimeout: () => null);
          if (acked == null) _noteLateHandoff('$slug/$code fold');
        } catch (e) {
          _retire(lateReply: false);
          if (kDebugMode) debugPrint('[HADITH_SEARCH] fold errored ($e)');
        } finally {
          ack.close();
          if (!done.isCompleted) done.complete();
        }
      }());
    } catch (e) {
      _retire(lateReply: false);
      ack.close();
      if (!done.isCompleted) done.complete();
      if (kDebugMode) debugPrint('[HADITH_SEARCH] fold handoff failed: $e');
    }
  }

  /// One request main is holding a wait open for. The object IS the ledger
  /// entry HR-1.1 needed: before it, every in-flight search carried a bare
  /// `await`, so a burst left N stale timeouts armed and each of them could
  /// reach for the kill switch (the ×6 pile the owner's debug log showed for one
  /// typed phrase). With a ledger, a wait that is no longer newest — because a
  /// newer commit overtook it — is answered honestly and NOT counted as a miss.
  _HadithSearchHandoff _beginSearchHandoff(int id) {
    final handoff = _HadithSearchHandoff(id);
    _pendingReplies.add(id);
    _newestSentId = id;
    return handoff;
  }

  /// Drop a ledger entry once its reply or its budget has landed, and report
  /// whether the entry that just closed was the newest one (only that one may
  /// count as a miss; older ones were superseded by definition).
  bool _endSearchHandoff(_HadithSearchHandoff handoff) {
    final i = _pendingReplies.indexOf(handoff.id);
    if (i >= 0) _pendingReplies.removeAt(i);
    return handoff.id >= _newestSentId;
  }

  /// Number of searches main is still waiting on. Pinned by the hotfix test to
  /// return to zero — a leak here is the pile-up wearing a different hat.
  int get inFlight => _pendingReplies.length;

  /// Missed budgets that were NOT superseded. Any live round trip clears them.
  void _noteMissedBudget(String why, {required bool newest}) {
    if (!newest) {
      _supersededMisses++;
      if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] $why missed its budget but a newer query '
            'had already overtaken it — discarded, not counted');
      }
      return;
    }
    _retire(lateReply: true);
  }

  /// Completes once the worker has assembled every book handed to it so far.
  /// The typing path never awaits this; the benchmark gate and a late language
  /// fold do.
  Future<void> whenSettled() async {
    if (_handoffs.isEmpty) return;
    await Future.wait(List<Future<void>>.of(_handoffs));
  }

  /// `null` means "the worker cannot answer THIS query" (not live, spawn
  /// refused, out of budget, superseded). The caller must NOT respond by
  /// running the scan itself with a corpus capture — that is the freeze HR-1
  /// removed, and it stays removed.
  ///
  /// HR-1.1 rewrote the wait. The old shape was
  ///     final received = await replyPort.first.timeout(replyTimeout, ...);
  ///     if (received is! _HadithSearchReply) { _kill(); _dead = true; ... }
  /// which folded "late" and "dead" into one branch and made the second one
  /// permanent. Now: the wait is armed through a ledger entry, a reply that
  /// closes the port is death, a budget that expires is a MISS (retirement only
  /// after [retireAfterTimeouts] in a row, and not at all when a newer query
  /// overtook this one), and a late reply still answers the reader.
  Future<List<List<LocalSearchResult>>?> search(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    // HR-1.1 requirement 2, in ONE line: the next search COMMIT is where a
    // retired worker is revived, because `start()` is the single-flight,
    // rate-limited door (`_reviveWindowOpen()` refuses a second attempt inside
    // `reviveCooldown`, and it never runs a scan here as a fallback). The service
    // still OWNS the re-hand of the corpus, so "revive" here means "get a live
    // port back", never "answer from main's memory".
    if (_toWorker == null || _retired) await start();
    final port = _toWorker;
    if (port == null || _retired || queries.isEmpty) return null;
    final id = ++_requestSeq;
    final handoff = _beginSearchHandoff(id);
    final replyPort = ReceivePort();
    // A cold worker may be answering for the first time, i.e. answering BEHIND
    // the boot hand-offs, so it gets the longer budget. Measured, not assumed.
    final budget = currentReplyBudget;
    if (kDebugMode) {
      final warmness = _everAnswered ? 'warm' : 'first after a spawn';
      debugPrint('[HADITH_SEARCH] scan request $id, budget '
          '${budget.inSeconds}s ($warmness)');
    }
    try {
      port.send(_HadithSearchRequest(
        id: id,
        queries: List<String>.unmodifiable(queries),
        maxPerQuery: maxPerQuery,
        replyTo: replyPort.sendPort,
      ));
    } catch (e) {
      // Death evidence — the port is gone, this is not a slow reply.
      replyPort.close();
      _noteDeadPort(handoff, 'request refused: $e');
      return null;
    }
    try {
      final Object? received = await replyPort.first.timeout(
        budget,
        onTimeout: () {
          // A budget that expires must let go of the ledger and the timeout
          // bookkeeping in the same breath — an un-cancellable watchdog is what
          // left six stale awaits armed per typed phrase in HR-1. ORDER
          // MATTERS: the ledger closes first and the hand-off is marked done, so
          // a reply that lands a heartbeat later cannot be misread as a death.
          // (No `replyPort.close()` here: `Stream.first` already closed it when
          // it gave up, and the `finally` is the belt for every other path.)
          final wasNewest = _endSearchHandoff(handoff);
          handoff.abandon();
          _noteMissedBudget('query $id', newest: wasNewest);
          return const _HadithSearchTimeout();
        },
      );
      if (received is! _HadithSearchReply) {
        // Three honest cases, and only the second one is death:
        //   * the budget expired — `onTimeout` has already counted the miss;
        //   * `received` is null because the REPLY PORT CLOSED WITHOUT EVER
        //     DELIVERING: the isolate died mid-request. Retire on that,
        //     immediately, because it is proof and not a stopwatch;
        //   * a message the protocol does not recognise: one miss on the
        //     newest request, no verdict.
        if (received is _HadithSearchTimeout) return null;
        if (received == null) {
          _noteDeadPort(handoff, 'reply port for $id closed without an answer');
          return null;
        }
        _noteMissedBudget('unrecognised reply to $id',
            newest: handoff.id >= _newestSentId);
        return null;
      }
      // SLOW ≠ DEAD, the last mile: if our own budget had already expired and
      // this answer arrived anyway, the reply is LATE, not ABSENT — that fact
      // belongs to the hand-off (which is what timed out), not to the immutable
      // message the isolate sent us (CI: `const_constructor_with_non_final_field`
      // the moment I tried to stamp it there). Refund the miss it cost and let the
      // reader have the result: shown an answer 46 s in is not a dead search.
      if (handoff.done) _refundLateReply();
      handoff.markSuccess();
      _endSearchHandoff(handoff);
      // Any answered query pays off every timeout before it: the counter exists
      // to spot a worker that never answers, not to score one slow moment.
      _timeouts = 0;
      _everAnswered = true;
      if (kDebugMode) {
        // THE MEASUREMENT the next device run needs, printed on the only side
        // that can print: the worker isolate has no Flutter binding. One line
        // per query with the corpus size, so a real low-end phone replaces the
        // 45 s budget with data instead of a second guess.
        final elapsedMs = received.elapsedUs / 1000.0;
        debugPrint('[HADITH_SEARCH] scan $id answered in '
            '${elapsedMs.toStringAsFixed(1)}ms over ${received.corpusRows} '
            'corpus rows (budget ${budget.inSeconds}s)');
      }
      return received.superseded ? null : received.batches;
    } catch (e) {
      // A throw from the wait itself is only ever the reply port's stream
      // ending (a `StateError` from `first` on a closed port) or something the
      // protocol never produced. The first is death evidence, the second is
      // not, so the branch is chosen by WHETHER the hand-off is still open —
      // never by catching a timeout, which the `onTimeout` above already owns.
      if (!handoff.done && !handoff.answered) {
        _noteDeadPort(handoff, 'wait for $id threw: $e');
      } else if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] wait for $id ended late ($e) — answered '
            'empty, worker untouched: a failed wait is not death evidence');
      }
      return null;
    } finally {
      // The ledger ALWAYS closes here: one in-flight request per commit, never
      // a pile. A stale entry surviving this point is precisely the ×6 the
      // device log showed, and it is why the hand-off object exists.
      if (!handoff.done) handoff.abandon();
      _endSearchHandoff(handoff);
      try {
        replyPort.close();
      } catch (_) {
        // Already closed by the budget branch — closing twice on a retired
        // hand-off must not turn a search miss into a crash (P3-7 asks every
        // empty catch in lib to say why; that is why).
      }
    }
  }

  /// The one place "the port is gone" becomes a retirement. It also closes the
  /// ledger entry, so a dead worker cannot leave the hand-off list holding an
  /// id nobody will ever answer.
  void _noteDeadPort(_HadithSearchHandoff handoff, String why) {
    handoff.abandon();
    _endSearchHandoff(handoff);
    _retire(lateReply: false);
    if (kDebugMode) debugPrint('[HADITH_SEARCH] $why');
  }

  /// Retire the worker for good: tests and process teardown. HR-1.1 keeps the
  /// kill switch, but the flag it sets is now a state the next commit can leave.
  /// The kill switch. HR-1.1 keeps it — a worker that genuinely died must stop
  /// being talked to — but what follows it is no longer "forever": `_retired`
  /// is cleared by the next [start] that finds the revive window open, and the
  /// fresh isolate re-reads the hand-off list from scratch (`_corpusStale`).
  void _kill() {
    _toWorker = null;
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    try {
      _inbox?.close();
    } catch (_) {
      // Already closed, or never opened: `_kill` runs on paths where the inbox
      // may not exist yet, and a failure while retiring a dead worker must not
      // replace a search miss with a crash. Deliberately silent, deliberately
      // here — `test/core/pass_p3_polish_test.dart` (P3-7) requires every empty
      // catch in lib to say why, and this is the saying.
    }
    _inbox = null;
  }

  /// Pretend nothing has ever been answered, so the NEXT wait runs on the cold
  /// budget. Exists because "the first query after a spawn gets a bigger
  /// budget" is a rule the app only exercises once per process, and a test must
  /// be able to exercise it more than once to prove it is a rule and not a fluke.
  @visibleForTesting
  void forceCold() => _everAnswered = false;

  /// The immediate-retirement door, for tests. It is the SAME `_retire` the
  /// death-evidence branches call (refused spawn, throw on send, reply port
  /// closed, isolate exited) — not a parallel implementation — so a test can
  /// prove "death retires at once, and the cooldown rate-limits coming back"
  /// without waiting out two 45 s budgets or killing an isolate by hand.
  @visibleForTesting
  void noteDeathForTest(String why) {
    if (kDebugMode) debugPrint('[HADITH_SEARCH] test-driven death evidence: $why');
    _retire(lateReply: false);
  }

  /// Tests retire the worker between cases; app code keeps it for the process.
  /// The HR-1.1 knobs survive on purpose — a test that retired a worker must be
  /// able to watch it come back on the same patience budget it timed out on.
  @visibleForTesting
  void shutdownForTest() {
    _kill();
    _retired = false;
    _timeouts = 0;
    _supersededMisses = 0;
    _pendingReplies.clear();
    _newestSentId = 0;
    _corpusStale = false;
    _handoffs.clear();
    _handed.clear();
  }
}

/// The sentinel `search`'s wait returns when its budget expired, so the code
/// after the `await` can tell "late" (keep the worker) from "the port died"
/// (retire it) without a second flag on the hand-off.
class _HadithSearchTimeout {
  const _HadithSearchTimeout();
}

/// One in-flight search from main's side: the request id, and whether it is
/// still open. The ledger (`HadithSearchWorker._pendingReplies`) holds the ids;
/// this object is what lets a superseded or expired wait close EVERYTHING it
/// owns — ledger entry, port, timeout bookkeeping — in one move. It holds no
/// rows and no corpus handle, so the HR-1 capture ban is untouched by it.
class _HadithSearchHandoff {
  _HadithSearchHandoff(this.id);

  final int id;

  /// True once the wait is over, by reply, by budget, or by abandonment.
  bool done = false;

  /// True only if a reply was actually delivered. The `finally` reads this
  /// before deciding whether an error thrown by the wait is evidence at all.
  bool answered = false;

  /// Close the wait as "no answer, and no news either". Called from the budget
  /// branch, the death branches and the `finally`, so it must be idempotent.
  void abandon() {
    if (done) return;
    done = true;
    answered = false;
  }

  /// Close the wait with an answer. Kept separate from a bare `done = true`
  /// because the two differ in what the `finally` may conclude: a delivered
  /// reply is NOT a dead port, and conflating them is how a slow-but-answered
  /// query would retire the worker again.
  void markSuccess() {
    done = true;
    answered = true;
  }
}

/// The worker's entry point: top-level (isolate-safe), no Flutter binding, no
/// rootBundle, no providers. It decodes what it is handed and answers.
void _hadithSearchWorkerEntry(SendPort mainPort) {
  final inbox = ReceivePort();
  mainPort.send(inbox.sendPort);

  // The corpus, owned HERE. Nothing on this side is reachable from main.
  final books = <String, List<LocalHadith>>{};
  // HOTFIX HR-1.3 — the folded mirror of `books`, slug by slug.
  //
  // `books` is why a scan was possible; this is why a scan is POSSIBLE IN TIME.
  // The pre-fix loop asked `SearchNormalizer.contains(row.text, q)`, which
  // folds the row, per field, per query, so one hadith of 1,400 chars was
  // re-normalised four times per keystroke, 36,390 rows deep — the owner's
  // device answered that with `scan request N, budget 90s (first after a
  // spawn)` six times and zero `answered` lines. Here the fold is paid ONCE per
  // row at settle (below) and the keystroke path is `indexOf` on cached
  // strings: same hits, same order, same scores, because the strings it matches
  // are exactly the ones the old loop folded.
  //
  // The cost is memory, and it is DISCLOSED rather than waved at: one extra
  // String per searched field per row, held in the worker. The pass report
  // quotes the measured number (build ms and folded chars) from the log line
  // this branch prints, not an estimate.
  final folded = <String, List<FoldedHadith>>{};
  var newestRequestId = 0;
  // HR-1.1 telemetry, kept as an INT so the row count can ride the reply back to
  // main's debugPrint. Maintained incrementally (replace, not recount) because
  // a full walk of the corpus on every hand-off is work nobody asked for.
  var rows = 0;

  // `Object?`, NOT the inferred `dynamic`: with `strict-casts: true`
  // (analysis_options.yaml) an implicit downcast from dynamic is an ERROR, and
  // the field accesses below are exactly that. Declaring the parameter as
  // Object? makes each `is` test a real promotion instead.
  inbox.listen((Object? message) {
    if (message is _HadithBookPayload) {
      final assembled = assembleHadithBook(
        englishData: message.rawEnglish == null
            ? null
            : HadithDatabaseService.decodeHadithAsset(message.rawEnglish!),
        arabicData: message.rawArabic == null
            ? null
            : HadithDatabaseService.decodeHadithAsset(message.rawArabic!),
        urduData: message.rawUrdu == null
            ? null
            : HadithDatabaseService.decodeHadithAsset(message.rawUrdu!),
        langIndices: message.langIndices,
        slug: message.slug,
        name: message.name,
      );
      if (assembled != null) {
        rows -= books[message.slug]?.length ?? 0;
        books[message.slug] = assembled.hadiths;
        rows += assembled.hadiths.length;
        // A mirror of rows that no longer exist is not a cache, it is a wrong
        // answer with good timing. Drop it; the next settle rebuilds.
        folded.remove(message.slug);
      }
      return;
    }
    if (message is _HadithFoldRequest) {
      final rows0 = books[message.slug];
      if (rows0 != null && rows0.isNotEmpty) {
        books[message.slug] = foldLanguageIntoRows(
          rows: rows0,
          code: message.code,
          index: message.index,
        ).rows;
        // `foldLanguageIntoRows` makes NEW row objects with NEW text, so the
        // mirror of this slug is describing a corpus that has been replaced.
        // Index-by-position is only honest while the rows are the rows; this is
        // the line that keeps that promise.
        folded.remove(message.slug);
      }
      return;
    }
    if (message is _HadithFlushRequest) {
      // THE settle point: every book main has is in `books` now, so this is the
      // one moment the whole corpus can be folded once — off the main isolate,
      // behind the boot, and BEFORE the reply below, because main reads that
      // reply as "the corpus is ready" and a query that arrived first would pay
      // the fold on the typing path again. One-time, not per keystroke, and
      // never on a keystroke at all.
      final sw = Stopwatch()..start();
      // Incremental on purpose: `folded.remove(slug)` is what a replaced book
      // leaves behind, so a slug that is already mirrored is already correct and
      // must not be folded again — main may well settle twice in one boot, and
      // "once per row" has to survive that.
      var mirrored = 0;
      for (final entry in books.entries) {
        if (folded.containsKey(entry.key)) continue;
        folded[entry.key] = foldHadithBook(entry.value);
        mirrored++;
      }
      sw.stop();
      if (kDebugMode) {
        // The numbers the report quotes, measured on the device in the mode the
        // device runs: a one-time cost, and the owner is entitled to its size.
        var foldedChars = 0;
        for (final mirror in folded.values) {
          for (final row in mirror) {
            foldedChars += row.foldedChars;
          }
        }
        final usPerRow = rows == 0 ? 0 : sw.elapsedMicroseconds ~/ rows;
        debugPrint('[HADITH_SEARCH] corpus folded at settle: $mirrored books '
            'new / ${folded.length} mirrored, $rows rows, '
            '${sw.elapsedMilliseconds}ms (${usPerRow}us/row), '
            '$foldedChars folded chars ~'
            '${(foldedChars * 2 / (1024 * 1024)).toStringAsFixed(1)}MB held');
      }
      message.replyTo.send(true);
      return;
    }
    if (message is _HadithSearchRequest) {
      if (message.id < newestRequestId) {
        // HR-1 supersession: a newer query is already queued or running, so
        // this one is answered WITHOUT scanning — the corpus walk for a query
        // nobody will paint is exactly the waste the freeze was made of.
        // HR-1.1 adds the other half: main must not count this honest,
        // instant reply as a missed budget either (see the `_pendingReplies`
        // ledger), because a burst of keystrokes used to leave one stale wait
        // per character holding the kill switch.
        message.replyTo.send(const _HadithSearchReply(true, []));
        return;
      }
      newestRequestId = message.id;
      final sw = Stopwatch()..start();
      // The keystroke path: no fold in this call, only `indexOf` on the
      // strings built above. `folded` may lag `books` for one book mid-boot;
      // the scan answers that by folding that book itself, which is correct and
      // bounded, and never happens for a settled corpus.
      final batches = scanFoldedHadithCorpus(
        books,
        folded,
        message.queries,
        maxPerQuery: message.maxPerQuery,
      );
      sw.stop();
      message.replyTo
          .send(_HadithSearchReply(false, batches,
              elapsedUs: sw.elapsedMicroseconds, corpusRows: rows));
      return;
    }
  }, onDone: () {
    // main closed our inbox — it retired us. Leaving the isolate alive with
    // nobody to talk to is a leak, and exiting here is also what makes main's
    // next "the port died" observation honest rather than inferred.
    Isolate.exit();
  });
}
