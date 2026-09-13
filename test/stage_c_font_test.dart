// Stage C (updated at Stage D hotfix) — bundled fonts, never a runtime CDN
// fetch. Amiri (Arabic) and Inter (Latin) are pubspec font families; the
// google_fonts package itself is no longer a dependency, so there is not
// even a kill-switch left to flip: a `GoogleFonts.` reference cannot compile.
// Source-scan assertions; run under `flutter test` without a harness.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _interFiles = <String, int>{
  'assets/fonts/Inter-Light.ttf': 300,
  'assets/fonts/Inter-Regular.ttf': 400,
  'assets/fonts/Inter-Medium.ttf': 500,
  'assets/fonts/Inter-SemiBold.ttf': 600,
  'assets/fonts/Inter-Bold.ttf': 700,
  'assets/fonts/Inter-ExtraBold.ttf': 800,
  'assets/fonts/Inter-Black.ttf': 900,
};

void main() {
  test('bundled TTFs exist on disk and are valid TrueType', () {
    for (final p in [
      'assets/fonts/Amiri-Regular.ttf',
      'assets/fonts/Amiri-Bold.ttf',
      ..._interFiles.keys,
    ]) {
      final f = File(p);
      expect(f.existsSync(), isTrue, reason: '$p missing');
      final head = f.openSync().readSync(4);
      // trueType sfnt version 1.0
      expect(head, orderedEquals(<int>[0x00, 0x01, 0x00, 0x00]),
          reason: '$p is not a TrueType sfnt');
      expect(f.lengthSync() > 100000, isTrue, reason: '$p looks truncated');
    }
    for (final lic in [
      'assets/fonts/LICENSE-Amiri.txt',
      'assets/fonts/LICENSE-Inter.txt',
    ]) {
      expect(File(lic).existsSync(), isTrue,
          reason: 'OFL license text must ship with the font');
    }
  });

  test('pubspec registers Amiri and Inter with every used weight', () {
    final src = File('pubspec.yaml').readAsStringSync();
    expect(src.contains('family: Amiri'), isTrue,
        reason: 'fonts: block must declare family Amiri');
    expect(src.contains('assets/fonts/Amiri-Regular.ttf'), isTrue);
    expect(src.contains('assets/fonts/Amiri-Bold.ttf'), isTrue);
    expect(src.contains('weight: 700'), isTrue,
        reason: 'bold faces must be registered as weight 700');
    expect(src.contains('family: Inter'), isTrue,
        reason: 'fonts: block must declare family Inter');
    for (final asset in _interFiles.keys) {
      expect(src.contains('asset: $asset'), isTrue,
          reason: 'missing Inter registration: $asset');
    }
    for (final w in _interFiles.values) {
      expect(src.contains('weight: $w'), isTrue,
          reason: 'Inter weight $w must be registered');
    }
  });

  test('google_fonts is fully removed: no dep, no imports, no call sites',
      () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('google_fonts'), isFalse,
        reason: 'the package must not remain a dependency');
    // Directory() paths are OS-native ('\' on Windows) — only
    // separator-free predicates (.dart suffix / literal contains) below.
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      expect(src.contains('package:google_fonts'), isFalse,
          reason: '${f.path} still imports google_fonts');
      expect(src.contains('GoogleFonts.'), isFalse,
          reason: '${f.path} still has GoogleFonts call sites — use the '
              'bundled families (AppTextStyles/AppArabicStyles) instead');
    }
    // The kill-switch line is gone WITH the package — its absence is the
    // point; nothing may re-add a runtime-fetch path.
    expect(File('lib/main.dart').readAsStringSync()
        .contains('allowRuntimeFetching'), isFalse);
  });

  test('every app_typography style pins a bundled family', () {
    final src =
        File('lib/core/design_system/app_typography.dart').readAsStringSync();
    final latin = RegExp(
            r'TextStyle\(\s*fontFamily:\s*AppFontFamily\.primary')
        .allMatches(src)
        .length;
    final arabic = RegExp(
            r'TextStyle\(\s*fontFamily:\s*AppFontFamily\.arabic')
        .allMatches(src)
        .length;
    expect(latin, greaterThanOrEqualTo(30),
        reason: 'all 30 Latin getters must resolve on the bundled Inter');
    expect(arabic, greaterThanOrEqualTo(9),
        reason: 'all 9 Arabic getters must resolve on the bundled Amiri');
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
      'lib/features/tools',
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
