// test/hadith_multilang_test.dart
// ============================================================
// QIBRA AI — HADITH MULTI-LANGUAGE (PHASE B) PINS
// ============================================================
// The Phase B promise, made executable: four extra languages
// (Bengali/Turkish/Indonesian/French) ship per book, are joined to OUR
// records ONLY by the (hadithnumber, arabicnumber) pair, fall back
// honestly when a hadith has no text in the selected language, and the
// Settings selector is DERIVED from the availability matrix — never
// hardcoded. These tests read the real bundled JSON (no fixtures
// substituted for corpus data).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/hadith/data/hadith_availability.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';

Map<String, dynamic> _readAsset(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _hadithsOf(String path) =>
    (_readAsset(path)['hadiths'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

// Join keys in these tests call the RUNTIME function itself
// (HadithDatabaseService.pairKey) — re-implementing the normalization in
// the test is exactly how Rev. 1's floor-collapse escaped review. Rev. 2
// keys are exact and fractional-aware: 402 and 402.2 are different hadiths.
String _pairOf(Map<String, dynamic> rec) =>
    HadithDatabaseService.pairKey(rec['hadithnumber'], rec['arabicnumber']);

bool _unjoinable(Map<String, dynamic> rec) {
  final h = HadithDatabaseService.numberKey(rec['hadithnumber']);
  return h.isEmpty || h == '0';
}

void main() {
  const books = kHadithBookSlugs;
  const newLangs = {'bn': 'bengali', 'tr': 'turkish', 'id': 'indonesian', 'fr': 'french'};

  group('availability matrix ⇔ data on disk', () {
    test('every advertised (language, book) file exists and parses', () {
      for (final entry in HadithAvailability.booksForLanguage.entries) {
        final code = entry.key;
        final covered = entry.value;
        for (final slug in books) {
          final stem =
              code == 'en' ? 'english' : HadithAvailability.fileForLanguage[code]!;
          final file = File('assets/data/hadith/$slug/$stem.json');
          expect(covered.contains(slug), file.existsSync(),
              reason: 'matrix says coverage=$covered but $file '
                  '${file.existsSync() ? "EXISTS" : "is absent"}');
          if (file.existsSync()) {
            expect(_hadithsOf(file.path), isNotEmpty, reason: file.path);
          }
        }
      }
    });

    test('French is six-of-seven: fra-tirmidhi absent by data, no placeholder', () {
      expect(File('assets/data/hadith/tirmidhi/french.json').existsSync(), isFalse,
          reason: 'the dataset has no fra-tirmidhi edition — the matrix must '
              'NOT claim it, and no empty placeholder may be shipped');
      expect(HadithAvailability.hasBook('fr', 'tirmidhi'), isFalse);
      expect(HadithAvailability.bookCount('fr'), 6);
    });

    test('selector options are the seven language codes, labels native', () {
      final options = HadithAvailability.selectorOptions();
      expect(options.map((o) => o.code), ['en', 'ar', 'ur', 'bn', 'tr', 'id', 'fr']);
      expect(options.firstWhere((o) => o.code == 'fr').note, contains('6 of 7'));
      expect(options.firstWhere((o) => o.code == 'bn').label, 'বাংলা');
      expect(options.firstWhere((o) => o.code == 'tr').label, 'Türkçe');
      expect(options.firstWhere((o) => o.code == 'id').label, 'Bahasa Indonesia');
    });

    test('the language notifier DERIVES from the matrix (no hardcoded set)', () {
      expect(HadithLanguageNotifier.supported,
          HadithAvailability.languageCodes.toSet());
    });
  });

  group('key-join invariants (never positional)', () {
    test('every language record key exists in the book english.json', () {
      // Texts are present (the extractor dropped empties): an unmatched
      // hadith must be ABSENT from the language file, never carried as ''.
      for (final slug in books) {
        final basePairs = _hadithsOf('assets/data/hadith/$slug/english.json')
            .where((r) => !_unjoinable(r))
            .map(_pairOf)
            .toSet();
        for (final lang in newLangs.entries) {
          final file = 'assets/data/hadith/$slug/${lang.value}.json';
          if (!File(file).existsSync()) continue;
          for (final rec in _hadithsOf(file)) {
            expect(basePairs.contains(_pairOf(rec)), isTrue,
                reason: '$file: orphan key ${_pairOf(rec)} not in base');
            expect((rec['text'] as String).trim(), isNotEmpty,
                reason: '$file #${rec['hadithnumber']}: empty text must be '
                    'dropped, not shipped');
          }
        }
      }
    });

    test('language files mirror base records 1:1 and in base order', () {
      // Rev. 2 contract: one language record per MATCHED base record,
      // numbers/reference copied from the BASE record itself (never from
      // the dataset). Two-pointer subsequence check — the strictest form
      // that survives intentional drops (unmatched/empty dataset texts).
      for (final slug in books) {
        final base = _hadithsOf('assets/data/hadith/$slug/english.json');
        for (final lang in newLangs.entries) {
          final file = 'assets/data/hadith/$slug/${lang.value}.json';
          if (!File(file).existsSync()) continue;
          final langRecs = _hadithsOf(file);
          var i = 0;
          for (final rec in langRecs) {
            var found = false;
            while (i < base.length) {
              final b = base[i++];
              if (_unjoinable(b)) continue;
              if (_pairOf(b) == _pairOf(rec)) {
                expect(rec['hadithnumber'], b['hadithnumber'],
                    reason: '$file: hadithnumber must ride base verbatim');
                expect(rec['arabicnumber'], b['arabicnumber'],
                    reason: '$file: arabicnumber must ride base verbatim');
                expect(rec['reference'], b['reference'],
                    reason: '$file: reference must ride base verbatim');
                found = true;
                break;
              }
            }
            expect(found, isTrue,
                reason: '$file: record ${rec['hadithnumber']} does not '
                    'mirror a base record in order');
          }
        }
      }
    });

    test('REV. 2 — fractional records are SEPARATE hadiths (the 402 case)', () {
      // bengali bukhari 402.2 is a chapter citation whose dataset text
      // is EMPTY -> it must be absent (fallback), and the parent 402 must
      // carry ONLY its own text. The Rev. 1 floor-join shipped the parent
      // text to BOTH; this pin makes that regression impossible.
      final bn = _hadithsOf('assets/data/hadith/bukhari/bengali.json');
      expect(
          bn.where((r) =>
              HadithDatabaseService.numberKey(r['hadithnumber']) == '402.2'),
          isEmpty,
          reason: 'ben has no text for 402.2 — shipping one would fabricate');
      final bnParent = bn.where((r) => _pairOf(r) == '402|402').toList();
      expect(bnParent.length, 1);
      expect(bnParent.single['reference'], {'book': 8, 'hadith': 53});

      // french 402.2 DOES have its own text in the dataset (the citation
      // sentence) — Rev. 1 dropped it as a 'duplicate'; Rev. 2 ships it.
      final fr = _hadithsOf('assets/data/hadith/bukhari/french.json');
      final frFrac = fr.where((r) =>
          HadithDatabaseService.numberKey(r['hadithnumber']) == '402.2').toList();
      expect(frFrac.length, 1);
      expect((frFrac.single['text'] as String).startsWith('Rapporté par Anas'),
          isTrue);
      expect(frFrac.single['text'] != bnParent.single['text'], isTrue,
          reason: 'the citation text must not be the parent hadith text');

      // tirmidhi's ten-record 3604.x bundle: dataset texts are ALL empty
      // in bengali -> no 3604-series record may ship for that language.
      final tirmBn = _hadithsOf('assets/data/hadith/tirmidhi/bengali.json');
      for (var n = 0; n <= 9; n++) {
        final key =
            n == 0 ? '3604' : '3604.${n.toString().padLeft(2, '0')}';
        expect(
            tirmBn.where((r) =>
                HadithDatabaseService.numberKey(r['hadithnumber']) == key),
            isEmpty,
            reason: 'empty dataset text must not be padded into a match');
      }
    });

    test('spot hadiths carry identical numbers+reference across all languages', () {
      // of the book (text differs; keys cannot).
      for (final (slug, number) in [('bukhari', 1), ('abudawud', 2000), ('malik', 900)]) {
        final byLang = <String, Map<String, dynamic>>{};
        for (final r in _hadithsOf('assets/data/hadith/$slug/english.json')) {
          if (r['hadithnumber'] == number) {
            byLang['en'] = r;
            break;
          }
        }
        for (final lang in newLangs.entries) {
          final file = 'assets/data/hadith/$slug/${lang.value}.json';
          if (!File(file).existsSync()) continue;
          for (final r in _hadithsOf(file)) {
            if (r['hadithnumber'] == number) {
              byLang[lang.key] = r;
              break;
            }
          }
        }
        expect(byLang['en'], isNotNull);
        for (final entry in byLang.entries) {
          expect(entry.value['hadithnumber'], byLang['en']!['hadithnumber'],
              reason: '$slug#$number ${entry.key}: hadithnumber drifted');
          expect(entry.value['arabicnumber'], byLang['en']!['arabicnumber'],
              reason: '$slug#$number ${entry.key}: arabicnumber drifted');
          expect(entry.value['reference'], byLang['en']!['reference'],
              reason: '$slug#$number ${entry.key}: reference drifted');
        }
      }
    });
  });

  group('service join semantics (exact, fractional-aware)', () {
    test('numberKey canonicalizes int/double/string alike — never floors', () {
      expect(HadithDatabaseService.numberKey(402), '402');
      expect(HadithDatabaseService.numberKey('402'), '402');
      expect(HadithDatabaseService.numberKey(402.0), '402');
      expect(HadithDatabaseService.numberKey('446.00'), '446');
      expect(HadithDatabaseService.numberKey(402.2), '402.2');
      expect(HadithDatabaseService.numberKey('402.20'), '402.2');
      expect(HadithDatabaseService.numberKey(null), '');
    });

    test('pairKey: arabic 0 -> hadith num; fractions NEVER collapse onto the parent', () {
      expect(HadithDatabaseService.pairKey(10, 0), '10|10');
      expect(HadithDatabaseService.pairKey(10, 3), '10|3');
      expect(HadithDatabaseService.pairKey('1001', '446'), '1001|446');
      expect(HadithDatabaseService.pairKey(402.2, 402.2), '402.2|402.2');
      expect(
          HadithDatabaseService.pairKey(402, 402) ==
              HadithDatabaseService.pairKey(402.2, 402.2),
          isFalse,
          reason: 'the Rev. 1 collapse: 402 and 402.2 are different hadiths');
    });

    test('pairTextIndex: blanks skipped, arabicnumber-0 fallback, first wins',
        () {
      final index = HadithDatabaseService.pairTextIndex([
        {'hadithnumber': 1, 'arabicnumber': 0, 'text': 'one'},
        {'hadithnumber': '1001', 'arabicnumber': '446', 'text': 'thousand-one'},
        {'hadithnumber': 2, 'arabicnumber': '3033.02', 'text': 'fractional'},
        {'hadithnumber': 3, 'arabicnumber': 3, 'text': '   '}, // blank -> skip
        {'hadithnumber': 1, 'arabicnumber': 0, 'text': 'IGNORED'}, // dup
        {'hadithnumber': 0, 'arabicnumber': 0, 'text': 'zero-pair'},
        {'hadithnumber': 'abc', 'arabicnumber': 1, 'text': 'non-numeric'},
      ]);
      expect(index['1|1'], 'one');
      expect(index['1001|446'], 'thousand-one');
      expect(index['2|3033.02'], 'fractional');
      expect(index.containsKey('3|3'), isFalse,
          reason: 'whitespace-only text must NOT win the join — hasX would '
              'turn true with nothing to show, breaking the fallback');
      expect(index['1|1'], isNot('IGNORED'));
      // (Rev. 4) arabicnumber 0 is the fawazahmed0 marker for ABSENT —
      // pairKey (hadith_database_service.dart:629) intentionally falls back
      // to the hadithnumber-only key ('$h|$h'), mirroring the extractor.
      // So (0,0) is NOT "unjoinable": it indexes under '0|0'. It stays
      // inert because no base record carries hadithnumber 0 to query it.
      expect(index['0|0'], 'zero-pair',
          reason: 'arabic-number fallback rule, not a validity filter');
      // numberKey validates nothing — a malformed label survives as its
      // trimmed string (also true in the extractor); it can only ever fail
      // to JOIN, never corrupt a real pair.
      expect(index['abc|1'], 'non-numeric');
    });

    test('a blank that comes FIRST must not shadow the later real text', () {
      final index = HadithDatabaseService.pairTextIndex([
        {'hadithnumber': 7, 'arabicnumber': 7, 'text': ' '},
        {'hadithnumber': 7, 'arabicnumber': 7, 'text': 'real'},
      ]);
      expect(index['7|7'], 'real');
    });

    test('a hadith without a key-match has hasX == false (fallback input)', () {
      const bare = LocalHadith(
        hadithNumber: 5,
        arabicNumber: 5,
        textArabic: 'ع',
        textEnglish: 'e',
        textUrdu: 'ا',
        bookSlug: 'bukhari',
        bookName: 'Sahih al Bukhari',
        bookNumber: 1,
        chapterHadithNumber: 1,
        chapterName: 'c',
        grade: '',
      );
      expect(bare.hasBengali, isFalse);
      expect(bare.hasTurkish, isFalse);
      expect(bare.hasIndonesian, isFalse);
      expect(bare.hasFrench, isFalse);
    });
  });

  group('language-driven text selection', () {
    HadithModel model({String bn = '', String tr = '', String id = '', String fr = ''}) =>
        HadithModel(
          id: 'x',
          hadithNumber: 1,
          bookSlug: 'bukhari',
          bookName: 'Sahih al Bukhari',
          chapterNumber: 1,
          chapterName: 'c',
          textArabic: 'ar',
          textEnglish: 'en',
          textUrdu: '',
          textBengali: bn,
          textTurkish: tr,
          textIndonesian: id,
          textFrench: fr,
          grade: HadithGrade.unknown,
          narrator: const HadithNarrator(name: ''),
        );

    test('each new language reads its own field; missing -> null', () {
      final full = model(bn: 'bn', tr: 'tr', id: 'id', fr: 'fr');
      expect(hadithTextForLanguage(full, 'bn'), 'bn');
      expect(hadithTextForLanguage(full, 'tr'), 'tr');
      expect(hadithTextForLanguage(full, 'id'), 'id');
      expect(hadithTextForLanguage(full, 'fr'), 'fr');
      expect(hadithTextForLanguage(model(), 'bn'), isNull);
      expect(hadithTextForLanguage(model(fr: '   '), 'fr'), isNull,
          reason: 'whitespace-only is NOT a translation');
      expect(hadithTextForLanguage(model(), 'xx'), isNull,
          reason: 'unknown code selects nothing');
    });

    test('LocalHadith variant follows the same rule (related-section surface)', () {
      const local = LocalHadith(
        hadithNumber: 1,
        arabicNumber: 1,
        textArabic: 'ar',
        textEnglish: 'en',
        textUrdu: '',
        textBengali: 'bn',
        bookSlug: 'bukhari',
        bookName: 'b',
        bookNumber: 1,
        chapterHadithNumber: 1,
        chapterName: 'c',
        grade: '',
      );
      expect(localHadithTextForLanguage(local, 'bn'), 'bn');
      expect(localHadithTextForLanguage(local, 'fr'), isNull);
    });

    test('model JSON round-trips the new fields (aliases included)', () {
      final fromAlias = HadithModel.fromJson({
        'hadithBengali': 'bn-alias',
        'textTurkish': 'tr-direct',
        'indonesian': 'id-short',
      });
      expect(fromAlias.textBengali, 'bn-alias');
      expect(fromAlias.textTurkish, 'tr-direct');
      expect(fromAlias.textIndonesian, 'id-short');
      expect(fromAlias.textFrench, '');
      final json = fromAlias.toJson();
      expect(json['textBengali'], 'bn-alias');
      expect(json['textFrench'], '');
    });

    test('copyWith preserves the new fields', () {
      final m = model(bn: 'x');
      expect(m.copyWith(chapterName: 'z').textBengali, 'x');
    });
  });

  group('search normalizer on the new scripts', () {
    test('Bengali matches pass through the fold untouched', () {
      expect(
        SearchNormalizer.contains(
          'আবু হুরায়রা (রা.) থেকে বর্ণিত',
          'আবু হুরায়রা',
        ),
        isTrue,
      );
      // Unknown-to-the-fold codepoints must survive the fold verbatim.
      expect(SearchNormalizer.foldQuery('হুরায়রা'), 'হুরায়রা');
    });

    test('Latin-with-diacritics matching is case-folded, accents verbatim', () {
      expect(SearchNormalizer.contains('Nulle part où aller — ÉMU', 'ému'), isTrue);
      expect(SearchNormalizer.contains('Nulle part', 'part'), isTrue);
      // Known limitation, pinned honestly: no accent-folding, so an
      // unaccented query does NOT match accented text.
      expect(SearchNormalizer.contains('ému', 'emu'), isFalse);
    });
  });

  group('surfaces route through the selection (source pins)', () {
    test('settings hadith selector is derived; the app-locale selector is', () {
      // SCOPED pin: settings_screen ALSO has an app-language (locale)
      // sheet that legitimately uses ('en', 'English') tuples with
      // localeProvider — unrelated to hadith. The pin therefore inspects
      // ONLY the hadith language sheet region for the old hardcoded list.
      final src =
          File('lib/features/settings/presentation/settings_screen.dart').readAsStringSync();
      expect(src.contains("HadithAvailability.selectorOptions()"), isTrue);
      // (Rev. 4) anchor on the DEFINITION — the bare name first occurs at
      // the call site (~:140), which gave the wrong window; the definition
      // (~:907) is what the region pin is about. The 'void ' prefix occurs
      // exactly once (call site has no modifier).
      final start = src.indexOf('void _showHadithLanguageSheet');
      expect(start, greaterThan(0));
      var end = src.indexOf('\n  void ', start + 1);
      if (end < 0) end = src.length;
      final region = src.substring(start, end);
      expect(region.contains("('en', 'English')"), isFalse,
          reason: 'the old hardcoded hadith language list must stay gone');
      // and the locale sheet's literal remains legitimately untouched:
      expect(src.substring(0, start).contains("('en', 'English')"), isTrue,
          reason: 'the app-locale selector (:764) is a different surface — '
              'it sits BEFORE the hadith sheet definition and must survive');
    });

    test('the book quick-settings sheet is a SECOND derived entry, not a copy',
        () {
      // Owner 2026-09-05 UX finding: readers inside a book looked for the
      // 7-language switch in the quick-settings sheet and found only
      // toggles. The fix must not fork the matrix — BOTH surfaces must
      // derive from HadithAvailability.selectorOptions() and write the
      // SAME provider, or they can drift exactly like the old hardcoded
      // list did. This pin is what keeps them welded together.
      final book = File('lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      final settings = File('lib/features/settings/presentation/settings_screen.dart')
          .readAsStringSync();
      for (final src in [book, settings]) {
        expect(src.contains('HadithAvailability.selectorOptions()'), isTrue,
            reason: 'every hadith-language entry derives from the matrix');
        expect(
            src.contains('hadithLanguageProvider.notifier') &&
                src.contains('.setLanguage(option.code)'),
            isTrue,
            reason: 'every entry writes the same single provider');
      }
      // Placement (owner ask): the Language row sits at the TOP of the
      // quick-settings sheet, above the display toggles — pinned as a real
      // source order, not a vibe.
      final sheet = book.indexOf('void _showQuickSettingsSheet');
      expect(sheet, greaterThan(0));
      expect(book.indexOf('Icons.translate_rounded', sheet),
          lessThan(book.indexOf("'Arabic Text", sheet)),
          reason: 'Language row must sit above the toggles in the sheet');
      expect(book.contains('void _showReadingLanguageSheet'), isTrue,
          reason: 'the row opens a real picker, not a dead button');
      expect(book.contains('_showReadingLanguageSheet(sheetContext)'), isTrue,
          reason: 'and the picker is opened FROM the quick-settings sheet');
      // No new hardcoded language list may exist in the book screen:
      expect(RegExp(r"'en',\s*'ar'|'ar',\s*'ur'").hasMatch(book), isFalse,
          reason: 'lists of codes inline = the drift this pin exists to stop');
    });

    test('book screen shows ONE translation block (no fixed Urdu/English pair)', () {
      final src = File('lib/features/hadith/presentation/hadith_book_screen.dart')
          .readAsStringSync();
      expect(src.contains('showTranslation: _showTranslation'), isTrue);
      expect(src.contains('showUrdu'), isFalse);
      expect(src.contains('showEnglish'), isFalse);
      expect(src.contains('hadithTextForLanguage'), isTrue);
      expect(src.contains("'Verified translation unavailable for this language.'"), isTrue);
    });

    test('home tab previews route through hadithTextForLanguage', () {
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart').readAsStringSync();
      expect(src.contains('final previewText = translation ?? hadith.textEnglish;'), isTrue,
          reason: 'the tile preview must follow the reading language');
      expect(src.contains('_RecentlyReadCard extends ConsumerWidget'), isTrue);
    });

    test('the service joins new languages by pair key and searches them', () {
      final src = File('lib/features/hadith/data/services/hadith_database_service.dart')
          .readAsStringSync();
      expect(src.contains("textBengali: langIndices['bn']?[pair] ?? ''"), isTrue);
      expect(src.contains('pairKey(map[\'hadithnumber\'], map[\'arabicnumber\'])'), isTrue,
          reason: 'the runtime join must key off the RAW record numbers');
      expect(src.contains("'bengali'"), isTrue);
      expect(src.contains('pairTextIndex'), isTrue);
    });

    test('sidecar records the seven-language layout', () {
      final manifest =
          File('assets/data/content_manifest.json').readAsStringSync();
      expect(manifest.contains('ar/en/ur/bn/tr/id/fr JSON'), isTrue);
      expect(manifest.contains('extract_hadith_languages.py'), isTrue);
    });
  });

  group('honest coverage floors (real bundled data, Rev. 2)', () {
    test('per-language text counts match the Rev. 2 extraction report', () {
      // Numbers produced by scripts/extract_hadith_languages.py on
      // 2026-09-05 after the fractional-key fix; a future data pass must
      // consciously re-pin them.
      expect(_hadithsOf('assets/data/hadith/bukhari/bengali.json').length, 7529);
      expect(_hadithsOf('assets/data/hadith/bukhari/turkish.json').length, 7521);
      expect(_hadithsOf('assets/data/hadith/bukhari/indonesian.json').length, 6858);
      expect(_hadithsOf('assets/data/hadith/bukhari/french.json').length, 7589);
      // French Bukhari is COMPLETE (every base record, citations included
      // — the dataset carries text for all of them).
      expect(_hadithsOf('assets/data/hadith/bukhari/french.json').length,
          _hadithsOf('assets/data/hadith/bukhari/english.json').length);
      // Turkish Nasai is the dataset's big gap (5,136 of 5,765 texts empty)
      // — shipped as the 629 real translations it has, no padding.
      expect(_hadithsOf('assets/data/hadith/nasai/turkish.json').length, 629);
      // Malik's French file matched 1,505 of 1,858 — and 41 dataset
      // records exist that our base does not have at all (reported, not
      // silently dropped, by the extractor's mismatch table).
      expect(_hadithsOf('assets/data/hadith/malik/french.json').length, 1505);
    });
  });
}
