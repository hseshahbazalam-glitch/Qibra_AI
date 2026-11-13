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
class _HadithSearchReply {
  const _HadithSearchReply(this.superseded, this.batches);

  final bool superseded;
  final List<List<LocalSearchResult>> batches;
}

class HadithSearchWorker {
  HadithSearchWorker();

  /// The app has exactly one hadith corpus, so exactly one worker owns it.
  static final HadithSearchWorker instance = HadithSearchWorker._shared();

  HadithSearchWorker._shared();

  /// How long one reply may take before the worker is considered wedged. A
  /// whole-corpus scan of 36k rows is a few hundred ms on a mid phone; 20 s is
  /// generosity, and the timeout is what keeps a wedged worker from hanging the
  /// search stream forever.
  static const Duration replyTimeout = Duration(seconds: 20);

  /// How long the handover port may take to appear before the spawn counts as
  /// refused. Boot must never wait on the worker beyond this.
  static const Duration handshakeTimeout = Duration(seconds: 5);

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _toWorker;
  Future<void>? _starting;
  int _requestSeq = 0;
  bool _dead = false;
  final List<Future<void>> _handoffs = [];

  /// Book names handed over. Deliberately a Set of Strings and nothing more:
  /// a stray debug call must not be able to grow a second corpus reference on
  /// the main side.
  final Set<String> _handed = <String>{};

  bool get isLive => _toWorker != null && !_dead;

  /// Slugs the worker has been asked to hold (not a claim that it has decoded
  /// them yet — [whenSettled] is the claim).
  List<String> get handedBooks => _handed.toList(growable: false);

  /// Spawn (idempotent, single-flight) and wait for the worker's command port.
  /// Never throws: a platform that refuses the spawn marks the worker dead and
  /// the service then answers honestly EMPTY — it must never copy the corpus
  /// instead, because that copy is the freeze this pass exists to remove.
  Future<void> start() async {
    if (_dead) return;
    if (_toWorker != null) return;
    final pendingStart = _starting;
    if (pendingStart != null) {
      await pendingStart;
      return;
    }
    final completer = Completer<void>();
    _starting = completer.future;
    final inbox = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
        _hadithSearchWorkerEntry,
        inbox.sendPort,
        debugName: 'hadith-search-worker',
      );
      // Typed `Object?` on purpose: `ReceivePort` delivers `dynamic`, and under
      // this repo's `strict-casts: true` handing that straight to a `SendPort`
      // field is an error, not a lint.
      final Object? announced = await inbox.first
          .timeout(handshakeTimeout, onTimeout: () => null);
      if (announced is! SendPort) {
        isolate.kill(priority: Isolate.immediate);
        throw StateError('worker never announced its port');
      }
      _toWorker = announced;
      _isolate = isolate;
      _inbox = inbox;
      if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] worker live — search answers off-main, '
            'corpus owned there');
      }
    } catch (e) {
      _dead = true;
      inbox.close();
      if (kDebugMode) {
        debugPrint('[HADITH_SEARCH] spawn refused ($e) — hadith search '
            'answers empty rather than copying the corpus on the main isolate');
      }
    } finally {
      _starting = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Hand one book's raw text to the worker. Fire-and-forget by contract: the
  /// boot must not await the worker's decode (that is first-screen latency on
  /// the main isolate), so the returned future only exists for callers that
  /// genuinely need the worker caught up.
  Future<void> noteBook({
    required String slug,
    required String name,
    required String? rawEnglish,
    String? rawArabic,
    String? rawUrdu,
    Map<String, Map<String, String>> langIndices = const {},
  }) async {
    if (_dead) return;
    if (rawEnglish == null && rawArabic == null && rawUrdu == null) return;
    await start();
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
          await ack.first.timeout(replyTimeout);
        } catch (e) {
          _dead = true;
          if (kDebugMode) {
            debugPrint('[HADITH_SEARCH] no ack for $slug ($e)');
          }
        } finally {
          ack.close();
          if (!done.isCompleted) done.complete();
        }
      }());
    } catch (e) {
      _dead = true;
      if (!done.isCompleted) done.complete();
      if (kDebugMode) debugPrint('[HADITH_SEARCH] handoff failed: $e');
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
    if (_dead) return;
    await start();
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
          await ack.first.timeout(replyTimeout);
        } catch (e) {
          _dead = true;
          if (kDebugMode) debugPrint('[HADITH_SEARCH] no fold ack ($e)');
        } finally {
          ack.close();
          if (!done.isCompleted) done.complete();
        }
      }());
    } catch (e) {
      _dead = true;
      ack.close();
      if (!done.isCompleted) done.complete();
      if (kDebugMode) debugPrint('[HADITH_SEARCH] fold handoff failed: $e');
    }
  }

  /// Completes once the worker has assembled every book handed to it so far.
  /// The typing path never awaits this; the benchmark gate and a late language
  /// fold do.
  Future<void> whenSettled() async {
    if (_handoffs.isEmpty) return;
    await Future.wait(List<Future<void>>.of(_handoffs));
  }

  /// `null` means "the worker cannot answer this query" (not live, spawn
  /// refused, timed out, wedged, or superseded). The caller must NOT respond by
  /// running the scan itself with a corpus capture — that is the bug.
  Future<List<List<LocalSearchResult>>?> search(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    final port = _toWorker;
    if (port == null || _dead || queries.isEmpty) return null;
    final id = ++_requestSeq;
    final replyPort = ReceivePort();
    try {
      port.send(_HadithSearchRequest(
        id: id,
        queries: List<String>.unmodifiable(queries),
        maxPerQuery: maxPerQuery,
        replyTo: replyPort.sendPort,
      ));
    } catch (e) {
      replyPort.close();
      _dead = true;
      if (kDebugMode) debugPrint('[HADITH_SEARCH] request refused: $e');
      return null;
    }
    var portClosed = false;
    try {
      final Object? received = await replyPort.first.timeout(
        replyTimeout,
        onTimeout: () => null,
      );
      if (received is! _HadithSearchReply) {
        // Timeout or a message we do not understand: the worker is no longer
        // trustworthy for this session. Kill it, stay dead, answer empty — a
        // respawn per keystroke would be its own jank.
        _kill();
        _dead = true;
        if (kDebugMode) debugPrint('[HADITH_SEARCH] worker unresponsive — '
            'retired for this session');
        return null;
      }
      return received.superseded ? null : received.batches;
    } catch (e) {
      if (!portClosed) {
        portClosed = true;
        replyPort.close();
      }
      return null;
    } finally {
      if (!portClosed) replyPort.close();
    }
  }

  void _kill() {
    _toWorker = null;
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    try {
      _inbox?.close();
    } catch (_) {}
    _inbox = null;
  }

  /// Tests retire the worker between cases; app code keeps it for the process.
  @visibleForTesting
  void shutdownForTest() {
    _kill();
    _dead = false;
    _handoffs.clear();
    _handed.clear();
  }
}

/// The worker's entry point: top-level (isolate-safe), no Flutter binding, no
/// rootBundle, no providers. It decodes what it is handed and answers.
void _hadithSearchWorkerEntry(SendPort mainPort) {
  final inbox = ReceivePort();
  mainPort.send(inbox.sendPort);

  // The corpus, owned HERE. Nothing on this side is reachable from main.
  final books = <String, List<LocalHadith>>{};
  var newestRequestId = 0;

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
      if (assembled != null) books[message.slug] = assembled.hadiths;
      return;
    }
    if (message is _HadithFoldRequest) {
      final rows = books[message.slug];
      if (rows != null && rows.isNotEmpty) {
        books[message.slug] = foldLanguageIntoRows(
          rows: rows,
          code: message.code,
          index: message.index,
        ).rows;
      }
      return;
    }
    if (message is _HadithFlushRequest) {
      message.replyTo.send(true);
      return;
    }
    if (message is _HadithSearchRequest) {
      if (message.id < newestRequestId) {
        // HR-1 supersession: a newer query is already queued or running, so
        // this one is answered WITHOUT scanning — the corpus walk for a query
        // nobody will paint is exactly the waste the freeze was made of.
        message.replyTo.send(const _HadithSearchReply(true, []));
        return;
      }
      newestRequestId = message.id;
      final batches = scanHadithCorpus(
        books,
        message.queries,
        maxPerQuery: message.maxPerQuery,
      );
      message.replyTo.send(_HadithSearchReply(false, batches));
      return;
    }
  });
}
