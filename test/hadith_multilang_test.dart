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

(int, int) _pairOf(Map<String, dynamic> rec) {
  int lead(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    final m = RegExp(r'^(\d+)').firstMatch(v.toString());
    return m != null ? int.parse(m.group(1)!) : 0;
  }
  final h = lead(rec['hadithnumber']);
  final a = lead(rec['arabicnumber']);
  return (h, a == 0 ? h : a);
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

    test('language files mirror the base record numbers exactly', () {
      // (same pair) — so the runtime Dart join hits by construction.
      for (final slug in books) {
        final base = {
          for (final r in _hadithsOf('assets/data/hadith/$slug/english.json'))
            _pairOf(r): r,
        };
        for (final lang in newLangs.entries) {
          final file = 'assets/data/hadith/$slug/${lang.value}.json';
          if (!File(file).existsSync()) continue;
          for (final rec in _hadithsOf(file)) {
            final b = base[_pairOf(rec)]!;
            expect(_pairOf(rec), _pairOf(b));
            expect(rec['reference'], b['reference'],
                reason: 'reference must ride the base record verbatim');
          }
        }
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

  group('service join semantics (mirrors the shipped parser)', () {
    test('pairKey matches the loader normalization (arabic 0 -> hadith num)', () {
      expect(HadithDatabaseService.pairKey(10, 0), (10, 10));
      expect(HadithDatabaseService.pairKey(10, 3), (10, 3));
    });

    test('pairTextIndex: string/floor semantics, empties skipped, first wins', () {
      final index = HadithDatabaseService.pairTextIndex([
        {'hadithnumber': 1, 'arabicnumber': 0, 'text': 'one'},
        {'hadithnumber': '1001', 'arabicnumber': '446', 'text': 'thousand-one'},
        {'hadithnumber': 2, 'arabicnumber': '3033.02', 'text': 'floored'},
        {'hadithnumber': 3, 'arabicnumber': 3, 'text': '   '}, // empty -> skip
        {'hadithnumber': 1, 'arabicnumber': 0, 'text': 'IGNORED'}, // dup
        {'hadithnumber': 0, 'arabicnumber': 0, 'text': 'unjoinable'},
      ]);
      expect(index[(1, 1)], 'one');
      expect(index[(1001, 446)], 'thousand-one');
      expect(index[(2, 3033)], 'floored');
      expect(index.containsKey((3, 3)), isFalse);
      expect(index[(1, 1)], isNot('IGNORED'));
      expect(index.containsKey((0, 0)), isFalse);
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
    test('settings selector is derived, not a hardcoded const list', () {
      final src =
          File('lib/features/settings/presentation/settings_screen.dart').readAsStringSync();
      expect(src.contains("HadithAvailability.selectorOptions()"), isTrue);
      expect(src.contains("('en', 'English')"), isFalse,
          reason: 'the old hardcoded language list must stay gone');
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
      expect(src.contains('textBengali: langIndices[\'bn\']?[pair] ?? \'\''), isTrue);
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

  group('honest coverage floors (real bundled data)', () {
    test('per-language text counts match the extraction report', () {
      // Numbers produced by scripts/extract_hadith_languages.py on
      // 2026-09-05; a future data pass must consciously re-pin them.
      expect(_hadithsOf('assets/data/hadith/bukhari/bengali.json').length, 7529);
      expect(_hadithsOf('assets/data/hadith/bukhari/turkish.json').length, 7512);
      expect(_hadithsOf('assets/data/hadith/bukhari/indonesian.json').length, 6856);
      expect(_hadithsOf('assets/data/hadith/bukhari/french.json').length, 7563);
      // Turkish Nasai is the dataset's big gap (5,136 of 5,765 texts empty)
      // — shipped as the 629 real translations it has, no padding.
      expect(_hadithsOf('assets/data/hadith/nasai/turkish.json').length, 629);
    });
  });
}
