// test/features/hadith/hadith_hotfix_hr21_coverage_census_test.dart
// ============================================================
// HOTFIX HR-2.1 § C — the "100 verified" table, as an executable pin.
//
// The owner's order was: "mujhe original urdu and eng dalna h arabic hata dena
// h pura hadith ka sara book 100 verified sab". Two of those clauses are facts
// about bytes on disk (which editions ship); the third is a claim about CONTENT
// — what fraction of every hadith actually carries each edition. A claim of that
// shape cannot live in a report, because a report does not fail when the data
// moves. So every number here is computed in this file, from the shipped JSON,
// with the loader's own join rule: the same rule `hadith_pass_x6_test.dart` uses
// for its two-book census, extended to all seven books and both editions.
//
// What this pins:
//   1. the bundle's shape — 15 files, 7 books × 2 editions + the section-name
//      sidecar, exact byte total, and no `arabic.json` anywhere;
//   2. the spine's integrity — 36,390 English rows, 1:1 under the loader's
//      fractional-aware `numberKey`, `reference.book`/`reference.hadith` present
//      on every row (this is the "the diet lost no row" proof);
//   3. per-book coverage of BOTH editions, the rows that have NEITHER (shown,
//      small as they are) and the Urdu rows the int-keyed join drops;
//   4. that this census is not a second opinion: the real `assembleHadithBook`
//      over the real files yields exactly these texts for the three books whose
//      data is awkward (key collisions, fractional numbers, an off-spine row);
//   5. that the Arabic edition cannot come back halfway: the identifiers that
//      carried it are absent from `lib/features/hadith` (code only — the shared
//      comment stripper is used), while the vocabulary HR-2.1 deliberately kept
//      (`arabicnumber` as a join key, `HadithMatchType.arabic` as X5 label
//      vocabulary) is asserted PRESENT, so a later cleanup cannot "finish" the
//      job by deleting the wrong things.
//
// Red evidence. Written against the A+B tree (24297a3 + 13f9f55) in a sandbox
// with no Dart SDK — CI is the only compiler, and the first compile of this file
// is the run of this commit, recorded with its numbers in
// docs/HADITH_HR_PASS_REPORT.md § C. Against the pre-diet tree at 865c3f8 it is
// red by construction: 22 asset files, 7 `arabic.json` blobs, a byte total
// 47,807,149 B larger, and `FoldedHadith` with four fields instead of three. It
// is red the moment the data moves, which is the entire point of pinning a
// coverage percentage instead of writing it down.
//
// Conventions match hadith_pass_x6_test / hadith_multilang_test: pure units
// where a helper carries a rule, source pins where the bug class is
// grep-visible.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/hadith/data/hadith_availability.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';

import '../../support/source_guards.dart';

/// The seven books, in the order the manifest and the availability matrix use.
const List<String> _books = [
  'bukhari',
  'muslim',
  'abudawud',
  'nasai',
  'ibnmajah',
  'malik',
  'tirmidhi',
];

const String _dir = 'assets/data/hadith';

/// The two editions HR-2.1 ships, DERIVED from the single source of truth rather
/// than written out again — a test that hardcodes the list is how an edition
/// sneaks back in through the door the selector no longer has.
final List<String> _editions = (['english', ...HadithAvailability.fileForLanguage.values])
    .toSet()
    .toList()
  ..sort();

/// Sum of the 15 files' own byte lengths, measured on the tree this commit
/// landed on. (`du -sb` of the directory reports 65,746,257 because it counts
/// the 8 directory entries as well; the arithmetic in § A/§ C of the report uses
/// file bytes, so this pin uses file bytes.) If a translation pass edits a file
/// this moves, and the size math has to be re-measured — which is what it is
/// for.
const int _bundleBytes = 65741265;

/// One decode per (book, edition) for the whole file. Reading 62 MB of JSON is
/// the expensive part of this test; doing it seven times because a helper is
/// convenient would make the suite slower for no evidence.
final Map<String, Map<String, dynamic>> _json = {};

Map<String, dynamic> _bookJson(String slug, String edition) =>
    _json.putIfAbsent(
      '$slug/$edition',
      () => jsonDecode(File('$_dir/$slug/$edition.json').readAsStringSync())
          as Map<String, dynamic>,
    );

List<Map<String, dynamic>> _rows(String slug, String edition) =>
    (_bookJson(slug, edition)['hadiths'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// The loader's tolerant hadithnumber parse (its private `_parseHadithNumber`):
/// leading digits of any scalar, else 0. The Urdu join is keyed by THIS int, so
/// a different rule here would measure a corpus the app never builds.
int _intKey(dynamic v) {
  if (v is num) return v.toInt();
  final m = RegExp(r'^(\d+)').firstMatch((v ?? '').toString());
  return m == null ? 0 : (int.tryParse(m.group(1)!) ?? 0);
}

/// The Urdu side map exactly as `assembleHadithBook` builds it: int key, LAST
/// write wins, a blank row overwriting an earlier non-blank one, text verbatim
/// (untrimmed). HR-2.2 kept this map as the PRIMARY source of a row's Urdu — it
/// is half the rule, not the whole one any more — and pins it beside the pair
/// rescue below. "Improving" either half in this file would pin a number no
/// reader ever sees.
final Map<String, Map<int, String>> _urduByBook = {};

/// HR-2.2's other half: the exact `pairKey` index over the same rows, built by
/// the service's own function so this census and the loader cannot disagree about
/// what "blanks skipped, first wins" means on a Tuesday.
final Map<String, Map<String, String>> _urduByPair = {};

Map<int, String> _urduMap(String slug) => _urduByBook.putIfAbsent(slug, () {
      final out = <int, String>{};
      for (final row in _rows(slug, 'urdu')) {
        out[_intKey(row['hadithnumber'])] = '${row['text'] ?? ''}';
      }
      return out;
    });

String _text(Map<String, dynamic> row) => '${row['text'] ?? ''}';

Map<String, String> _urduPairMap(String slug) => _urduByPair.putIfAbsent(
      slug,
      () => HadithDatabaseService.pairTextIndex(_rows(slug, 'urdu')),
    );

/// The shipped join, called through the shipped function.
String _urduTextOf(String slug, Map<String, dynamic> row) =>
    HadithDatabaseService.urduJoinText(
      byNumber: _urduMap(slug)[_intKey(row['hadithnumber'])] ?? '',
      byPair: _urduPairMap(slug)[
              HadithDatabaseService.pairKey(
                row['hadithnumber'],
                row['arabicnumber'],
              )] ??
          '',
    );

/// One book, both editions, as the reader will see it.
typedef _Census = ({
  int rows,
  int englishNonBlank,
  int urduNonBlank,
  int neither,
  int urduOffSpine,
  int spineCollisions,
  int brokenReferences,
});

_Census _census(String slug) {
  final spine = _rows(slug, 'english');
  final spineKeys = [for (final r in spine) _intKey(r['hadithnumber'])];
  var english = 0, urduHits = 0, neither = 0, broken = 0;
  for (final row in spine) {
    final en = _text(row).trim();
    final ur = _urduTextOf(slug, row).trim();
    if (en.isNotEmpty) english++;
    if (ur.isNotEmpty) urduHits++;
    if (en.isEmpty && ur.isEmpty) neither++;
    final ref = row['reference'];
    if (ref is! Map<String, dynamic> ||
        ref['book'] == null ||
        ref['hadith'] == null) {
      broken++;
    }
  }
  final onSpine = spineKeys.toSet();
  return (
    rows: spine.length,
    englishNonBlank: english,
    urduNonBlank: urduHits,
    neither: neither,
    urduOffSpine: urdu.keys.where((k) => !onSpine.contains(k)).length,
    spineCollisions: spineKeys.length - onSpine.length,
    brokenReferences: broken,
  );
}

final Map<String, _Census> _all = {for (final b in _books) b: _census(b)};

int get _totalRows => _all.values.fold<int>(0, (a, c) => a + c.rows);
int get _totalEnglish =>
    _all.values.fold<int>(0, (a, c) => a + c.englishNonBlank);
int get _totalUrdu => _all.values.fold<int>(0, (a, c) => a + c.urduNonBlank);
int get _totalNeither => _all.values.fold<int>(0, (a, c) => a + c.neither);
int get _totalCollisions =>
    _all.values.fold<int>(0, (a, c) => a + c.spineCollisions);
int get _totalUrduOffSpine =>
    _all.values.fold<int>(0, (a, c) => a + c.urduOffSpine);

void main() {
  group('HR-2.1 C — the bundle that ships is the bundle that was measured', () {
    test('15 files, two editions per book, no arabic.json survives', () {
      final expected = <String>{
        for (final b in _books) ...['english', 'urdu'].map((e) => '$b/$e.json'),
        'kitab_names.json',
      };
      final onDisk = Directory(_dir)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path
              .replaceAll(Platform.pathSeparator, '/')
              .substring(_dir.length + 1)) // past `_dir/`
          .toSet();
      expect(onDisk, expected,
          reason: 'the hadith bundle is exactly the two shipped editions plus '
              'the section-name sidecar; a third file here is either a '
              're-bundle (which must come with a selector entry and a census '
              'row) or a stray that must not ship');
      expect(onDisk.where((p) => p.endsWith('arabic.json')), isEmpty);
      expect(_editions, ['english', 'urdu']);
      expect(HadithAvailability.languageCodes, ['en', 'ur']);
      expect(HadithAvailability.fileForLanguage, const {'ur': 'urdu'});
      var bytes = 0;
      for (final rel in onDisk) {
        bytes += File('$_dir/$rel').lengthSync();
      }
      expect(bytes, _bundleBytes,
          reason: 'the report derives its size math (§ A: 108.29 MiB → 62.69 '
              'MiB, -47,807,149 B of Arabic) from these bytes; moving them '
              'means re-measuring the table, not re-typing it');
    });

    test('the sidecar names only the editions on disk (7 rows)', () {
      final manifest = jsonDecode(
        File('assets/data/content_manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final sources =
          (manifest['sources'] as List<dynamic>).cast<Map<String, dynamic>>();
      final hadith = sources
          .where((s) => '${s['id']}'.startsWith('hadith_') &&
              '${s['id']}' != 'hadith_kitab_names')
          .toList(growable: false);
      expect(hadith.length, 7,
          reason: 'one row per book — a new book needs a row AND a census entry');
      for (final row in hadith) {
        expect('${row['content']}', contains('en/ur JSON'),
            reason: '${row['id']} advertises an edition the bundle does not '
                'carry, which is a ledger a reader can install');
        expect('${row['language']}', 'en/ur',
            reason: '${row['id']}: `language` describes what THIS source path '
                'holds, and the path no longer holds Arabic');
      }
    });

    test('the spine is 36,390 English rows, 1:1, reference keys intact', () {
      expect(_totalRows, 36390);
      for (final entry in _all.entries) {
        expect(entry.value.brokenReferences, 0,
            reason: '${entry.key}: a row with no reference.book/hadith cannot '
                'be cited, and the reader would not know why it is blank');
      }
      // 1:1 under the loader's OWN fractional-aware key: 402.2 is a
      // sub-narration of 402, not a second copy of it (that distinction is
      // what `pairKey` exists for — Phase B, Rev. 2).
      for (final slug in _books) {
        final keys = _rows(slug, 'english')
            .map((r) => HadithDatabaseService.numberKey(r['hadithnumber']))
            .toList();
        expect(keys.every((k) => k.isNotEmpty), isTrue,
            reason: '$slug: an unusable key drops its row from the book '
                'silently, which is the failure this census exists to catch');
        expect(keys.toSet().length, keys.length,
            reason: '$slug: two rows sharing one key means one of them is '
                'invisible to the reader');
      }
    });

    test('the per-book coverage table: rows, english, urdu, NEITHER', () {
      // The measured truth of the shipped bundle. Counts AND percentages,
      // because the reader is shown the rounded percent and a rounded 100 can
      // hide a blank row (abudawud: 5,272 of 5,274 english).
      const expected = <String, ({int rows, int en, int ur, int neither})>{
        // HR-2.2 re-pin, old → new, on the urdu column only (english and the row
        // counts are untouched because the English join and the spine are):
        //   bukhari 6994→7019 (+25)  nasai 3875→3876 (+1)
        //   ibnmajah 4327→4329 (+2)   tirmidhi 3907→3931 (+24), neither 12→9
        'bukhari': (rows: 7589, en: 7580, ur: 7019, neither: 6),
        'muslim': (rows: 7563, en: 7360, ur: 7458, neither: 82),
        'abudawud': (rows: 5274, en: 5272, ur: 5273, neither: 0),
        'nasai': (rows: 5765, en: 5679, ur: 3876, neither: 82),
        'ibnmajah': (rows: 4343, en: 4340, ur: 4329, neither: 1),
        'malik': (rows: 1858, en: 1818, ur: 1590, neither: 23),
        'tirmidhi': (rows: 3998, en: 3926, ur: 3931, neither: 9),
      };
      expect(expected.values.fold<int>(0, (a, e) => a + e.rows), 36390);
      for (final entry in expected.entries) {
        final got = _all[entry.key]!;
        final want = entry.value;
        expect(got.rows, want.rows, reason: '${entry.key}: row count moved');
        expect(got.englishNonBlank, want.en,
            reason: '${entry.key}: english coverage moved');
        expect(got.urduNonBlank, want.ur,
            reason: '${entry.key}: urdu coverage moved');
        // The honest ceiling, shown however small.
        expect(got.neither, want.neither,
            reason: '${entry.key}: the rows with NEITHER edition are the only '
                'rows that can show a reader nothing at all — the report states '
                '203 corpus-wide since HR-2.2 recovered three of the 206, and if '
                'this moved so did that claim');
      }
      expect(HadithAvailability.coveragePercent(
          _all['nasai']!.urduNonBlank, _all['nasai']!.rows), 67);
      expect(HadithAvailability.coveragePercent(
          _all['malik']!.urduNonBlank, _all['malik']!.rows), 86);
      expect(HadithAvailability.coveragePercent(
          _all['bukhari']!.urduNonBlank, _all['bukhari']!.rows), 92);
      // And the disclosure rule those three numbers drive: exactly the thin
      // books get a note, and no other book does.
      final thin = HadithAvailability.thinCoverage({
        for (final entry in _all.entries)
          entry.key: {
            'en': (
              nonEmpty: entry.value.englishNonBlank,
              total: entry.value.rows
            ),
            'ur': (
              nonEmpty: entry.value.urduNonBlank,
              total: entry.value.rows
            ),
          },
      });
      expect({for (final r in thin) '${r.language}/${r.book}'}, {
        'ur/nasai',
        'ur/malik',
      },
          reason: 'the depth note the reader sees must come from these files, '
              'so an edition improving or regressing changes the UI in the same '
              'commit as the data — not one pass later');
    });

    test('the corpus totals the report prints, and what they are NOT', () {
      final rows = _totalRows;
      final en = _totalEnglish;
      final ur = _totalUrdu;
      final neither = _totalNeither;
      expect(rows, 36390);
      expect(en, 35975);
      expect(ur, 33476); // 33,424 + the 52 rows HR-2.2 rescues
      expect(neither, 203); // was 206; three tirmidhi rows gained Urdu
      expect(HadithAvailability.coveragePercent(en, rows), 99);
      expect(HadithAvailability.coveragePercent(ur, rows), 92);
      expect(rows - ur, 2914,
          reason: 'the HR-2 figure (2,966) minus the 52 rows HR-2.2 rescues: 2,914 of '
              '36,390 rows have no Urdu anywhere in the upstream files this '
              'bundle came from, so "100 % Urdu" is not a claim this data can '
              'support, and a re-join is not the same as a re-source');
      expect(rows - en, 415);
      expect(ur, lessThan(en),
          reason: 'urdu is the thinner edition; if that ever inverts, the '
              'fallback copy ("this language has nothing for this hadith") is '
              'pointing the wrong way and must be re-read');
      expect(neither / rows, lessThan(0.01),
          reason: 'the ceiling, in the reader\'s terms: 0.56 % of the corpus '
              'has no text in either shipped edition. Stated as a fraction so a '
              'later pass cannot round it to nothing — and so "every hadith '
              'shows Urdu or English" is always read WITH this number, never '
              'alone');
    });

    test('the join this census computes IS the join the app runs', () {
      // Three books chosen for how awkward their data is: bukhari (26 english
      // rows share an int key with a sibling), malik (31 fractional urdu rows
      // and the thinnest-but-one coverage) and muslim (one urdu row with no
      // usable hadithnumber, which the join drops).
      for (final slug in ['bukhari', 'malik', 'muslim']) {
        final spine = _rows(slug, 'english');
        final assembled = assembleHadithBook(
          englishData: _bookJson(slug, 'english'),
          urduData: _bookJson(slug, 'urdu'),
          langIndices: const {},
          slug: slug,
          name: HadithAvailability.bookDisplayNames[slug] ?? slug,
        );
        expect(assembled, isNotNull);
        // `LocalHadith` is declared in the SERVICE library
        // (hadith_database_service.dart:418), not in hadith_models.dart — the
        // first draft imported the models file for it and CI's `unused_import`
        // warning (run 43598073037) is the proof. No explicit annotation here:
        // the type is what `assembleHadithBook` returns, and this test asserts
        // on its fields.
        final hadiths = assembled!.hadiths;
        expect(hadiths.length, spine.length,
            reason: '$slug: the diet may not lose or invent one row');
        for (var i = 0; i < spine.length; i++) {
          final row = spine[i];
          final local = hadiths[i];
          expect(local.textEnglish, _text(row),
              reason: '$slug row ${row['hadithnumber']}: the rendered english is '
                  'the file text verbatim — the fold is applied to match, never '
                  'to store');
          expect(local.textUrdu, _urduTextOf(slug, row),
              reason: '$slug row ${row['hadithnumber']}: the census and the '
                  'loader disagree about which Urdu text this row gets, so every '
                  'coverage number in this file describes a different app '
                  '(HR-2.2: both sides now go through `urduJoinText`, so a '
                  'disagreement here means the JOIN moved, not the mirror)');
          expect(local.bookSlug, slug);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('the arithmetic of the key collision, disclosed not smoothed over',
        () {
      // `_parseHadithNumber` truncates, so `402.2` shares a URDU join key with
      // `402`: those rows still show their own english (the spine row) but get
      // whichever urdu text the map holds last. HR-2.2 did NOT re-join on the
      // pair key for these rows — it only rescues rows the int map left blank —
      // so the collision census below is still describing the shipped join.
      // 77 english rows across 4 books
      // are a second member of such a pair — 0.21 % of the corpus, pre-existing,
      // NOT introduced by HR-2.1, and not silently "fixed" either, because the
      // fix would re-join every book and change which text a reader is shown.
      expect(_totalCollisions, 77);
      expect(_all['bukhari']!.spineCollisions, 26);
      expect(_all['nasai']!.spineCollisions, 7);
      expect(_all['ibnmajah']!.spineCollisions, 2);
      expect(_all['tirmidhi']!.spineCollisions, 42);
      expect(_all['muslim']!.spineCollisions, 0);
      expect(_all['malik']!.spineCollisions, 0);
      expect(_all['abudawud']!.spineCollisions, 0);
      // One Urdu row in Muslim has no usable hadithnumber at all, so the join
      // has nothing to attach it to. Measured, so nobody calls it a lost hadith:
      // the english spine still shows it.
      expect(_totalUrduOffSpine, 1);
      expect(_all['muslim']!.urduOffSpine, 1);
    });

    test('the Arabic edition cannot come back halfway — the kept vocabulary '
        'stays', () {
      final files = Directory('lib/features/hadith')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(files.length, greaterThan(10));
      for (final f in files) {
        final src = stripCommentsForGuard(f.readAsStringSync());
        for (final gone in [
          'textArabic',
          'arabicData',
          'rawArabic',
          'showArabic',
          'hasArabic',
          'arabicPreview',
        ]) {
          expect(src.contains(gone), isFalse,
              reason: '${f.path} references `$gone`, which HR-2.1 removed with '
                  'the edition that held it — a field with no asset behind it '
                  'is how this pass half-reverts');
        }
      }
      // Deliberate survivors. `arabicnumber` is the scholarly hadith number and
      // the second half of `pairKey`; `HadithMatchType.arabic` is X5 label
      // vocabulary that outlives the bundle it was named after (the same
      // precedent that kept `textBengali`/`textFrench` for unbundled editions).
      final db = File(
        'lib/features/hadith/data/services/hadith_database_service.dart',
      ).readAsStringSync();
      expect(db.contains("map['arabicnumber']"), isTrue);
      expect(db.contains('pairKey'), isTrue);
      expect(db.contains('arabicNumber'), isTrue);
      final models =
          File('lib/features/hadith/data/models/hadith_models.dart')
              .readAsStringSync();
      expect(models.contains('enum HadithMatchType'), isTrue);
      expect(models.contains('arabic'), isTrue);
      // And the re-bundle seam HR-2.1 left in place: the matrix maps a language
      // code to a file, and the ONLY such map is empty today — so adding an
      // edition back is one row in one file, and this pin is what makes the
      // "we removed Arabic on purpose" note in the report stay true.
      final availability =
          File('lib/features/hadith/data/hadith_availability.dart')
              .readAsStringSync();
      expect(
          availability.contains(
            'static const Map<String, String> newLanguageFiles = {};',
          ),
          isTrue,
          reason: 'the documented seam for a future edition must exist, or the '
              'removal is a dead end instead of a reversible decision');
      expect(availability.contains('newLanguageFiles'), isTrue);
    });
  });
}
