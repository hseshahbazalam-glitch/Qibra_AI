import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/features/ai/domain/rag_service.dart';

/// Roman Urdu bridge (owner 2026-09-02): Roman-script queries must reach the
/// Arabic/English corpus through query expansion, with Levenshtein-1 typo
/// recovery behind it. These are pure-function tests — no assets or DB
/// initialization needed; the end-to-end retrieval is the device gate.

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
      _m6bad.add('features_ai_roman_urdu_bridge_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('features_ai_roman_urdu_bridge_test :: $d :: ${e.toString().split('\n').first}');
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

  group('bridge map — owner vocabulary', () {
    test('every owner-named word is a key', () {
      const required = [
        'namaz', 'salah', 'roza', 'zakat', 'qibla', 'dua', 'sabr', 'jannah',
        'jahannam', 'paani', 'halal', 'haram', 'iman', 'taubah', 'nabi',
        'quran', 'makkah', 'madina', 'eid', 'hajj', 'umrah', 'farz',
        'sunnah', 'hadith', 'ghusl', 'wudu',
      ];
      for (final word in required) {
        expect(RagService.romanUrduBridge.containsKey(word), isTrue,
            reason: word);
      }
    });

    test('namaz expands to prayer/salah/salat and the Arabic script', () {
      final variants = RagService.romanUrduBridge['namaz']!;
      expect(variants, containsAll(<String>['prayer', 'salah', 'salat', 'صلاة']));
    });

    test('core glosses match the owner brief', () {
      expect(RagService.romanUrduBridge['roza'], containsAll(['fasting', 'sawm']));
      expect(RagService.romanUrduBridge['dua'], contains('supplication'));
      expect(RagService.romanUrduBridge['sabr'], contains('patience'));
      expect(RagService.romanUrduBridge['jannah'], contains('paradise'));
      expect(RagService.romanUrduBridge['jahannam'], contains('hell'));
      expect(RagService.romanUrduBridge['paani'], contains('water'));
      expect(RagService.romanUrduBridge['iman'], contains('faith'));
      expect(RagService.romanUrduBridge['taubah'], contains('repentance'));
      expect(RagService.romanUrduBridge['nabi'], contains('prophet'));
      expect(RagService.romanUrduBridge['farz'], contains('obligatory'));
      expect(RagService.romanUrduBridge['wudu'], contains('ablution'));
    });
  });

  group('expandQuery', () {
    test('Roman Urdu words contribute corpus variants', () {
      expect(
        RagService.expandQuery('namaz kiyq h'),
        containsAll(<String>['prayer', 'salah', 'salat', 'صلاة']),
      );
    });

    test('already-typed variants are not duplicated', () {
      // 'prayer' is already in the query — expanding 'namaz' must not add it
      final out = RagService.expandQuery('namaz prayer');
      expect(out.contains('prayer'), isFalse);
      expect(out.contains('salah'), isTrue);
    });

    test('English-only queries get no expansion', () {
      expect(RagService.expandQuery('mercy of Allah'), isEmpty);
    });

    test('the corpus direction is real: prayer exists, namaz does not', () {
      final raw = File('assets/data/quran/translation_en.json').readAsStringSync();
      expect(raw.toLowerCase().contains('prayer'), isTrue);
      expect(raw.toLowerCase().contains('namaz'), isFalse);
    });
  });

  group('typo tolerance (Levenshtein-1)', () {
    test('one-edit typos of dictionary words are corrected', () {
      expect(RagService.correctionsFor('namz'), contains('namaz'));
      expect(RagService.correctionsFor('prayerr'), contains('prayer'));
      expect(RagService.correctionsFor('rozaa'), contains('roza'));
      expect(RagService.correctionsFor('wud'), contains('wudu'));
    });

    test('dictionary words and non-words behave', () {
      expect(RagService.correctionsFor('prayer'), isEmpty); // already correct
      expect(RagService.correctionsFor('xy'), isEmpty); // too short
      expect(RagService.correctionsFor('qqqqzzzz'), isEmpty); // no neighbor
    });
  });

  group('language mirroring', () {
    test('Roman Urdu queries are detected', () {
      expect(RagService.looksRomanUrdu('namaz kiyq h'), isTrue);
      expect(RagService.looksRomanUrdu('roza kaise rakhen'), isTrue);
    });

    test('English queries stay English', () {
      expect(RagService.looksRomanUrdu('what is patience in the quran'), isFalse);
      expect(RagService.looksRomanUrdu(''), isFalse);
    });
  });

  group('retrieve contract', () {
    test('blank query is still a blank refusal', () async {
      expect(await RagService.instance.retrieve('   '), isEmpty);
    });
  });
}
