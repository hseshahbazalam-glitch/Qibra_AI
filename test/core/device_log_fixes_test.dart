// Device-log fix pass (owner mega-session @CPH2573): ink-surface source
// guards, boot-banner honesty, and the pure Overpass request builder.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/prayer/data/services/mosque_service.dart';

String read(String rel) => File(rel).readAsStringSync();

void main() {
  group('ListTile/ink surface guards (fix 1)', () {
    test('hadith detail-sheet body is a Material with the same radius', () {
      final src =
          read('lib/features/hadith/presentation/hadith_book_screen.dart');
      // the transparent-modal sheet: ink must paint on the sheet surface
      expect(src, contains('child: Material('));
      expect(src, contains('Radius.circular(28)'));
      expect(src.contains('return Container(\n          constraints:'), isFalse,
          reason: 'colored Container as sheet body hid all descendant ink');
      expect(src.contains("backgroundColor: Colors.transparent"), isTrue,
          reason: 'the transparent-modal pattern stays; the BODY carries ink');
    });

    test('settings sheets keep ListTiles on the modal Material (swept)', () {
      final src = read('lib/features/settings/presentation/settings_screen.dart');
      // four sheet call-sites, all already Material-backed: none may
      // regress into a colored Container wrapping the ListTiles.
      final offenders = RegExp(
        r'Container\(\s*\n\s*decoration: BoxDecoration\(\s*\n\s*color: colors\.card[^)]*\)\s*\n[^;]*ListTile\(',
      ).hasMatch(src);
      expect(offenders, isFalse);
    });
  });

  group('boot banner honesty (fix 2)', () {
    test('.env line is conditional on the real load outcome', () {
      final src = read('lib/main.dart');
      expect(src, contains('var envLoaded = false;'));
      expect(src, contains('envLoaded = true;'));
      expect(src, contains('✅ .env loaded'));
      expect(src, contains('⚠️ .env not present'));
      expect(src, contains(r"${envLoaded ? '✅ .env loaded' : '⚠️ .env not present'}"));
      // audit outcome: the two lines that could not be true at print time
      // were reworded to what actually happens — no new banner lines.
      expect(src, contains('📖 Quran data queued (loads after first frame)'));
      expect(src.contains('📖 Quran data ready'), isFalse);
    });
  });

  group('mosque Overpass request (fix 3)', () {
    test('query builder is exact — node+way, around-radius, out center', () {
      final q = MosqueService.buildQuery(
          latitude: 12.9716, longitude: 77.5946);
      expect(q, startsWith('[out:json][timeout:10];'));
      expect(q,
          contains('node["amenity"="place_of_worship"]["religion"="muslim"]'
              '(around:5000.0,12.9716,77.5946)'));
      expect(q,
          contains('way["amenity"="place_of_worship"]["religion"="muslim"]'
              '(around:5000.0,12.9716,77.5946)'));
      expect(q, contains('out center;'));
      final q2 = MosqueService.buildQuery(
          latitude: 1.5, longitude: 2.5, radiusMeters: 2500);
      expect(q2, contains('(around:2500.0,1.5,2.5)'));
    });

    test('headers defeat the 406: identifiable UA + JSON accept', () {
      final h = MosqueService.requestHeaders;
      expect(h['User-Agent'], isNotNull);
      expect(h['User-Agent']!, startsWith('QibraAI/'));
      expect(h['Accept'], 'application/json');
      expect(MosqueService.overpassEndpoint,
          'https://overpass-api.de/api/interpreter');
    });

    test('transport is a form-POST (current API contract), fallback intact',
        () {
      final src = read('lib/features/prayer/data/services/mosque_service.dart');
      expect(src, contains('http\n          .post('));
      expect(src, contains("body: {'data': overpassQuery}"));
      expect(src.contains('http.get('), isFalse);
      // honest-empty on non-200 stays; no fabricated mosque data ever
      expect(src, contains("return const [];"));
    });
  });
}
