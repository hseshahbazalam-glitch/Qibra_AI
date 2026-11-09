// lib → test/features/hadith/hadith_pass_h1_test.dart
//
// Pass H1 — kitab-names data layer, tirmidhi-grade honesty, selector
// parity disclosure, hadith token hygiene.
//
// Conventions (matching hadith_redesign_test / hadith_multilang_test):
// pure-function units, source guards, and REAL shipped JSON read from
// disk. No 234 MB corpus pumps here — CI's existing widget smokes
// cover the live loader. Every number pinned below is the verified
// 2026-09-25 census, not an estimate.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/hadith/data/hadith_availability.dart';
import 'package:qibra_ai/features/hadith/data/hadith_kitab_names.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart';

const List<String> _colls = [
  'bukhari',
  'muslim',
  'abudawud',
  'nasai',
  'tirmidhi',
  'ibnmajah',
  'malik',
];
const Map<String, String> _stems = {
  'en': 'english',
  'ar': 'arabic',
  'ur': 'urdu',
  'bn': 'bengali',
  'tr': 'turkish',
  'id': 'indonesian',
  'fr': 'french',
};

Map<String, dynamic> _book(String coll, String stem) => jsonDecode(
      File('assets/data/hadith/$coll/$stem.json').readAsStringSync(),
    ) as Map<String, dynamic>;

String _src(String path) => File(path).readAsStringSync();

/// Mirror of the loader's private int-truncating key for the historical
/// arabic/urdu join (hadithnumber only, leading digits). Kept as a
/// single 3-line function and pinned in test 12 against the service
/// source, so a loader change can never silently desync this mirror.
int _appNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  final m = RegExp(r'^(\d+)').firstMatch('$v');
  return m != null ? int.parse(m.group(1)!) : 0;
}

/// The joined coverage counts EXACTLY the way HadithDatabaseService
/// computes them before exposing `languageCoverage` (en counted on
/// itself; ar/ur via hadithnumber int-map, last wins, blanks included;
/// bn/tr/id/fr via the public runtime pairTextIndex — empty skipped,
/// first wins; absent file → 0).
Map<String, Map<String, ({int nonEmpty, int total})>> _coverageByBook() {
  final out = <String, Map<String, ({int nonEmpty, int total})>>{};
  for (final coll in _colls) {
    final en = _book(coll, 'english')['hadiths'] as List<dynamic>;
    final counts = <String, ({int nonEmpty, int total})>{};
    int nonEmpty(bool Function(int i) has) =>
        [for (var i = 0; i < en.length; i++) if (has(i)) i].length;
    counts['en'] = (
      nonEmpty: nonEmpty(
          (i) => '${(en[i] as Map)['text'] ?? ''}'.trim().isNotEmpty),
      total: en.length,
    );
    for (final lc in ['ar', 'ur']) {
      final hs = _book(coll, _stems[lc]!)['hadiths'] as List<dynamic>;
      final m = <int, String>{};
      for (final h in hs) {
        m[_appNum((h as Map)['hadithnumber'])] = '${h['text'] ?? ''}';
      }
      counts[lc] = (
        nonEmpty: nonEmpty((i) =>
            (m[_appNum((en[i] as Map)['hadithnumber'])] ?? '')
                .trim()
                .isNotEmpty),
        total: en.length,
      );
    }
    for (final lc in ['bn', 'tr', 'id', 'fr']) {
      final f = File('assets/data/hadith/$coll/${_stems[lc]}.json');
      if (!f.existsSync()) {
        counts[lc] = (nonEmpty: 0, total: en.length);
        continue;
      }
      final idx = HadithDatabaseService.pairTextIndex(
          (jsonDecode(f.readAsStringSync())['hadiths']) as List<dynamic>);
      counts[lc] = (
        nonEmpty: nonEmpty((i) => idx
            .containsKey(HadithDatabaseService.pairKey(
                (en[i] as Map)['hadithnumber'],
                (en[i] as Map)['arabicnumber']))),
        total: en.length,
      );
    }
    out[coll] = counts;
  }
  return out;
}

void main() {
  // M6RED-REPORT (transient): name the culprit test on failure —
  // same annotation channel as the M5 TALLY, one tearDown, deleted
  // with the probe commit.
  tearDown(() {
    if (testState == TestState.failed) {
      print('::error::M6RED ${testCase.name}');
    }
  });

  group('Pass H1 · kitab names — no invention, honest fallback', () {
    test('ledger ⇄ shipped data: the 3 unnamed refs are EXACTLY the census',
        () {
      final ledger = jsonDecode(
              File('assets/data/hadith/kitab_names.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(ledger['schema'], 'qibra.kitab_names.v1');
      final sectionsByColl = <String, Map<String, String>>{};
      final refsByColl = <String, Set<int>>{};
      for (final coll in _colls) {
        final data = _book(coll, 'english');
        sectionsByColl[coll] =
            ((data['metadata'] as Map)['sections'] as Map).cast<String, String>();
        refsByColl[coll] = {
          for (final h in data['hadiths'] as List<dynamic>)
            _appNum((h as Map)['reference']?['book']),
        };
      }
      final unnamed = HadithKitabNames.unnamedRefs(sectionsByColl, refsByColl);
      expect(unnamed, {'bukhari/0', 'nasai/0', 'malik/0'});
      // Cross-check with the sidecar ledger entry-by-entry.
      final ledgerRefs = <String>{
        for (final e
            in (ledger['unnamedBookRefs'] as Map<String, dynamic>).entries)
          for (final n in (e.value as List<dynamic>)) '${e.key}/$n',
      };
      expect(unnamed, ledgerRefs);
      // The 399 referenced (collection, book_number) pairs — the honest
      // matched-vs-unknown ratio (396 named, 3 not). The pass spec's
      // '401' predated this app-side recount; raw file book values are
      // themselves 399 distinct (no fractional folding here).
      final totalRefs =
          refsByColl.values.map((s) => s.length).reduce((a, b) => a + b);
      expect(totalRefs, 399);
    });

    test('sections dicts: key counts, blank sentinels, language-invariance',
        () {
      const keyCounts = {
        'bukhari': 98,
        'muslim': 57,
        'abudawud': 44,
        'nasai': 52,
        'tirmidhi': 50,
        'ibnmajah': 38,
        'malik': 62,
      };
      for (final coll in _colls) {
        final en = _book(coll, 'english');
        final secs = (en['metadata'] as Map)['sections'] as Map;
        expect(secs.length, keyCounts[coll], reason: coll);
        for (final e in secs.entries) {
          if ((e.value as String).trim().isEmpty) {
            expect(e.key, '0', reason: '$coll blank name on non-sentinel!');
          }
        }
        // Upstream finding: every edition shares the SAME English dict.
        for (final lc in _stems.keys.where((l) => l != 'en')) {
          final f = File('assets/data/hadith/$coll/${_stems[lc]}.json');
          if (!f.existsSync()) continue;
          final other = ((jsonDecode(f.readAsStringSync())
                  as Map<String, dynamic>)['metadata'] as Map)['sections']
              as Map;
          expect(other, secs, reason: '$coll/$lc sections drifted from en');
        }
      }
    });

    test('accessor: names real, sentinels null, NOTHING is invented', () {
      final secs = (  _book('bukhari', 'english')['metadata'] as Map)['sections']
          as Map;
      final s = secs.cast<String, String>();
      expect(HadithKitabNames.name(s, 1), 'Revelation');
      expect(HadithKitabNames.name(s, 0), isNull);
      expect(HadithKitabNames.name(s, 4242), isNull); // never guess
      expect(HadithKitabNames.name(const {'7': '   '}, 7), isNull);
      expect(HadithKitabNames.name(const {'7': ' Guarded '}, 7), 'Guarded');
    });

    test('chip fallback: unnamed renders the i18n label, no dangling colon',
        () {
      expect(HadithBookScreen.chapterChipLabel(0, '', 'Book 0'), 'Book 0');
      expect(HadithBookScreen.chapterChipLabel(0, '   ', 'Book 0'), 'Book 0');
      expect(HadithBookScreen.chapterChipLabel(1, 'Revelation', 'Book 1'),
          'Ch 1: Revelation');
      final en = AppStrings.forCode('en');
      final ar = AppStrings.forCode('ar');
      final ur = AppStrings.forCode('ur');
      expect(en.hadithKitabLabel(0), 'Book 0');
      expect(ar.hadithKitabLabel(0).contains('\u0643\u062a\u0627\u0628'),
          isTrue); // 'كتاب 0'
      expect(ur.hadithKitabLabel(0).contains('\u06a9\u062a\u0627\u0628'),
          isTrue); // 'کتاب 0'
      // Wired into the book screen (source guard — the raw string never
      // exists; only the getter does):
      final bookSrc =
          _src('lib/features/hadith/presentation/hadith_book_screen.dart');
      expect(bookSrc.contains('HadithBookScreen.chapterChipLabel('), isTrue);
      expect(bookSrc.contains('hadithKitabLabel'), isTrue);
    });

    test('the provider takes names through the accessor (one window)', () {
      expect(_src('lib/features/hadith/providers/hadith_provider.dart')
          .contains('HadithKitabNames.name(bookInfo.sections'), isTrue);
    });
  });

  group('Pass H1 · grades — recorded where recorded, silent where silent',
      () {
    test('grade-presence census (English files, 2026-09-25)', () {
      const withGrades = {
        'bukhari': 0,
        'muslim': 0,
        'abudawud': 5274,
        'nasai': 5758,
        'tirmidhi': 3954,
        'ibnmajah': 4341,
        'malik': 1858,
      };
      for (final coll in _colls) {
        final hs = _book(coll, 'english')['hadiths'] as List<dynamic>;
        final n = hs
            .where((h) => ((h as Map)['grades'] as List<dynamic>?) != null &&
                (h['grades'] as List).isNotEmpty)
            .length;
        expect(n, withGrades[coll], reason: coll);
      }
    });

    test('Tirmidhi grader names + grade values are the shipped census', () {
      final hs = _book('tirmidhi', 'english')['hadiths'] as List<dynamic>;
      final graders = <String>{}, values = <String>{};
      for (final h in hs) {
        for (final g in ((h as Map)['grades'] as List<dynamic>?) ?? const []) {
          graders.add('${(g as Map)['name'] ?? ''}');
          values.add('${g['grade'] ?? ''}');
        }
      }
      for (final grader in ['Shakir', 'Al-Albani', 'Zubair', 'Maarouf']) {
        expect(graders.any((g) => g.contains(grader)), isTrue, reason: grader);
      }
      for (final v in ['Sahih', 'Hasan', 'Daif', 'Hasan Sahih', 'Daif Isnaad',
        'Shadh', 'Munkar', 'Mawdu']) {
        expect(values, contains(v));
      }
    });

    test('fromString: current flattening pinned (enum cannot lose nuance '
        'silently — compound/other verdicts map exactly as documented)', () {
      expect(HadithGrade.fromString('Sahih'), HadithGrade.sahih);
      expect(HadithGrade.fromString('Hasan'), HadithGrade.hasan);
      // Compound verdicts flatten to the stronger enum member BY DESIGN
      // of the pre-existing parser — pinned here so any change is loud.
      expect(HadithGrade.fromString('Hasan Sahih'), HadithGrade.sahih);
      expect(HadithGrade.fromString('Sahih Isnaad'), HadithGrade.sahih);
      expect(HadithGrade.fromString('Daif'), HadithGrade.daif);
      expect(HadithGrade.fromString('Very Daif'), HadithGrade.daif);
      expect(HadithGrade.fromString('Daif Isnaad'), HadithGrade.daif);
      expect(HadithGrade.fromString('Mawdu'), HadithGrade.mawdu);
      // Verdicts with no enum member → unknown, NEVER defaulted to
      // something flattering:
      expect(HadithGrade.fromString('Shadh'), HadithGrade.unknown);
      expect(HadithGrade.fromString('Munkar'), HadithGrade.unknown);
      expect(HadithGrade.fromString('Maqtu'), HadithGrade.unknown);
      expect(HadithGrade.fromString(''), HadithGrade.unknown);
      expect(HadithGrade.fromString(null), HadithGrade.unknown);
    });

    test('detail sheet: absent grade shows the honest line, not silence', () {
      final src =
          _src('lib/features/hadith/presentation/hadith_book_screen.dart');
      expect(src.contains('] else ...['), isTrue);
      expect(src.contains('hadithGradeNotRecorded'), isTrue);
      expect(
          src.contains(
              "AppStrings.of(context).hadithGradeNotRecorded"),
          isTrue);
      // Never a raw hardcoded literal (i18n census rule):
      expect(src.contains("Text('Grade not recorded'"), isFalse);
      final en = AppStrings.forCode('en');
      final ar = AppStrings.forCode('ar');
      expect(en.hadithGradeNotRecorded, 'Grade not recorded');
      expect(ar.hadithGradeNotRecorded, isNot(en.hadithGradeNotRecorded));
      expect(ar.hadithGradeNotRecorded.trim().isNotEmpty, isTrue);
      expect(AppStrings.forCode('ur').hadithGradeNotRecorded.trim().isNotEmpty,
          isTrue);
      // The pre-existing Bukhari/Muslim collection rule is UNTOUCHED.
      expect(_src('lib/features/hadith/providers/hadith_provider.dart')
          .contains('HadithGrade.sahih'), isTrue);
    });
  });

  group('Pass H1 · parity disclosure — computed coverage, zero placeholders',
      () {
    test('coveragePercent: rounded, not floored; total<=0 → 0', () {
      expect(HadithAvailability.coveragePercent(629, 5765), 11);
      expect(HadithAvailability.coveragePercent(4927, 7563), 65);
      expect(HadithAvailability.coveragePercent(6858, 7589), 90);
      expect(HadithAvailability.coveragePercent(3998, 3998), 100);
      expect(HadithAvailability.coveragePercent(0, 3998), 0);
      expect(HadithAvailability.coveragePercent(12, 0), 0);
    });

    test('thinCoverage: <90 disclosed, ==90 silent, absent always, no '
        'counts → no rows beyond the matrix-derived absent ones', () {
      Map<String, ({int nonEmpty, int total})> m(
              int ne, int tot) =>
          {
            for (final lc in HadithAvailability.languageCodes)
              lc: (nonEmpty: lc == 'fr' ? 0 : ne, total: tot)
          };
      final rows = HadithAvailability.thinCoverage({
        'bukhari': m(7000, 7589), // 92% present langs → silent; fr forced 0
        'nasai': m(500, 5765), // ~9% → every present lang disclosed
        'tirmidhi': const {}, // unresolved counts → only 'fr' absent row
      });
      final keys = {for (final r in rows) '${r.language}/${r.book}'}.toList();
      expect(keys, contains('fr/tirmidhi'));
      expect(rows.firstWhere((r) => r.language == 'fr' && r.book == 'tirmidhi').absent,
          isTrue);
      expect(rows.any((r) => r.book == 'bukhari' && r.language != 'fr'),
          isFalse); // 92% ≥ 90 → silent (fr/bukhari shows: counted 0%)
      expect(rows.every((r) => r.percent < 90 || r.absent), isTrue);
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i].percent >= rows[i - 1].percent, isTrue);
      }
      // Threshold is strict (< 90): 90 exactly stays silent.
      final edge = HadithAvailability.thinCoverage({
        'muslim': {
          'tr': (nonEmpty: 6807, total: 7563), // 90.01→90 → silent
          'id': (nonEmpty: 6805, total: 7563), // 90% → silent
          'fr': (nonEmpty: 6730, total: 7563), // 89% → disclosed
        },
      });
      expect(edge.map((r) => r.language).toSet(), {'fr'});
    });

    test('real corpus → EXACTLY ten disclosure rows (98→silent honesty)',
        () {
      final rows = HadithAvailability.thinCoverage(_coverageByBook());
      final set = {
        for (final r in rows)
          (language: r.language, book: r.book, percent: r.percent, absent: r.absent),
      };
      expect(set, {
        (language: 'fr', book: 'tirmidhi', percent: 0, absent: true),
        (language: 'tr', book: 'nasai', percent: 11, absent: false),
        (language: 'id', book: 'muslim', percent: 65, absent: false),
        (language: 'ur', book: 'nasai', percent: 67, absent: false),
        (language: 'fr', book: 'malik', percent: 81, absent: false),
        (language: 'id', book: 'abudawud', percent: 84, absent: false),
        (language: 'id', book: 'malik', percent: 84, absent: false),
        (language: 'tr', book: 'malik', percent: 84, absent: false),
        (language: 'ur', book: 'malik', percent: 86, absent: false),
        (language: 'id', book: 'tirmidhi', percent: 89, absent: false),
      });
      expect(rows.first.absent, isTrue); // 0% sorts first
    });

    test('selector matrix + selectorOptions: FROZEN byte-for-byte (the '
        '"6 of 7" multilang pin and the settings sheet both keep seeing '
        'exactly the pre-H1 rows)', () {
      expect(HadithAvailability.languageCodes,
          ['en', 'ar', 'ur', 'bn', 'tr', 'id', 'fr']);
      expect(HadithAvailability.labelFor, {
        'en': 'English',
        'ar': 'العربية',
        'ur': 'اردو',
        'bn': 'বাংলা',
        'tr': 'Türkçe',
        'id': 'Bahasa Indonesia',
        'fr': 'Français',
      });
      expect(HadithAvailability.fileForLanguage, {
        'ar': 'arabic',
        'ur': 'urdu',
        'bn': 'bengali',
        'tr': 'turkish',
        'id': 'indonesian',
        'fr': 'french',
      });
      expect(HadithAvailability.newLanguageFiles,
          {'bn': 'bengali', 'tr': 'turkish', 'id': 'indonesian', 'fr': 'french'});
      for (final coll in _colls) {
        for (final lc in HadithAvailability.languageCodes) {
          expect(HadithAvailability.hasBook(lc, coll), lc != 'fr' || coll != 'tirmidhi',
              reason: '$lc/$coll matrix drift');
        }
      }
      expect(HadithAvailability.selectorOptions(), [
        (code: 'en', label: 'English', note: null),
        (code: 'ar', label: 'العربية', note: null),
        (code: 'ur', label: 'اردو', note: null),
        (code: 'bn', label: 'বাংলা', note: null),
        (code: 'tr', label: 'Türkçe', note: null),
        (code: 'id', label: 'Bahasa Indonesia', note: null),
        (code: 'fr', label: 'Français', note: '6 of 7 collections'),
      ]);
    });

    test('bookDisplayNames match the loader table (no third spelling of a '
        'title)', () {
      final svc = _src(
          'lib/features/hadith/data/services/hadith_database_service.dart');
      expect(HadithAvailability.bookDisplayNames.keys.toSet(), _colls.toSet());
      for (final e in HadithAvailability.bookDisplayNames.entries) {
        expect(
            svc.contains("'${e.key}': '${e.value}'".replaceAll("'", "'")) ||
                // nasai is written with an escaped quote in the service:
                (e.key == 'nasai' &&
                    svc.contains(r"'nasai': 'Sunan an-Nasa\'i'")) ||
                (e.key == 'tirmidhi' &&
                    svc.contains("'tirmidhi': 'Jami` at-Tirmidhi'")),
            isTrue,
            reason: '${e.key} display-name drift');
      }
    });

    test('the wiring is live at all three surfaces (source guards)', () {
      final svc = _src(
          'lib/features/hadith/data/services/hadith_database_service.dart');
      expect(svc.contains('_languageCoverage[slug] = {'), isTrue);
      expect(svc.contains('get languageCoverage =>'), isTrue);
      // The mirror above must keep matching the loader's private int
      // truncation for the ar/ur join — pin its exact mechanism:
      expect(svc.contains(r"RegExp(r'^(\d+)')"), isTrue);
      final prov =
          _src('lib/features/hadith/providers/hadith_provider.dart');
      expect(
          prov.contains(
              'hadithLanguageCoverageProvider = FutureProvider'),
          isTrue);
      expect(
          prov.contains('await ref.watch(hadithDatabaseInitProvider.future)'),
          isTrue);
      final book =
          _src('lib/features/hadith/presentation/hadith_book_screen.dart');
      expect(book.contains('ref.read(hadithLanguageCoverageProvider)') &&
          book.contains('depthNote(option.code)') &&
          book.contains('hadithNotAvailableForBook'), isTrue);
      final settings =
          _src('lib/features/settings/presentation/settings_screen.dart');
      expect(
          settings.contains('HadithAvailability.thinCoverage(') &&
              settings.contains('hadithNoEditionFor(') &&
              settings.contains('hadithThinCoverage(') &&
              settings.contains('ref.read(hadithLanguageCoverageProvider)'),
          isTrue);
    });

    test('disclosure strings: exact English, real ar/ur (no machine filler)',
        () {
      final en = AppStrings.forCode('en');
      expect(en.hadithCoverageOfBook(11), '11% of this book');
      expect(en.hadithNotAvailableForBook, 'not available for this book');
      expect(
          en.hadithThinCoverage('Türkçe', "Sunan an-Nasa'i", 11),
          'Türkçe: 11% of Sunan an-Nasa\'i');
      expect(
          en.hadithNoEditionFor('Français', 'Jami` at-Tirmidhi'),
          'Français is not available for Jami` at-Tirmidhi');
      for (final code in ['ar', 'ur']) {
        final s = AppStrings.forCode(code);
        expect(s.hadithCoverageOfBook(11), isNot(en.hadithCoverageOfBook(11)));
        expect(s.hadithNotAvailableForBook,
            isNot(en.hadithNotAvailableForBook));
        expect(s.hadithNoEditionFor('X', 'Y').contains('X'), isTrue);
        expect(s.hadithNoEditionFor('X', 'Y').contains('Y'), isTrue);
      }
    });
  });

  group('Pass H1 · token hygiene + provenance guards', () {
    test('hadith_models.dart carries ZERO raw hexes; enum colors ARE the '
        'navy-ramp tokens (value-identical swap)', () {
      final src =
          _src('lib/features/hadith/data/models/hadith_models.dart');
      expect(RegExp(r'Color\(0x').hasMatch(src), isFalse);
      expect(RegExp(r'0xFF[0-9A-Fa-f]{6}').hasMatch(src), isFalse);
      expect(HadithGrade.sahih.color, AppEmerald.s500);
      expect(HadithGrade.hasan.color, AppEmerald.s400);
      expect(HadithGrade.daif.color, AppGold.s500);
      expect(HadithGrade.mawdu.color, AppSemanticColors.error);
      expect(HadithGrade.unknown.color, AppNeutral.s500);
      final bySlug = {for (final b in popularHadithBooks) b.name: b.color};
      expect(bySlug['Sahih al-Bukhari'], AppEmerald.s500);
      expect(bySlug['Sahih Muslim'], AppEmerald.s400);
      expect(bySlug['Sunan Abu Dawud'], AppGold.s700);
      // (The legacy model list spells 'Sunan Abu Dawud'; the loader and
      // bookDisplayNames spell 'Sunan Abi Dawud' — two tables, pinned
      // against THEIR OWN sources by design above.)
      expect(bySlug['Jami at-Tirmidhi'], AppGold.s500);
    });

    test('no capitalized same-line Text literals in lib/features/hadith '
        '(i18n census rule, mirrored line-by-line from the global guard — '
        'per-line so Dart\'s \\s≡newline quirk cannot fire across rows)', () {
      final rx = RegExp(r"Text\(\s*'[A-Z]");
      for (final f in Directory('lib/features/hadith')
          .listSync(recursive: true)
          .whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        for (final line in f.readAsLinesSync()) {
          expect(rx.hasMatch(line), isFalse,
              reason: '${f.path}: untranslated literal ${line.trim()}');
        }
      }
    });

    test('manifest carries the ledger entry with UNKNOWN honesty', () {
      final manifest =
          ((jsonDecode(File('assets/data/content_manifest.json')
                  .readAsStringSync()) as Map)['sources'])
              as List<dynamic>;
      final entry = manifest
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['id'] == 'hadith_kitab_names');
      expect(entry['source'], 'assets/data/hadith/kitab_names.json');
      expect(entry['status'], 'UNKNOWN');
      expect(entry['copyright_status'], 'UNKNOWN');
      expect(entry['commercial_use'], 'UNKNOWN');
      expect(
          '${entry['license']}',
          allOf(contains('Unlicense'),
              contains('per-translator'))); // honesty granularity kept
      expect(File(entry['source'] as String).existsSync(), isTrue);
    });

    test('the sidecar ships NO name data (ledger only) and stays outside '
        'the hadith file validator\'s 21-file scan pattern', () {
      final ledger =
          jsonDecode(File('assets/data/hadith/kitab_names.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(ledger.keys, isNot(contains('sections')));
      expect(ledger.keys, isNot(contains('names')));
      // The validator scans assets/data/hadith/<coll>/<lang>.json only.
      final perBook = RegExp(r'^[a-z]+/[a-z]+\.json$');
      expect(perBook.hasMatch('kitab_names.json'), isFalse);
      final entries = Directory('assets/data/hadith').listSync();
      expect(entries.whereType<File>().length, 1); // the sidecar alone
      expect(entries.whereType<Directory>().length, 7); // the collections
    });
  });
}
