// Stage C — Amiri is a bundled asset, never a runtime CDN fetch.
// Source-scan assertions; run under `flutter test` without a harness.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Amiri TTFs exist on disk and are valid TrueType', () {
    for (final p in [
      'assets/fonts/Amiri-Regular.ttf',
      'assets/fonts/Amiri-Bold.ttf',
    ]) {
      final f = File(p);
      expect(f.existsSync(), isTrue, reason: '$p missing');
      final head = f.openSync().readSync(4);
      // trueType sfnt version 1.0
      expect(head, orderedEquals(<int>[0x00, 0x01, 0x00, 0x00]),
          reason: '$p is not a TrueType sfnt');
      expect(f.lengthSync() > 100000, isTrue,
          reason: '$p looks truncated');
    }
    expect(File('assets/fonts/LICENSE-Amiri.txt').existsSync(), isTrue,
        reason: 'OFL license text must ship with the font');
  });

  test('pubspec registers the Amiri family with both weights', () {
    final src = File('pubspec.yaml').readAsStringSync();
    expect(src.contains('family: Amiri'), isTrue,
        reason: 'fonts: block must declare family Amiri');
    expect(src.contains('assets/fonts/Amiri-Regular.ttf'), isTrue);
    expect(src.contains('assets/fonts/Amiri-Bold.ttf'), isTrue);
    expect(src.contains('weight: 700'), isTrue,
        reason: 'bold face must be registered as weight 700');
  });

  test('main() disables runtime font fetching', () {
    final src = File('lib/main.dart').readAsStringSync();
    expect(
        src.contains('GoogleFonts.config.allowRuntimeFetching = false;'),
        isTrue,
        reason: 'Arabic must never depend on a CDN fetch');
  });

  test('no dangling fontFamily: \'Amiri\' literals outside the '
      'bundled-style definitions', () {
    // AppArabicStyles (app_typography.dart) is the single Arabic
    // typography entry point; screens must not hand-roll the family.
    final stragglers = <String>[];
    for (final dir in [
      'lib/features/ai',
      'lib/features/auth',
      'lib/features/calendar',
      'lib/features/onboarding',
      'lib/features/hadith/presentation/hadith_book_screen.dart',
      'lib/features/prayer/presentation/salah_schedule_screen.dart',
      'lib/features/quran',
    ]) {
      final d = Directory(dir);
      final files = d.existsSync()
          ? d.listSync(recursive: true).whereType<File>()
          : <File>[File(dir)];
      for (final f in files) {
        if (!f.path.endsWith('.dart')) continue;
        if (f.path.contains('app_typography.dart')) continue;
        if (f.readAsStringSync().contains("fontFamily: 'Amiri'")) {
          stragglers.add(f.path);
        }
      }
    }
    expect(stragglers, isEmpty,
        reason: 'use AppArabicStyles instead of raw Amiri literals');
  });
}
