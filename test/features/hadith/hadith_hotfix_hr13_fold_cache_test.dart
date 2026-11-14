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
// typing stayed smooth, so this is NOT a worker-availability bug: the scan does
// not finish in time.
//
// WHY CI WAS GREEN (the gate lied, and the report repeated its conclusion):
// the HR-1 benchmark's synthetic rows carry ~20-25-char topic strings. Real
// hadith texts are 300-2,000 chars (measured below, from the shipped bundle).
// `scanHadithCorpus` asks `SearchNormalizer.contains(rawText, q)` per row per
// field, and `SearchNormalizer.fold` rebuilds the folded text — char by char,
// with a per-character index map — EVERY TIME. Cost is therefore a function of
// TEXT LENGTH, and the benchmark under-modelled the real corpus by orders of
// magnitude. This file's first job is to make the real cost a gate.
//
// RED EVIDENCE for the cost gate below, and the measured numbers this pass
// reports, are recorded in the CI-rounds table of
// docs/HADITH_HR_PASS_REPORT.md ("HR-1.3") and in the commit that landed the
// fix — the gate is a stopwatch, so its red is a measurement, not a guess.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

/// The shipped English file of one real collection. Not a fixture: the corpus
/// the phone actually scans.
const _realBookSlug = 'bukhari';
const _realBookDir = 'assets/data/hadith/$_realBookSlug';

/// Rows under the gate. 1,200 of the real 7,563 in this file — enough that the
/// fold cost is unmissable, small enough that a RED run of this test costs
/// seconds instead of the minutes the device pays. The shipped shape (the full
/// corpus, through the debounce) is the second test.
const _rowsUnderGate = 1200;

/// The scan's own bound, in ms, for one query over the rows under the gate.
/// 500 ms is the brief's end-to-end bound; the fold-per-scan shape blows it by
/// an order of magnitude on real-length text, which is the whole finding.
const _scanBoundMs = 500.0;

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
  expect(assembled, isNotNull, reason: 'the real bundle must assemble — if this '
      'is red the fixture is wrong, not the scan');
  final all = assembled!.hadiths;
  expect(all.length, greaterThan(rows),
      reason: 'the gate needs $rows real rows and the bundle has ${all.length}');
  return {_realBookSlug: all.sublist(0, rows)};
}

/// Chars per row per searched field, measured on the corpus under test. The
/// number that makes the benchmark's lie arithmetic instead of opinion.
({int fields, int chars, int rows}) _measureCorpus(Map<String, List<LocalHadith>> corpus) {
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

int _p95Us(List<int> xs) {
  final sorted = [...xs]..sort();
  final i = (sorted.length * 0.95).ceil() - 1;
  return sorted[i < 0 ? 0 : (i >= sorted.length ? sorted.length - 1 : i)];
}

void main() {
  group('HR-1.3 the fold must be paid once per row, not once per query per scan', () {
    /// THE COST GATE. Reads no synthetic text at all: the corpus is the shipped
    /// bundle, the queries are the owner's, and the bound is the brief's.
    test('one scan of $rowsUnderGate REAL rows is bounded, not "minutes"', () {
      final corpus = _realCorpus();
      final size = _measureCorpus(corpus);
      final perRow = (size.chars / size.rows).round();
      // Printed for the report, because the finding IS a number.
      debugPrint('[HR13_MEASURE] rows=${size.rows} searchedChars=${size.chars} '
          'meanCharsPerRow=$perRow fields=${size.fields}');

      // The queries are the ones the device typed, and the ones a reader types:
      // short terms against long text — the worst case for a per-row fold,
      // because the fold cost is paid in full whether or not anything matches.
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
              'p95. The device paid this on EVERY keystroke while the UI waited '
              '90 s for a reply that never came — that is HR-1.3. The bound only '
              'holds once the fold is cached per row at hand-off (the fix); the '
              'fold-per-scan shape cannot meet it at any row count that matters.');
    });

    /// The arithmetic of why the shipped benchmark could not see this, kept as
    /// a witness so nobody re-derives the conclusion from short synthetic text.
    test('the HR-1 synthetic fixture is lighter per row than reality — measured',
        () {
      final real = _measureCorpus(_realCorpus(rows: 400));
      final realPerRow = real.chars / real.rows;
      // The exact generator `hadith_pass_hr1_test` uses (that file's own copy is
      // private, so the shape is restated here rather than edited there): one
      // 20-word topic sentence per row.
      const topic = 'namaz ka tarika';
      final fixtureText = 'Volume 1, Book 1, Hadith 1: $topic — the Prophet '
          '(peace be upon him) said, and the chain is complete for row 1 of '
          'bukhari.';
      final syntheticPerRow = fixtureText.length; // english only, as generated
      debugPrint('[HR13_MEASURE] real mean searched chars/row = '
          '${realPerRow.toStringAsFixed(0)}; HR-1 synthetic english/row = '
          '$syntheticPerRow; ratio = '
          '${(realPerRow / syntheticPerRow).toStringAsFixed(1)}x');
      expect(realPerRow / syntheticPerRow, greaterThan(3.0),
          reason: 'the benchmark that concluded "no indexed pre-normalisation '
              'pass is indicated" scanned rows $realPerRow / $syntheticPerRow = '
              'far longer than this. Fold cost scales with text length, so its '
              'timing was off by the same factor and more (the fold is '
              'quadratic in length inside SearchNormalizer.append). If this '
              'ratio ever drops, the benchmark has gone short-text again and the '
              'gate is blind.');
    });
  });
}
