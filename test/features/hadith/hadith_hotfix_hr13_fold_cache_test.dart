// lib/test/features/hadith/hadith_hotfix_hr13_fold_cache_test.dart
//
// ============================================================================
// HOTFIX HR-1.3 — the corpus fold must be paid ONCE per row, not once per row
// per query per scan. (device-red #3: the scan never completes on a real phone)
// ============================================================================
//
// DEVICE EVIDENCE (owner, CPH2573, debug, tip `83d0220`), verbatim: six
//   [HADITH_SEARCH] scan request N, budget 90s (first after a spawn)
// lines — ALL of them saying "first after a spawn" — and ZERO
//   [HADITH_SEARCH] scan N answered in Xms over ... corpus rows
// lines across ~60 s of typing. `firstReplyBudget` only stays in force while
// nothing has ever been answered, so six "first" lines is the machine saying:
// no reply was ever processed. HR-1.1 held (no "retired for this session") and
// typing stayed smooth, so this is NOT a worker-availability bug: the scan
// does not finish in time.
//
// WHY CI WAS GREEN (the gate lied, and the report repeated its conclusion):
// the HR-1 benchmark's synthetic rows carry ~20-25-char topic strings. Real
// hadith texts are 300-2,000 chars (measured below, from the shipped bundle).
// `scanHadithCorpus` asks `SearchNormalizer.contains(rawText, q)` per row per
// field, and `SearchNormalizer.fold` rebuilds the folded text — char by char,
// with a per-character index map — EVERY TIME. Cost is therefore a function of
// TEXT LENGTH, and the benchmark under-modelled the real corpus by two orders
// of magnitude on the fields that matter.
//
// THE SECOND HALF, WHICH THE BRIEF ONLY IMPLIED: the fold is not linear in
// text length. `SearchNormalizer.append` decided "does the buffer already end
// in a space?" with `foldedBuf.toString().codeUnitAt(len - 1)` — a FRESH COPY
// OF THE WHOLE PARTIALLY-BUILT STRING, once per whitespace character. Real
// prose has a space every 5-6 chars, so one 1,400-char row paid ~240 copies
// averaging 700 chars to be folded once: ~35x the work the fold itself needs,
// x 4 fields x 36,390 rows x every keystroke. That is the "minutes".
//
// CI ROUNDS FOR THIS FILE (red evidence; the full table lives in
// docs/HADITH_HR_PASS_REPORT.md under "HR-1.3"):
//   `73cdadd`  run 43585154315  RED on Analyze only, and the failure was MINE:
//              a `$rowsUnderGate` interpolation in a test title naming an
//              identifier that does not exist (the const is `_rowsUnderGate`).
//              No measurement produced: the suite never ran.
//   `f1546a8`  run 43585606786  GREEN. The 1,200-row cost gate PASSED at that
//              moment — reported because it is the finding that matters: a
//              stopwatch on a slice of the corpus is not a proof, and CI's
//              runner is not a CPH2573.
//   `54f5de4`  run 43586298265  RED as designed: `695 tests passed, 6 failed`,
//              `git diff --stat` proving the only changed file is this one, so
//              every failure is a gate of HR-1.3 and no existing gate moved.
//              Six, not five: the five designed reds (whole-corpus fold bound,
//              fold-growth ratio, the three source pins) plus the 1,200-row p95
//              gate, which at HEAD sits ON the 500 ms bound and so flips with
//              the runner's mood. That is the honest state of the pre-fix code:
//              a real-corpus scan is not "minutes" on a 4-core x86 in a warm VM
//              and it is minutes on the owner's phone, and the only reason the
//              first of those is even arguable is that CI's hadith benchmarks
//              never carried real text. After the fix the gate has ~30x of
//              margin for the same rows; at HEAD it had noise.
//
// So the red is aimed at the two things that scale honestly: the fold's own
// cost (whole corpus, and a machine-independent growth ratio) and the scan
// path's source (no fold of corpus text anywhere in it, mirror built at settle
// only). A timing gate can be out-fiddled by a smaller fixture — that is
// exactly how HR-1 ended up green and the phone red.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

import '../../support/source_guards.dart';

const _servicePath =
    'lib/features/hadith/data/services/hadith_database_service.dart';
const _workerPath =
    'lib/features/hadith/data/services/hadith_search_worker.dart';

/// The signature HR-1.3 must add (source pins key on the exact text).
const _foldedScanSignature =
    'List<List<LocalSearchResult>> scanFoldedHadithCorpus(';
const _rawScanSignature = 'List<List<LocalSearchResult>> scanHadithCorpus(';

/// The shipped English file of one real collection. Not a fixture: the corpus
/// the phone actually scans.
const _realBookSlug = 'bukhari';
const _realBookDir = 'assets/data/hadith/$_realBookSlug';

/// Rows under the scan gate. 1,200 of the real 7,563 in this file — enough
/// that the fold cost is unmissable, small enough that a RED run of this test
/// costs seconds instead of the minutes the device pays.
const _rowsUnderGate = 1200;

/// The scan's own bound, in ms, for one query over the rows under the gate.
/// 500 ms is the brief's end-to-end bound.
const _scanBoundMs = 500.0;

/// One pass of the fold over the ENTIRE shipped corpus must fit in this (ms).
/// Folding 15.4 M linear chars is a fraction of it; the per-whitespace
/// `buf.toString()` guard is not.
const _wholeCorpusFoldBoundMs = 2000.0;

/// Fold-time growth between two texts 8x apart: a linear fold grows by ~8, the
/// quadratic guard grows by ~8 x 8. A ratio, so runner speed cannot flake it.
const _foldGrowthBound = 12.0;
const _foldSmallChars = 20000;
const _foldBigChars = 160000;

/// The real rows, assembled by the app's own assembler from the real bytes, so
/// `LocalHadith` here has exactly the fields the scan reads (english + arabic +
/// urdu joined on the pair key, chapter names from the shipped section table).
Map<String, List<LocalHadith>> _realCorpus({int rows = _rowsUnderGate}) {
  Map<String, dynamic> read(String name) =>
      jsonDecode(File('$_realBookDir/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  final english = HadithDatabaseService.decodeHadithAsset(
      File('$_realBookDir/english.json').readAsStringSync());
  final assembled = assembleHadithBook(
    englishData: english,
    arabicData: read('arabic'),
    urduData: read('urdu'),
    langIndices: const {},
    slug: _realBookSlug,
    name: 'Sahih al-Bukhari',
  );
  expect(assembled, isNotNull,
      reason: 'the real bundle must assemble — if this is red the fixture is '
          'wrong, not the scan');
  final all = assembled!.hadiths;
  expect(all.length, greaterThan(rows),
      reason: 'the gate needs $rows real rows and the bundle has '
          '${all.length}');
  return {_realBookSlug: all.sublist(0, rows)};
}

/// Chars per row per searched field, measured on the corpus under test. The
/// number that makes the benchmark's lie arithmetic instead of opinion.
({int fields, int chars, int rows}) _measureCorpus(
    Map<String, List<LocalHadith>> corpus) {
  var chars = 0;
  var rows = 0;
  for (final list in corpus.values) {
    for (final h in list) {
      rows++;
      chars += h.textEnglish.length + h.textArabic.length + h.textUrdu.length +
          h.chapterName.length;
    }
  }
  return (fields: 4, chars: chars, rows: rows);
}

Map<String, List<LocalHadith>>? _allRealCorpusCache;

/// All 7 shipped books, english only, assembled once for the whole file: the
/// corpus the phone walks. (arabic/urdu are the same order of magnitude, and
/// the fold-cost finding is per char, so english carries the gate.)
Map<String, List<LocalHadith>> _allRealCorpus() {
  final cached = _allRealCorpusCache;
  if (cached != null) return cached;
  final out = <String, List<LocalHadith>>{};
  for (final slug in const [
    'bukhari', 'muslim', 'nasai', 'abudawud', 'tirmidhi', 'ibnmajah', 'malik',
  ]) {
    final assembled = assembleHadithBook(
      englishData: HadithDatabaseService.decodeHadithAsset(
          File('assets/data/hadith/$slug/english.json').readAsStringSync()),
      arabicData: null,
      urduData: null,
      langIndices: const {},
      slug: slug,
      name: slug,
    );
    if (assembled != null) out[slug] = assembled.hadiths;
  }
  _allRealCorpusCache = out;
  return out;
}

int _p95Us(List<int> xs) {
  final sorted = [...xs]..sort();
  final i = (sorted.length * 0.95).ceil() - 1;
  return sorted[i < 0 ? 0 : (i >= sorted.length ? sorted.length - 1 : i)];
}

String _read(String path) => File(path).readAsStringSync();

/// The method from its signature to its closing brace — same contract as
/// `hadith_pass_hr1_test`'s helper: anchored on the OPENING brace, because a
/// wrapped parameter list ends in a sequence that looks like the body's end.
String _methodBody(String code, String signatureStart) {
  final start = code.indexOf(signatureStart);
  if (start < 0) return '';
  final lineStart = code.lastIndexOf('\n', start) + 1;
  final closer = '\n${' ' * (start - lineStart)}}';
  final params = code.indexOf(')', start);
  final open = code.indexOf('{', params);
  if (params < 0 || open < 0) return '';
  final end = code.indexOf(closer, open);
  return end < 0 ? '' : code.substring(start, end);
}

/// One `if (message is X) { ... }` branch of the worker inbox listener, from
/// its test to the next one. Branch-level pins are what keep a build-at-settle
/// requirement from being satisfied by a build-somewhere-else.
String _workerBranch(String entry, String marker) {
  final start = entry.indexOf(marker);
  if (start < 0) return '';
  final next = entry.indexOf('if (message is', start + marker.length);
  return next < 0 ? entry.substring(start) : entry.substring(start, next);
}

/// Real prose from the shipped bundle, concatenated to [targetChars], so the
/// whitespace density is the corpus's own (~1 space per 5-6 chars) and not a
/// fixture's. This is the input the fold is timed on.
String _realTextAtLeast(int targetChars) {
  final buf = StringBuffer();
  for (final rows in _allRealCorpus().values) {
    for (final h in rows) {
      buf
        ..write(h.textEnglish)
        ..write(' ');
      if (buf.length >= targetChars) return buf.toString();
    }
  }
  throw StateError('the shipped corpus is smaller than $targetChars chars');
}

/// The comparable identity of a result list: which row, at what score, matched
/// in which field. Deliberately NOT `identical`: the fix must hand back the
/// same rows (it does — the mirror never replaces them) but what the READER
/// sees is hits, order and scores, and that is the promise being pinned.
List<(int, String, double, String)> _signature(List<LocalSearchResult> hits) =>
    [
      for (final h in hits)
        (h.hadith.hadithNumber, h.hadith.bookSlug, h.relevance, h.matchedIn),
    ];

void main() {
  group('HR-1.3 the fold must be paid once per row, not once per query per '
      'scan', () {
    /// THE COST GATE. Reads no synthetic text at all: the corpus is the shipped
    /// bundle, the queries are the owner's, and the bound is the brief's.
    test('one scan of ${_rowsUnderGate} REAL rows is bounded, not "minutes"',
        () {
      final corpus = _realCorpus();
      final size = _measureCorpus(corpus);
      final perRow = (size.chars / size.rows).round();
      // Printed for the report, because the finding IS a number.
      debugPrint('[HR13_MEASURE] rows=${size.rows} searchedChars=${size.chars} '
          'meanCharsPerRow=$perRow fields=${size.fields}');

      // The queries are the ones the device typed, and the ones a reader
      // types: short terms against long text — the worst case for a per-row
      // fold, because the fold is paid in full whether or not anything
      // matches.
      const queries = ['namaz ka tarika', 'patience', 'prayer', 'masjid'];

      final scans = <int>[];
      for (var i = 0; i < queries.length; i++) {
        final sw = Stopwatch()..start();
        final batches =
            scanHadithCorpus(corpus, [queries[i]], maxPerQuery: 50);
        sw.stop();
        scans.add(sw.elapsedMicroseconds);
        debugPrint('[HR13_MEASURE] scan ${i + 1} "${queries[i]}" cost '
            '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)}ms and '
            'returned ${batches.single.length} hits over ${size.rows} rows');
      }
      final p95 = _p95Us(scans) / 1000.0;
      debugPrint('[HR13_MEASURE] p95 scan over ${scans.length} queries = '
          '${p95.toStringAsFixed(1)}ms (bound ${_scanBoundMs}ms)');

      expect(p95, lessThan(_scanBoundMs),
          reason: 'a real corpus scan of ${size.rows} rows (mean $perRow chars '
              'of searched text per row) took ${p95.toStringAsFixed(0)} ms at '
              'p95. The device paid this on EVERY keystroke while the UI '
              'waited '
              '90 s for a reply that never came. The bound only holds once the '
              'fold is cached per row at hand-off (the fix); the fold-per-scan '
              'shape cannot meet it at any row count that matters.');
    });

    /// The arithmetic of why the shipped benchmark could not see this, kept as
    /// a witness so nobody re-derives the conclusion from short synthetic text.
    test('the HR-1 synthetic fixture is lighter per row than reality — '
        'measured', () {
      final real = _measureCorpus(_realCorpus(rows: 400));
      final realPerRow = real.chars / real.rows;
      // The exact generator `hadith_pass_hr1_test` uses (that file's own copy
      // is private, so the shape is restated here rather than edited there):
      // one 20-word topic sentence per row, english only.
      const topic = 'namaz ka tarika';
      const fixtureText = 'Volume 1, Book 1, Hadith 1: $topic — the Prophet '
          '(peace be upon him) said, and the chain is complete for row 1 of '
          'bukhari.';
      final syntheticPerRow = fixtureText.length;
      debugPrint('[HR13_MEASURE] real mean searched chars/row = '
          '${realPerRow.toStringAsFixed(0)}; HR-1 synthetic english/row = '
          '$syntheticPerRow; ratio = '
          '${(realPerRow / syntheticPerRow).toStringAsFixed(1)}x');
      expect(realPerRow / syntheticPerRow, greaterThan(3.0),
          reason: 'the benchmark that concluded "no indexed pre-normalisation '
              'pass is indicated" scanned rows $realPerRow / $syntheticPerRow '
              'times shorter than this. Fold cost scales with text length, so '
              'its timing was off by the same factor and more (the fold is '
              'also quadratic in length inside SearchNormalizer.append). If '
              'this ratio ever drops, the benchmark has gone short-text again '
              'and the gate is blind.');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // THE FOLD ITSELF. The scan's cost is fold(row) x fields x queries, so the
  // device number is only explained once the fold's OWN cost is on the record.
  // ─────────────────────────────────────────────────────────────────────────
  group('HR-1.3 the fold must cost what the text costs, not its square', () {
    test('one fold pass over the ENTIRE shipped corpus fits in '
        '${_wholeCorpusFoldBoundMs.toInt()} ms', () {
      final corpus = _allRealCorpus();
      var chars = 0;
      var rows = 0;
      for (final list in corpus.values) {
        rows += list.length;
        for (final h in list) {
          chars += h.textEnglish.length;
        }
      }
      final sw = Stopwatch()..start();
      var foldedChars = 0;
      for (final list in corpus.values) {
        for (final h in list) {
          foldedChars += SearchNormalizer.foldQuery(h.textEnglish).length;
        }
      }
      sw.stop();
      final ms = sw.elapsedMicroseconds / 1000.0;
      debugPrint('[HR13_FOLD] one-time fold pass, english field of all 7 '
          'books: rows=$rows chars=$chars foldedChars=$foldedChars cost='
          '${ms.toStringAsFixed(0)}ms '
          '(${(ms * 1000000 / chars).toStringAsFixed(1)}ns/char)');
      expect(ms, lessThan(_wholeCorpusFoldBoundMs),
          reason: 'folding $chars real chars ONCE — not per query, per row — '
              'is what HR-1.3 makes the entire cost of preparing the corpus. '
              'If this single pass needs ${ms.toStringAsFixed(0)} ms, the '
              'settle-time cache is not a fix, it is a delay, and the phone '
              'pays the same $ms ms before the first result can exist. This '
              'bound is a stopwatch, so its red is a measurement.');
    });

    test('fold time grows with the text, not with its square', () {
      final small = _realTextAtLeast(_foldSmallChars);
      final big = _realTextAtLeast(_foldBigChars);
      double time(String s) {
        final sw = Stopwatch()..start();
        SearchNormalizer.foldQuery(s);
        sw.stop();
        return sw.elapsedMicroseconds / 1000.0;
      }

      // Warm both shapes: the first fold of a big string also pays to prime
      // the regex and the fold map. The ratio is the finding, so it must not
      // be measured against a cold JIT on only one of the two sides.
      time(small.substring(0, 200));
      time(big.substring(0, 200));
      final smallMs = time(small);
      final bigMs = time(big);
      final growth = bigMs / (smallMs <= 0 ? 0.001 : smallMs);
      final lengthGrowth = big.length / small.length;
      debugPrint('[HR13_FOLD] fold(${small.length} chars)='
          '${smallMs.toStringAsFixed(2)}ms fold(${big.length} chars)='
          '${bigMs.toStringAsFixed(2)}ms growth=${growth.toStringAsFixed(1)}x '
          'for ${lengthGrowth.toStringAsFixed(1)}x more text');
      expect(growth, lessThan(_foldGrowthBound),
          reason: '${lengthGrowth.toStringAsFixed(0)}x the text cost '
              '${growth.toStringAsFixed(0)}x the time. A linear fold cannot '
              'grow faster than its input by more than a loaded CI runner\'s '
              'noise; the `buf.toString()` whitespace guard multiplies the '
              'growth by the buffer length too, which is what made 36,390 '
              'rows unreadable in time on the owner\'s phone. Keep this ratio '
              'near ${lengthGrowth.toStringAsFixed(0)} and nobody may '
              're-materialise the buffer per character again.');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // THE CLASS OF BUG, PINNED IN SOURCE. Every timing gate here can be
  // out-fiddled by a smaller fixture — that is precisely how HR-1 ended up
  // green and the phone red. These pins cannot: they read the scan path and
  // forbid folding corpus text inside it.
  // ─────────────────────────────────────────────────────────────────────────
  group('HR-1.3 the scan path may not fold corpus text', () {
    test('the mirrored scan matches with indexOf on cached strings and folds '
        'nothing but the query', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      final body = _methodBody(code, _foldedScanSignature);
      expect(body, isNotEmpty,
          reason: 'HR-1.3 exists to move the fold out of the scan: the service '
              'must expose $_foldedScanSignature — the scan that takes the '
              'corpus ALREADY folded. Its absence is the pre-fix shape, the '
              'one that never answered the owner\'s phone.');
      for (final banned in [
        'SearchNormalizer.contains(',
        'SearchNormalizer.fold(',
        'foldLanguageIntoRows',
      ]) {
        expect(body.contains(banned), isFalse,
            reason: '`$banned` inside the scan folds corpus text again, which '
                'is the bug, not an optimisation of it');
      }
      expect(RegExp(r'SearchNormalizer\.foldQuery\(').allMatches(body).length,
          1,
          reason: 'the only fold allowed in the scan is the query fold, done '
              'once per query into a list BEFORE the row loop. Two occurrences '
              'in the source means someone is folding inside the row loop '
              'again.');
      expect(body.contains('indexOf('), isTrue,
          reason: 'matching must be `indexOf` on the cached folded string');
    });

    test('the raw scan is a delegate, not a second implementation', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      final body = _methodBody(code, _rawScanSignature);
      expect(body.contains('scanFoldedHadithCorpus('), isTrue,
          reason: '`scanHadithCorpus` is pinned by HR-1 (row identity, the '
              'benchmark). It must stay the PRE-HR-1.3 REFERENCE: fold, then '
              'hand the fold to the same matching body. Two implementations of '
              'one ranking rule is how a cache quietly starts disagreeing with '
              'the truth.');
      expect(body.contains('hadith.textEnglish'), isFalse,
          reason: 'if the raw path matched fields itself it would be a second '
              'ranking implementation, and the parity test would prove '
              'nothing');
    });

    test('the worker builds the mirror at settle and never on the keystroke '
        'path', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      final entry = _methodBody(
          code, 'void _hadithSearchWorkerEntry(SendPort mainPort) {');
      expect(entry, isNotEmpty, reason: 'the worker entry must keep its name');
      expect(entry.contains('foldHadithBook('), isTrue,
          reason: 'the folded mirror is built in the worker, next to the rows '
              'it already owns — never on the main isolate, which is HR-1\'s '
              'copy ban');
      expect(entry.contains('scanFoldedHadithCorpus('), isTrue,
          reason: 'searches are answered from the mirror');
      expect(RegExp(r'(?<![A-Za-z])scanHadithCorpus\(').hasMatch(entry),
          isFalse,
          reason: 'the worker must not call the folding scan any more: that is '
              'the per-keystroke fold the phone died of');

      final settle =
          _workerBranch(entry, 'if (message is _HadithFlushRequest)');
      expect(settle, isNotEmpty,
          reason: 'the settle signal must stay named as it is: it is the only '
              '"the corpus is complete" moment the worker has');
      final builtAt = settle.indexOf('foldHadithBook(');
      final repliedAt = settle.indexOf('replyTo.send(');
      expect(builtAt, greaterThan(-1),
          reason: 'the mirror is built at settle — one-time, off-main, behind '
              'the boot, never on the keystroke path');
      expect(repliedAt, greaterThan(builtAt),
          reason: 'and only THEN does the worker answer the boot: main\'s '
              'first query must find a corpus that is already folded, because '
              'a query that arrives before the mirror exists pays the fold on '
              'the typing path, which is the bug wearing the fix');

      final search =
          _workerBranch(entry, 'if (message is _HadithSearchRequest)');
      expect(search.contains('foldHadithBook('), isFalse,
          reason: 'no folding in the request branch — this branch is what runs '
              'per keystroke, and "per keystroke" is exactly what the phone '
              'could not afford');

      expect(RegExp(r'\.remove\(message\.slug\)').allMatches(entry).length,
          greaterThan(1),
          reason: 'the mirror must die with the rows it mirrors: both the book '
              'payload and the language-fold replace `books[slug]`, and a fold '
              'cache that outlives its rows drops hits silently — the failure '
              'mode a device cannot see and a test must');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // THE FIX'S TWO PROMISES, MEASURED. (a) the mirror must answer EXACTLY what
  // the folding scan answered — "the optimization may not change one result";
  // (b) the memory bought with that speed is a NUMBER, not "roughly doubles".
  // ─────────────────────────────────────────────────────────────────────────
  group('HR-1.3 the cached mirror is the same scan', () {
    test('same hits, same order, same scores — real text, every field, plus a '
        'populated Phase-B one', () {
      final base = _realCorpus(rows: 1400);
      // A Phase-B language `foldLanguageIntoRows` really installed, so the
      // mirror is tested on the fields a shipped language fills — not only the
      // three that always have text.
      final withPhaseB = <String, List<LocalHadith>>{};
      for (final entry in base.entries) {
        withPhaseB[entry.key] = foldLanguageIntoRows(
          rows: entry.value,
          code: 'bn',
          index: {
            for (var i = 0; i < entry.value.length; i++)
              entry.value[i].pairKey:
                  '\u09a8\u09be\u09ae\u09be\u099c \u09b8\u0982\u0995\u09cd\u09b0'
                  '\u09be\u09a8\u09cd\u09a4 \u09b9\u09be\u09a6\u09bf\u09b8 '
                  '$i \u2014 \u09ac\u09b0\u09cd\u09a3\u09a8\u09be '
                  '\u09b8\u0982\u0995\u09cd\u09b7\u09bf\u09aa\u09cd\u09a4',
          },
        ).rows;
      }
      final mirror = foldHadithCorpus(withPhaseB);
      // Every query shape the phone can receive, including the two that are
      // edge cases by construction: whitespace-only and tashkeel-only fold to
      // EMPTY, where `indexOf('')` matches every row and `firstMatch` matches
      // nothing. Parity here means the empty-pattern guard, not luck.
      const queries = [
        'namaz ka tarika', 'patience', 'prayer', 'the Prophet', 'book of',
        '\u0627\u0644\u0631\u062d\u0645\u0646', '\u0635\u0628\u0631',
        '\u09a8\u09be\u09ae\u09be\u099c', ' ', '\u064e\u0651 ', 'KIND',
        'sahih bukhari',
      ];
      var checked = 0;
      var missed = 0;
      for (final q in queries) {
        final raw = scanHadithCorpus(withPhaseB, [q], maxPerQuery: 50).single;
        final cached =
            scanFoldedHadithCorpus(
                    withPhaseB, mirror, [q], maxPerQuery: 50)
                .single;
        expect(_signature(cached), equals(_signature(raw)),
            reason: 'query "$q" (hits ${raw.length}) — the mirror changed a '
                'result, which is the one thing this fix is not allowed to do');
        checked += raw.length;
        if (raw.isEmpty) missed++;
      }
      // Multi-query in one call: the per-query caps and the sort are shared
      // state, so a burst is a different path from 12 single queries.
      final rawBatch =
          scanHadithCorpus(withPhaseB, [...queries], maxPerQuery: 50);
      final cachedBatch = scanFoldedHadithCorpus(
          withPhaseB, mirror, [...queries],
          maxPerQuery: 50);
      expect(
          cachedBatch.map(_signature).toList(),
          equals(rawBatch.map(_signature).toList()),
          reason: 'a 12-query burst answered differently from 12 single '
              'queries — the caps or the sort drifted');
      expect(checked, greaterThan(0),
          reason: 'a parity test on a corpus nothing matched is a tautology');
      debugPrint('[HR13_PARITY] $checked hits compared across '
          '${queries.length} single queries + 1 burst, over '
          '${withPhaseB.values.first.length} real rows (english + arabic + '
          'urdu + chapter + a populated Phase-B field); $missed queries hit '
          'nothing on BOTH sides, which is the empty-pattern case');
    });

    test('what the mirror costs, measured: chars, build time, and RSS', () {
      final corpus = _realCorpus(rows: 1400);
      var rawChars = 0;
      var rows = 0;
      for (final list in corpus.values) {
        for (final h in list) {
          rows++;
          rawChars += h.textEnglish.length + h.textArabic.length +
              h.textUrdu.length + h.chapterName.length;
        }
      }
      final rssBefore = ProcessInfo.currentRss;
      final sw = Stopwatch()..start();
      final mirror = foldHadithCorpus(corpus);
      sw.stop();
      final rssAfter = ProcessInfo.currentRss;
      var mirrorChars = 0;
      var mirrored = 0;
      for (final list in mirror.values) {
        for (final row in list) {
          mirrored++;
          mirrorChars += row.foldedChars;
        }
      }
      expect(mirrored, rows,
          reason: 'one mirrored row per real row, or the index-by-position is '
              'a bug waiting to happen');
      // The fold only ever REMOVES (inert diacritics, collapsed whitespace), so
      // the mirror's text can never outweigh the rows it mirrors. A mirror that
      // starts retaining `FoldedText` objects — the per-character index map, 4
      // bytes per char, the very thing this pass stops building per query —
      // breaks this immediately.
      expect(mirrorChars, lessThanOrEqualTo(rawChars),
          reason: 'mirror $mirrorChars chars vs raw $rawChars chars: folding '
              'must not ADD characters, and must not keep the source or the '
              'map beside the folded string');
      final rssDeltaKb = (rssAfter - rssBefore) ~/ 1024;
      final mirrorCharsKb = mirrorChars * 2 ~/ 1024;
      debugPrint('[HR13_RAM] $rows real rows / $rawChars searched chars = '
          '${(rawChars * 2 / (1024 * 1024)).toStringAsFixed(2)}MB of text; '
          'mirror = $mirrorChars chars = '
          '${(mirrorChars / rawChars * 100).toStringAsFixed(1)}% of that, plus '
          '$mirrored row objects; build ${sw.elapsedMicroseconds}us = '
          '${(sw.elapsedMicroseconds / rows).toStringAsFixed(1)}us/row; '
          'RSS +${rssDeltaKb}KB (the mirror\'s own chars are '
          '${mirrorCharsKb}KB)');
      expect(rssDeltaKb, greaterThan(0),
          reason: 'the mirror is retained memory; if RSS did not move, the '
              'measurement is broken — and this number, not an estimate, is '
              'what the pass report quotes');
      expect(rssDeltaKb, lessThan(mirrorCharsKb * 4 + 8192),
          reason: 'RSS grew more than 4x what the mirror\'s own characters '
              'need — that is the shape of an index map (or a second copy of '
              'the raw text) being retained beside it');
    });
  });
}
