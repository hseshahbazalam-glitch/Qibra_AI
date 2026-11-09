// Content pass guards (owner, 2026-09-02): 7 hadith collections with
// ar/en/ur, tafsir coverage + range integrity, visible source credit.
// Dataset-level assertions — run in plain `flutter test`, no harness.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;

const _books = [
  'bukhari',
  'muslim',
  'nasai',
  'abudawud',
  'tirmidhi',
  'ibnmajah',
  'malik',
];


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('features_hadith_content_pass_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('features_hadith_content_pass_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
  });

  test('collections screen exposes exactly 7 books, incl. tirmidhi + nasai',
      () {
    final src =
        File('lib/features/hadith/presentation/hadith_screen.dart')
            .readAsStringSync();
    final slugs = RegExp(r"'slug':\s*'([a-z]+)'")
        .allMatches(src)
        .map((m) => m.group(1)!)
        .toSet();
    expect(slugs.length, 7, reason: 'one tile per collection');
    expect(slugs, containsAll(<String>['tirmidhi', 'nasai']));
    final svc =
        File('lib/features/hadith/data/services/hadith_database_service.dart')
            .readAsStringSync();
    for (final b in _books) {
      expect(svc.contains("'$b':"), isTrue, reason: 'service knows $b');
    }
  });

  test('all 7 collections ship the 3-file ar/en/ur layout', () {
    for (final b in _books) {
      for (final l in ['arabic', 'english', 'urdu']) {
        final f = File('assets/data/hadith/$b/$l.json');
        expect(f.existsSync(), isTrue, reason: '$b/$l.json missing');
        final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect((d['hadiths'] as List).isNotEmpty, isTrue,
            reason: '$b/$l.json has no hadiths');
      }
    }
  });

  test('tirmidhi urdu aligns with english on count, numbers and sections',
      () {
    final en = jsonDecode(File('assets/data/hadith/tirmidhi/english.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final ur = jsonDecode(File('assets/data/hadith/tirmidhi/urdu.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final eh = en['hadiths'] as List;
    final uh = ur['hadiths'] as List;
    expect(uh.length, eh.length);
    for (var i = 0; i < eh.length; i++) {
      expect((uh[i] as Map)['hadithnumber'], (eh[i] as Map)['hadithnumber'],
          reason: 'misalignment at $i');
    }
    expect((ur['metadata'] as Map)['sections'],
        (en['metadata'] as Map)['sections']);
  });

  group('bundled tafsir — Ibn Kathir (abridged, Eng. tr.)', () {
    late Map<String, dynamic> surahs;
    late Map<String, dynamic> meta;

    setUpAll(() {
      final data = jsonDecode(File('assets/data/tafsir/ibn_kathir_en.json')
          .readAsStringSync()) as Map<String, dynamic>;
      surahs = data['surahs'] as Map<String, dynamic>;
      meta = data['metadata'] as Map<String, dynamic>;
    });

    test('every surah 1..114 has at least one non-empty passage', () {
      for (var s = 1; s <= 114; s++) {
        final ps = surahs['$s'];
        expect(ps is List && ps.isNotEmpty, isTrue, reason: 'surah $s empty');
        for (final p in (ps as List)) {
          expect((p as Map)['t'].toString().trim().isNotEmpty, isTrue,
              reason: 'surah $s blank passage at ${p['s']}');
        }
      }
    });

    test('ayah ranges: no gaps, no overlaps, full coverage to last ayah', () {
      final info = (jsonDecode(File('assets/data/quran/surah_info.json')
              .readAsStringSync()) as Map<String, dynamic>)['data']
          as List;
      final counts = <int, int>{
        for (final e in info)
          (e as Map)['number'] as int: e['numberOfAyahs'] as int
      };
      expect(counts.length, 114);
      for (var s = 1; s <= 114; s++) {
        final ps = surahs['$s'] as List;
        var pos = 1;
        for (final p in ps) {
          final m = p as Map;
          expect(m['s'], pos, reason: 'surah $s gap/overlap at ayah $pos');
          expect(m['e'] as int, greaterThanOrEqualTo(pos),
              reason: 'surah $s inverted range');
          pos = (m['e'] as int) + 1;
        }
        expect(pos, counts[s]! + 1, reason: 'surah $s missing tail ayahs');
      }
    });

    test('provenance pinned: real published dataset, never generated', () {
      expect(meta['upstream_repo'].toString(), contains('spa5k/tafsir_api'));
      expect(meta['upstream_commit'].toString().length, 40);
      expect(meta['credit'], 'Tafsir Ibn Kathir (abridged, Eng. tr.)');
      expect(meta['license'], 'UNKNOWN'); // honesty: rights unverified
      final manifest = jsonDecode(File('assets/data/content_manifest.json')
          .readAsStringSync()) as Map<String, dynamic>;
      final tafsir = (manifest['sources'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['id'] == 'tafsir_ibn_kathir');
      expect(tafsir['verification_status'], 'REQUIRES_PERMISSION');
      expect(tafsir['license'], 'UNKNOWN');
    });

    test('screen surfaces the visible credit + honest fallback', () {
      final src =
          File('lib/features/tafseer/presentation/tafseer_screen.dart')
              .readAsStringSync();
      expect(src.contains('Tafsir Ibn Kathir (abridged, Eng. tr.)'), isTrue);
      expect(src.contains('_buildTafsirUnavailable'), isTrue,
          reason: 'fallback state must stay when the bundle fails to load');
    });
  });
}
