// test/features/hadith/hadith_pass_hr1_test.dart
// ============================================================
// PASS HR-1 — the search path may NEVER capture the corpus.
//
// OWNER FINDING this file exists to make impossible: typing "namaz ka tarika"
// into the hadith search froze the whole app on a CPH2573 in profile mode. The
// hadith tab committed a query on every keystroke, and every commit ran
//     final booksSnapshot = Map<String, List<LocalHadith>>.of(_bookData);
//     return Isolate.run(() { ...scan booksSnapshot... });
// — `Isolate.run` sends the closure to a NEW isolate, and sending is a DEEP
// copy of everything it captures: all 36,390 rows, copied on the main isolate,
// per keystroke.
//
// NO CI TEST COULD SEE IT: every hadith/AI search test drives a fake that
// OVERRIDES `searchBatchOffMain`, so the capture never executed there. That is
// the whole reason this file is mostly source pins — a forbidden pattern in the
// text is the one instrument that cannot be stubbed out. The two behavioural
// groups below (worker parity, the benchmark) run the REAL isolate, so the
// design is not merely documented, it is exercised.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_search_worker.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';

import '../../support/source_guards.dart';

const _servicePath =
    'lib/features/hadith/data/services/hadith_database_service.dart';
const _workerPath =
    'lib/features/hadith/data/services/hadith_search_worker.dart';
const _providerPath = 'lib/features/hadith/providers/hadith_provider.dart';
const _screenPath = 'lib/features/hadith/presentation/hadith_screen.dart';

String _read(String path) => File(path).readAsStringSync();

/// Every `Isolate.run(...)` / `Isolate.spawn(...)` call site in [code], as its
/// own balanced-paren span — i.e. the closure AND its argument list, which is
/// exactly the region a capture lives in. Comment-blind by contract: the worker
/// file QUOTES the frozen shape in its header, and a naive scan would read the
/// documentation as the bug (the same trap `hadith_redesign_test` hit and fixed).
List<String> isolateSpans(String code) {
  final out = <String>[];
  for (final m in RegExp(r'Isolate\.(?:run|spawn)\w*\(').allMatches(code)) {
    var depth = 0;
    var i = m.end - 1;
    while (i < code.length) {
      final c = code[i];
      if (c == '(') depth++;
      if (c == ')') {
        depth--;
        if (depth == 0) {
          out.add(code.substring(m.start, i + 1));
          break;
        }
      }
      i++;
    }
  }
  return out;
}

/// The method from its signature to its closing brace.
///
/// Anchored on the OPENING brace on purpose: `searchBatchOffMain` wraps its
/// parameter list, so the `  })` that closes that list is itself a
/// newline-plus-two-spaces-plus-brace sequence. Scanning for that from the
/// signature returns the signature and nothing else — which is how this
/// file's first draft ended up asserting against an empty body and reading
/// the pin as missing. The open-brace anchor cannot be confused.
String methodBody(String code, String signatureStart) {
  final start = code.indexOf(signatureStart);
  if (start < 0) return '';
  final params = code.indexOf(')', start);
  final open = code.indexOf('{', params);
  if (params < 0 || open < 0) return '';
  final end = code.indexOf('\n  }', open);
  return end < 0 ? '' : code.substring(start, end);
}

// ───────────────────────── synthetic corpus ─────────────────────────────────

/// One book of [rows] hadiths in EXACTLY the shipped shape (metadata.sections +
/// hadiths[] with hadithnumber / arabicnumber / reference / grades / text), so
/// the assembler, the join and the scan all run their production code paths on
/// it. Row [firstNumber] + i is the number; every 97th row is FRACTIONAL,
/// because the truncation onto its parent is the failure X6 proved is real and
/// a worker that forgot it would search a different corpus than the one painted.
/// One book of [rows] hadiths in EXACTLY the shipped shape (metadata.sections +
/// hadiths[] with hadithnumber / arabicnumber / reference / grades / text), so
/// the assembler, the join and the scan all run their production code paths on
/// it. Row [firstNumber] + i is the number; every 97th row is FRACTIONAL,
/// because the truncation onto its parent is the failure X6 proved is real and
/// a worker that forgot it would search a different corpus than the one painted.
///
/// HOTFIX HR-1.3 — THE TEXT LENGTH IS NOW THE SHIPPED ONE, AND THAT IS NOT A
/// COSMETIC CHANGE. Every row used to carry ONE 145-char sentence. The real
/// bundle (measured over `assets/data/hadith/*/english.json`, 36,390 rows) is
/// mean 423 chars, p95 1,134, max 24,676 for english and mean 549 / 464 for
/// arabic / urdu (the 549 is the unbundled edition, kept here as history).
/// `fold` cost scales with text length, so a benchmark of
/// 145-char rows measured the scan at ~1/10th of its real weight per field and
/// ~1/50th over all searched fields — and the report then concluded from it
/// that no pre-normalisation pass was indicated. The phone disagreed: six
/// `scan request N, budget 90s (first after a spawn)`, zero `answered`.
/// [lang] picks the script so the urdu field is real too. (HR-2.1: the
/// 'arabic' script this generator used to hand the benchmark is gone with the
/// edition — the corpus under test is the corpus that ships, which is the
/// whole point of the file.)
String _syntheticBook(int firstNumber, int rows,
    {String bookSlug = 'bukhari', String lang = 'english'}) {
  // One clause per script (english 127 chars, urdu 110), repeated
  // 2 + (i % 6) times: mean ~570 english / ~495 urdu chars per row
  // against the shipped bundle's measured 423 / 464 — i.e. 10-15% HEAVIER
  // than reality, which is the only direction a fixture may err in when it is
  // standing in for the device. Every 900th row adds 7 clauses, for the tail
  // (real max is 24,676). Placeholders are spelled `@x@` because a `$` inside a
  // Dart literal is interpolation, and this file's own history has a CI round
  // lost to exactly that.
  const clause = {
    'english': 'Volume 1, Book 1, Hadith @NO@: @TOPIC@ — the Prophet (peace '
        'be upon him) said, and the chain is complete for row @I@ of @SLUG@.',
    'urdu': '\u062c\u0644\u062f 1\u060c \u06a9\u062a\u0627\u0628 1\u060c '
        '\u062d\u062f\u06cc\u062b @NO@: @TOPIC@ \u2014 \u0646\u0628\u06cc '
        '\u06a9\u0631\u06cc\u0645 \u0635\u0644\u06cc \u0627\u0644\u0644\u06c1 '
        '\u0639\u0644\u06cc\u06c1 \u0648\u0633\u0644\u0645 \u0646\u06c1 '
        '\u0641\u0631\u0645\u0627\u06cc\u0627\u060c \u0627\u0648\u0631 '
        '\u0633\u0646\u062f @I@ \u06a9\u06d2 \u0644\u06cc\u0626\u06d2 '
        '\u0645\u06a9\u0645\u0644 \u06c1\u06d2 @SLUG@\u06d4',
  };
  const topics = {
    'english': 'namaz ka tarika',
    'urdu': '\u0646\u0645\u0627\u0632 \u06a9\u0627 \u062a\u0631\u06cc\u06a9\u06c1',
  };
  final hadiths = <Map<String, dynamic>>[];
  for (var i = 0; i < rows; i++) {
    final n = firstNumber + i;
    final fractional = i % 97 == 96;
    final number = fractional ? '$n.2' : '$n';
    final arabic = fractional ? '$n.2' : '$n';
    final repeats = 2 + (i % 6) + (i % 900 == 899 ? 7 : 0);
    final body = clause[lang]!
        .replaceAll('@NO@', '$n')
        .replaceAll('@TOPIC@',
            i % 7 == 0 ? topics[lang]! : 'patience in hardship')
        .replaceAll('@I@', '$i')
        .replaceAll('@SLUG@', bookSlug);
    hadiths.add({
      'hadithnumber': num.parse(number),
      'arabicnumber': num.parse(arabic),
      'reference': {
        'book': (i % 3) + 1,
        'hadith': n,
      },
      'grades': [
        {'grade': 'Sahih', 'name': 'Yahya'}
      ],
      'text': List.filled(repeats, body).join(' '),
    });
  }
  return jsonEncode({
    'metadata': {
      'name': 'Sahih al-Bukhari',
      'sections': {
        '1': 'The Book of Knowledge',
        '2': 'The Book of Faith',
        '3': 'The Book of Prayer',
      },
    },
    'hadiths': hadiths,
  });
}


Map<String, dynamic>? _decode(String raw) =>
    HadithDatabaseService.decodeHadithAsset(raw);

void main() {
  // ─────────────────────────── 1. the capture ban ───────────────────────────
  group('HR-1 capture ban — no isolate closure may hold the corpus', () {
    test('no Isolate.run / Isolate.spawn span in lib/features/hadith reads '
        'the corpus map (the frozen shape, forbidden in source)', () {
      final offenders = <String>[];
      final scanned = <String>[];
      for (final entity in Directory('lib/features/hadith')
          .listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final code = stripCommentsForGuard(_read(entity.path));
        scanned.add(entity.path);
        for (final span in isolateSpans(code)) {
          for (final banned in [
            '_bookData',
            'booksSnapshot',
            'Map<String, List<LocalHadith>>.of',
          ]) {
            if (span.contains(banned)) {
              offenders.add('${entity.path} — captures `$banned` in: '
                  '${span.substring(0, span.length.clamp(0, 90))}');
            }
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'a corpus graph inside an isolate closure is copied PER CALL '
              'on the main isolate — that single line is what froze the app for '
              'the owner. Offenders: $offenders');
      expect(scanned.length, greaterThan(10),
          reason: 'the sweep must cover the feature, not one file — hadith is '
              '11 dart files today, and a floor (not an exact count) is what a '
              'split file should not be able to break');
    });

    test('the old snapshot line is gone from the service, not renamed', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      expect(code.contains('Map<String, List<LocalHadith>>.of(_bookData)'),
          isFalse,
          reason: 'the shallow `.of()` looked free and was not: the copy '
              'happened when Isolate.run serialized the capture');
      expect(code.contains('booksSnapshot = Map<'), isFalse);
    });

    test('searchBatchOffMain keeps its signature and delegates — it does not '
        'scan, does not spawn, and does not copy', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      final body =
          methodBody(code, 'Future<List<List<LocalSearchResult>>> '
              'searchBatchOffMain(');
      expect(body, isNotEmpty, reason: 'the method must stay findable — the '
          'AI pins reference it by name');
      expect(body.contains('Isolate.'), isFalse,
          reason: 'no per-call isolate at all: the worker is long-lived');
      expect(body.contains('HadithSearchWorker.instance'), isTrue);
      expect(body.contains('if (!_isInitialized) return'), isTrue,
          reason: 'a COLD service still answers honestly empty — '
              'ai_revival_test pins that shape and it must stay');
    });

    test('a worker that cannot answer yields EMPTY, never a main-isolate rescan',
        () {
      final body = methodBody(
          stripCommentsForGuard(_read(_servicePath)),
          'Future<List<List<LocalSearchResult>>> searchBatchOffMain(');
      expect(body.contains('scanHadithCorpus(_bookData'), isFalse,
          reason: 'the emergency path must not be "do the old thing on main"; '
              'that is the freeze, re-labelled');
      expect(body.contains('return [for (final _ in queries) <LocalSearchResult>[]];'),
          isTrue,
          reason: 'empty is the honest degraded answer, and it is what the '
              'existing cold-start contract already does');
    });

    test('KNOWN DEBT, LEDGERED: the Quran repo still snapshots per call', () {
      // Pinned at its CURRENT count on purpose: the fix is real work on a
      // different corpus (114 surahs / 6,236 ayahs) and HR-1 is scoped to
      // hadith. If this number moves, the ledger moves with it — either
      // someone fixed it (update this test, celebrate) or someone grew it
      // (stop).
      final code = stripCommentsForGuard(
          _read('lib/features/quran/data/repository/quran_repository.dart'));
      final spans = isolateSpans(code)
          .where((s) => s.contains('surahsSnapshot') || s.contains('_cachedSurahsMap'))
          .length;
      expect(spans, 2,
          reason: 'quran search captures its corpus in 2 isolate spans today — '
              'smaller than the hadith corpus by ~6x, so it did not freeze the '
              'owner, and it is disclosed here rather than quietly ignored');
    });
    test('the worker keeps its corpus as a LOCAL of the entry, and never '
        'spawns per call', () {
      final code = stripCommentsForGuard(_read(_workerPath));
      expect(code.contains('void _hadithSearchWorkerEntry(SendPort mainPort) {'),
          isTrue,
          reason: 'top-level and port-only: no rootBundle, no providers, no '
              'this. An entry that could read assets would put the boot back on '
              'the critical path and stop being isolate-safe');
      expect(code.contains('final books = <String, List<LocalHadith>>{};'),
          isTrue,
          reason: 'the corpus is a LOCAL of the entry, captured by its own '
              'listener — the only shape in which main genuinely cannot reach it');
      expect(code.contains('Map<String, List<LocalHadith>> _'), isFalse,
          reason: 'a FIELD corpus would be a handle reachable through the '
              'singleton, which is the capture this pass bans');
      expect(code.contains('Isolate.spawn('), isTrue);
      expect(code.contains('Isolate.run'), isFalse,
          reason: 'Isolate.run IS a per-call spawn, the shape that copied the '
              'corpus per keystroke: one spawn per app, never one per query');
      expect(code.contains('rootBundle'), isFalse,
          reason: 'the worker is FED bytes and never reads assets itself, so '
              'the 21 boot reads stay exactly one per file per session');
    });

  });

  // ───────────────── 2. one assembler, one scan, two isolates ───────────────
  group('HR-1 the worker scans exactly what main renders', () {
    test('the assembler and the scan each exist ONCE in lib (no second '
        'implementation to drift)', () {
      var decls = 0;
      var scanSites = 0;
      var assemblerCalls = 0;
      for (final entity in Directory('lib/features/hadith')
          .listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final code = stripCommentsForGuard(_read(entity.path));
        decls += RegExp(r'HadithAssembledBook\? assembleHadithBook\(')
            .allMatches(code)
            .length;
        scanSites +=
            RegExp(r'List<List<LocalSearchResult>> scanHadithCorpus\(')
                .allMatches(code)
                .length;
        assemblerCalls += RegExp(r'assembleHadithBook\(').allMatches(code).length;
      }
      expect(decls, 1);
      expect(scanSites, 1,
          reason: 'one ranking implementation for the app; the worker calls it, '
              'nothing re-implements relevance rules in a closure');
      expect(assemblerCalls, 3,
          reason: 'one declaration, two call sites (main + the worker entry) — '
              'a fourth match means a third place that assembles rows, which '
              'is exactly where a join rule forks');
    });

    test('the worker assembles identical rows and returns identical hits',
        () async {
      final raw = _syntheticBook(1, 40);
      final worker = HadithSearchWorker();
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari', name: 'Sahih al-Bukhari', rawEnglish: raw);
      await worker.whenSettled();
      expect(worker.isLive, isTrue,
          reason: 'the spawn was refused in this environment — every other '
              'assertion here would be vacuous');

      final mainCopy = assembleHadithBook(
        englishData: _decode(raw),
        urduData: null,
        langIndices: const {},
        slug: 'bukhari',
        name: 'Sahih al-Bukhari',
      )!;
      expect(mainCopy.hadiths.length, 40);
      expect(mainCopy.sections['3'], 'The Book of Prayer',
          reason: 'sections come back on main (LocalBookInfo needs them) and '
              'the worker never sees them as a separate object');

      final expected =
          scanHadithCorpus({'bukhari': mainCopy.hadiths}, ['namaz ka tarika'],
              maxPerQuery: 5);
      final got = await worker.search(['namaz ka tarika'], maxPerQuery: 5);
      expect(got, isNotNull);
      expect(
          got![0].map((r) => '${r.hadith.id}|${r.relevance}|${r.matchedIn}'),
          expected[0]
              .map((r) => '${r.hadith.id}|${r.relevance}|${r.matchedIn}'),
          reason: 'the answer a reader sees must be the answer the rendered '
              'text would have produced — identical rows, identical rules');
      expect(got[0], isNotEmpty);
    });

    test('X6 fractional identity survives the isolate trip (402.2 is not 402)',
        () async {
      final raw = _syntheticBook(400, 200);
      final rows = assembleHadithBook(
        englishData: _decode(raw),
        urduData: null,
        langIndices: const {},
        slug: 'bukhari',
        name: 'Sahih al-Bukhari',
      )!;
      final labels = rows.hadiths.map((h) => h.numberLabel).toSet();
      expect(labels.contains('496.2'), isTrue,
          reason: 'row 96 of the synthetic corpus is the fractional one; the '
              'assembler must keep the edition number, not floor it');
      expect(rows.hadiths.firstWhere((h) => h.numberLabel == '496.2').id,
          'bukhari_496',
          reason: 'the int id still points at the parent BY DESIGN (bookmarks '
              'store ints — X6 pinned it), while the LABEL is honest');
      final worker = HadithSearchWorker();
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(slug: 'bukhari', name: 'Sahih al-Bukhari', rawEnglish: raw);
      await worker.whenSettled();
      final hits = await worker.search(['row 96 of bukhari'], maxPerQuery: 5);
      expect(hits, isNotNull);
      expect(hits![0].map((r) => r.hadith.numberLabel), contains('496.2'),
          reason: 'the row that crossed the isolate boundary kept its pairKey '
              '— a lost key here is X6 re-broken in the new architecture');
    });
  });

  // ─────────────────────── 3. boot diet, unchanged ─────────────────────────
  group('HR-1 the boot still reads once and never waits on the worker', () {
    test('two asset reads per book — the worker rides the SAME strings', () {
      // HR-2.1 re-pin: 3 → 2 per book (21 → 14 boot decodes), because
      // arabic.json left the bundle and the batch is built from
      // HadithAvailability.fileForLanguage. The RULE is unchanged and still
      // worth pinning: one read per shipped file, and the worker gets the
      // SAME strings, so the diet could not have been paid for by adding a
      // second read or a main-isolate copy.
      final code = stripCommentsForGuard(_read(_servicePath));
      final load = methodBody(code, 'Future<void> _loadBook(String slug, String name)');
      expect(RegExp(r'_loadJsonAsset\(').allMatches(load).length, 2,
          reason: 'english/urdu, once each — HR-1 must not add another read '
              'to feed the worker (the raw pair is handed from what was '
              'already read)');
      expect(load.contains('Future.wait<Object?>(['), isTrue,
          reason: 'the per-book batch shape perf_pass_test pins stays the batch');
    });

    test('the handoff is unawaited and lands AFTER main has its rows', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      final load =
          methodBody(code, 'Future<void> _loadBook(String slug, String name)');
      expect(load.contains('unawaited(HadithSearchWorker.instance.noteBook('),
          isTrue,
          reason: 'the first painted hadith must never wait on the worker decode');
      expect(
          load.indexOf('_bookData[slug] = hadiths;') <
              load.indexOf('unawaited(HadithSearchWorker.instance.noteBook('),
          isTrue,
          reason: 'main installs its copy first — the worker is a follower, '
              'so no UI path can observe a corpus that only exists there');
      expect(load.contains('rawEnglish: englishAsset?.raw'), isTrue);
    });

    test('the decode stays off-main, in one place, and the language fold is '
        'shared too', () {
      final code = stripCommentsForGuard(_read(_servicePath));
      expect(RegExp(r'jsonDecode').allMatches(code).length, 1,
          reason: 'perf_pass_test pins ONE decode site app-side; HR-1 must not '
              'add a second main-thread decode to feed the worker');
      expect(code.contains('Isolate.run(() => decodeHadithAsset(raw))'), isTrue,
          reason: 'main\'s own per-file decode is untouched — first-frame '
              'parity with X1/X5 is a binding contract, not an accident');
      expect(code.contains('foldLanguageIntoRows('), isTrue);
      final fold = methodBody(code, 'Future<bool> _foldLanguage(String code)');
      expect(fold.contains('noteFold('), isTrue,
          reason: 'a language selected AFTER boot folds both copies or neither');
    });
  });

  // ──────────────────────── 4. the 250 ms window ───────────────────────────
  group('HR-1 the debounce window supersedes, a tap does not wait', () {
    test('a burst of keystrokes commits ONCE, with the final text', () async {
      final d = HadithSearchDebounce(delay: const Duration(milliseconds: 30));
      addTearDown(d.dispose);
      final committed = <String>[];
      for (final q in [
        'n', 'na', 'nam', 'nama', 'namaz', 'namaz ', 'namaz k', 'namaz ka',
        'namaz ka t', 'namaz ka ta', 'namaz ka tar', 'namaz ka tari',
        'namaz ka tarika',
      ]) {
        d.note(q, committed.add);
      }
      expect(committed, isEmpty,
          reason: 'nothing may be issued while the window is open — every '
              'commit here used to cost a corpus copy');
      expect(d.pending, 'namaz ka tarika');
      expect(d.isScheduled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(committed, ['namaz ka tarika'],
          reason: '13 keystrokes, 1 scan: the number this pass exists to make '
              'true on the owner\'s device');
      expect(d.isScheduled, isFalse);
    });

    test('every keystroke bumps the generation, so a stale result is knowable',
        () async {
      final d = HadithSearchDebounce(delay: const Duration(milliseconds: 20));
      addTearDown(d.dispose);
      final before = d.generation;
      d.note('a', (_) {});
      d.note('ab', (_) {});
      expect(d.generation, before + 2);
      d.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(d.generation, before + 2,
          reason: 'cancel does not invent a generation — the counter moves on '
              'what the reader typed, not on what got committed');
    });

    test('commitNow is for taps: it emits at once and cancels the open window',
        () async {
      final d = HadithSearchDebounce(delay: const Duration(milliseconds: 40));
      addTearDown(d.dispose);
      final committed = <String>[];
      d.note('stale-typing', committed.add);
      d.commitNow('Patience', committed.add);
      expect(committed, ['Patience'],
          reason: 'the quick-pick chip pre-runs the sheet on its query — '
              'hadith_h4_search_test reads the provider one frame after the tap, '
              'and a debounce there would break a shipped behavior');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(committed, ['Patience'], reason: 'the discarded window stayed discarded');
    });

    test('the field and the pop-reset are wired through the window', () {
      final code = stripCommentsForGuard(_read(_screenPath));
      expect(
          RegExp(r'hadithSearchDebounceProvider\)\s*\.note\(')
              .allMatches(code)
              .length,
          1,
          reason: 'exactly ONE writer buffers — the field. Every other path is '
              'a tap or a lifecycle event and must not wait 250 ms');
      expect(
          RegExp(r'hadithSearchDebounceProvider\)\s*\.commitNow\(')
              .allMatches(code)
              .length,
          4,
          reason: 'Enter, the pop-reset, the quick-pick pre-runner and the '
              'recent-search chip all commit through the window (so they cancel '
              'it) instead of writing past it');
      // WHAT THIS PIN ACTUALLY MEANS, after CI corrected it once: the first
      // draft asserted "zero `.state =` writes in the screen", which was wrong —
      // the window's commit closures ARE writes, five of them, and that is the
      // design. The thing that must stay at zero is a write of LIVE text. So the
      // pair below counts every write of the committed query and every write
      // whose target is `committed`, and demands they be the same number.
      // Whitespace is flattened first: a source pin that depends on where
      // `dart format` happened to break a line is a coin flip, not a guard.
      final flat = code.replaceAll(RegExp(r'\s+'), ' ');
      final queryWrites = RegExp(
              r'read\(\s*hadithSearchQueryProvider\s*\.\s*notifier\s*\)\s*\.\s*state\s*=')
          .allMatches(flat)
          .length;
      final throughWindow = RegExp(
              r'read\(\s*hadithSearchQueryProvider\s*\.\s*notifier\s*\)\s*\.\s*state\s*=\s*committed\b')
          .allMatches(flat)
          .length;
      expect(queryWrites, 5,
          reason: 'field keystroke, Enter, the pop-reset, the quick-pick '
              'pre-runner and the recent-search chip — five writers, no more');
      expect(throughWindow, queryWrites,
          reason: 'and every one of them writes what the window committed, never '
              'live text: that is how 14 keystrokes became 14 scans, and it must '
              'stay impossible');
    });

    test('the provider layer keeps the committed query as its only input', () {
      final code = stripCommentsForGuard(_read(_providerPath));
      expect(code.contains('final query = ref.watch(hadithSearchQueryProvider);'),
          isTrue,
          reason: 'the results provider watches the COMMITTED query — if it '
              'watched live field text, the debounce would decorate a path that '
              'still scans per character');
      expect(code.contains('this.delay = const Duration(milliseconds: 250)'),
          isTrue,
          reason: '250 ms is the window the brief set, kept as a default a '
              'reader can find and change in one place');
      expect(
          code.contains(
              'final hadithSearchDebounceProvider = Provider<HadithSearchDebounce>'),
          isTrue,
          reason: 'one window per app: field, pill, chips and pop-reset supersede '
              'each other instead of keeping private timers that can commit an '
              'older text after a newer one');
      expect(
          RegExp(r'read\(hadithSearchQueryProvider\.notifier\)\s*\.state\s*=')
              .allMatches(code)
              .length,
          0,
          reason: 'no writer in the provider layer bypasses the window — the '
              'screen commits through it and nothing else writes it');
    });

  });

  // ─────────────────────────── 5. the benchmark gate ───────────────────────
  group('HR-1 benchmark gate — the owner\'s query, on a synthetic corpus', () {
    test('20,020 hadiths, 14 continuous keystrokes: p95 main block < 16 ms '
        'and p95 end-to-end < 500 ms', () async {
      const books = 7;
      const rowsPerBook = 2860; // 7 x 2860 = 20,020 ≥ the brief's 20,000 floor
      final slugs = [
        'bukhari', 'muslim', 'nasai', 'abudawud',
        'tirmidhi', 'ibnmajah', 'malik',
      ];
      final worker = HadithSearchWorker();
      addTearDown(worker.shutdownForTest);
      // HR-1.3 handed all THREE editions the shipped corpus then had, so the
      // benchmark measured the whole searched width instead of a third of it.
      // HR-2.1 re-pins that to the two the corpus now has: en + ur + chapter.
      // The rule survives the diet — hand every searched field, or the number
      // is a fraction of the work.
      for (var b = 0; b < books; b++) {
        await worker.noteBook(
          slug: slugs[b],
          name: slugs[b],
          rawEnglish: _syntheticBook(b * rowsPerBook + 1, rowsPerBook,
              bookSlug: slugs[b]),
          rawUrdu: _syntheticBook(b * rowsPerBook + 1, rowsPerBook,
              bookSlug: slugs[b], lang: 'urdu'),
        );
      }
      // HR-1.3's ONE-TIME cost is measured here, in the only place it can be:
      // the settle wait is assemble + replace + the whole-book fold. It is a
      // boot cost paid once, so the bound is generous and the print is the
      // number the pass report quotes (the device prints its own).
      final settleSw = Stopwatch()..start();
      await worker.whenSettled();
      settleSw.stop();
      debugPrint('[HR1_BENCH] settle (assemble + fold) over '
          '${books * rowsPerBook} real-length rows took '
          '${settleSw.elapsedMilliseconds}ms — one time, off-main');
      expect(settleSw.elapsedMilliseconds, lessThan(15000),
          reason: 'a boot-time pass that costs 15 s is not a cache, it is a '
              'wall: the fold must be paid once and it must stay off the typing '
              'path AND off any path the reader waits on twice.');
      expect(worker.isLive, isTrue, reason: 'no isolate in this environment');
      expect(worker.handedBooks.length, books);

      final queries = [
        'n', 'na', 'nam', 'nama', 'namaz', 'namaz ', 'namaz k', 'namaz ka',
        'namaz ka t', 'namaz ka ta', 'namaz ka tar', 'namaz ka tari',
        'namaz ka tarik', 'namaz ka tarika',
      ];

      // THE PATH UNDER TEST IS THE DEBOUNCED ONE — the brief's wording is
      // "continuous typing through the debounce", so the burst is issued through
      // the app's own window first: 14 keystrokes must produce ONE commit and
      // ONE scan, and that commit's answer must be the final text's.
      final window = HadithSearchDebounce();
      addTearDown(window.dispose);
      final debouncedCommits = <String>[];
      Future<List<List<LocalSearchResult>>?>? debouncedAnswer;
      for (final q in queries) {
        window.note(q, (committed) {
          debouncedCommits.add(committed);
          debouncedAnswer = worker.search([committed], maxPerQuery: 50);
        });
      }
      expect(debouncedCommits, isEmpty,
          reason: 'the window must hold the burst — every commit here used to be '
              'a corpus copy on the UI thread');
      // 250 ms is the shipped window; wait past it, with margin for a loaded CI.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(debouncedCommits, ['namaz ka tarika'],
          reason: '14 keystrokes in, 1 query out — this is the half of the fix '
              'the isolate alone could not give');
      final debatched = await debouncedAnswer;
      expect(debatched, isNotNull,
          reason: 'the single committed query must still be ANSWERED; an empty '
              'here would make the timing bounds below theater');
      expect(debatched!.first, isNotEmpty,
          reason: '"namaz ka tarika" must match the synthetic corpus');

      final block = <int>[];
      final total = <int>[];
      var lastHits = 0;
      for (final q in queries) {
        final blockSw = Stopwatch()..start();
        final pending = worker.search([q], maxPerQuery: 50);
        blockSw.stop();
        final totalSw = Stopwatch()..start();
        final batches = await pending;
        totalSw.stop();
        block.add(blockSw.elapsedMicroseconds);
        total.add(blockSw.elapsedMicroseconds + totalSw.elapsedMicroseconds);
        expect(batches, isNotNull, reason: 'query "$q" got no answer at all');
        lastHits = batches!.first.length;
      }
      expect(lastHits, greaterThan(0),
          reason: 'the corpus is genuinely resident in the worker — an empty '
              'answer would make both timing bounds meaningless');

      int p95(List<int> xs) {
        final sorted = [...xs]..sort();
        final i = (sorted.length * 0.95).ceil() - 1;
        return sorted[i < 0 ? 0 : (i >= sorted.length ? sorted.length - 1 : i)];
      }

      // THE GATE, in ms, on the main isolate: what a keystroke may cost before
      // the reader feels it. Bound from the brief (one frame at 60 Hz).
      expect(p95(block) / 1000.0, lessThan(16.0),
          reason: 'p95 main-isolate block was ${p95(block)} us over '
              '${queries.length} keystrokes — the freeze signature');
      expect(p95(total) / 1000.0, lessThan(500.0),
          reason: 'p95 end-to-end was ${p95(total)} us');

      // Zero tolerance for per-call corpus copies, measured the only way a test
      // can: a query must not hand the worker any more books.
      expect(worker.handedBooks.length, books,
          reason: '14 queries re-handed the corpus — the per-call copy is back');

      // And for the ledger: what the removed shape cost on THIS corpus. One
      // scan of the same 20,020 rows, run synchronously on the main isolate,
      // is what the per-keystroke closure body used to do — before it paid the
      // deep copy of the capture on top.
      final corpus = <String, List<LocalHadith>>{};
      for (var b = 0; b < books; b++) {
        final assembled = assembleHadithBook(
          englishData: _decode(_syntheticBook(b * rowsPerBook + 1, rowsPerBook,
              bookSlug: slugs[b])),
          urduData: null,
          langIndices: const {},
          slug: slugs[b],
          name: slugs[b],
        )!;
        corpus[slugs[b]] = assembled.hadiths;
      }
      var searchedChars = 0;
      for (final list in corpus.values) {
        for (final h in list) {
          searchedChars += h.textEnglish.length +
              h.textUrdu.length + h.chapterName.length;
        }
      }
      // HR-1.3's anti-blindness pin, and it lives HERE because this file owns
      // the generator: the fixture must stay as heavy as the corpus it stands
      // in for. The shipped bundle measures 423 chars of english text per row
      // (measured over all 36,390), so a generator whose mean drops under 350
      // has gone back to being a toy — and every timing in this file becomes
      // fiction again. That is exactly how HR-1 came to conclude "no indexed
      // pre-normalisation pass is indicated" from 58 ms scans of 145-char rows.
      final probe =
          (_decode(_syntheticBook(1, 60))!['hadiths'] as List)
              .cast<Map<String, dynamic>>();
      final probeMean = probe.fold<int>(
              0, (a, h) => a + (h['text'] as String).length) /
          probe.length;
      debugPrint('[HR1_BENCH] fixture weight: $probeMean english chars/row '
          '(the shipped bundle measures 423) — the timings below are only '
          'evidence while the two are the same order of magnitude');
      expect(probeMean, greaterThan(350.0),
          reason: 'the benchmark corpus went light again ($probeMean chars of '
              'english per row). Fold cost scales with text length, so a '
              'short-text benchmark is the gate that lied once already.');

      final ledgerRows =
          corpus.values.fold<int>(0, (a, b) => a + b.length);
      debugPrint('[HR1_BENCH] ledger corpus weight: $ledgerRows rows, '
          '$searchedChars searched chars, '
          '${(searchedChars / ledgerRows).round()} per row (the shipped '
          'bundle measures 1,436)');
      final onMain = Stopwatch()..start();
      scanHadithCorpus(corpus, ['namaz ka tarika'], maxPerQuery: 50);
      onMain.stop();
      expect(onMain.elapsedMicroseconds, greaterThan(1000),
          reason: 'the scan of 20,020 rows is real work — that is precisely why '
              'it must not sit on the keystroke path any more. Its cost here (in '
              'microseconds, on main, WITHOUT the corpus copy the old shape paid '
              'on top) is the number this pass moved off the UI thread.');
    });

    test('the worker survives 20 back-to-back queries without a respawn',
        () async {
      final worker = HadithSearchWorker();
      addTearDown(worker.shutdownForTest);
      await worker.noteBook(
          slug: 'bukhari', name: 'Sahih al-Bukhari', rawEnglish: _syntheticBook(1, 300));
      await worker.whenSettled();
      for (var i = 0; i < 20; i++) {
        final r = await worker.search(['patience'], maxPerQuery: 10);
        expect(r, isNotNull, reason: 'query $i lost the worker — a wedged '
            'isolate is the failure mode a per-app worker has to earn');
      }
      expect(worker.isLive, isTrue);
      expect(worker.handedBooks.length, 1,
          reason: 'one book, handed once — the worker is persistent, not a '
              'fresh isolate per query like Isolate.run was');
    });
  });
}
