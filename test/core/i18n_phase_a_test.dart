// I18N PHASE A — AppStrings coverage + census pin.
//
// Coverage is SOURCE-PARSED: every getter's definition IS its per-locale
// value (they all route through _t(en, ar, ur)), so parsing app_strings.dart
// checks every getter — present and future — with zero name-list drift.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;


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
      _m6bad.add('core_i18n_phase_a_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_i18n_phase_a_test :: $d :: ${e.toString().split('\n').first}');
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
    print('::error::M6BADEND core_i18n_phase_a_test ${_m6bad.length}');
  });

  group('AppStrings coverage', () {
    test('every getter: en/ar/ur non-empty and ar/ur distinct from en', () {
      final src = File('lib/core/l10n/app_strings.dart').readAsStringSync();
      final rx = RegExp(
        // String get x => _t('en', 'ar', 'ur');  |  String x(sig) => _t(...)
        // and the multi-line _t( ... ) variant already used in the file.
        r"String (?:get (\w+)|(\w+)\([^)]*\)) => _t\(\s*"
        r"'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)',?\s*\);",
        dotAll: true,
      );
      final names = <String>[];
      for (final m in rx.allMatches(src)) {
        final name = m.group(1) ?? m.group(2)!;
        names.add(name);
        final en = m.group(3)!, ar = m.group(4)!, ur = m.group(5)!;
        expect(en.trim().isNotEmpty, isTrue, reason: '$name: empty en');
        expect(ar.trim().isNotEmpty, isTrue, reason: '$name: empty ar');
        expect(ur.trim().isNotEmpty, isTrue, reason: '$name: empty ur');
        expect(ar, isNot(equals(en)),
            reason: '$name: Arabic equals English (copy-paste miss?)');
        expect(ur, isNot(equals(en)),
            reason: '$name: Urdu equals English (copy-paste miss?)');
      }
      expect(names.length, greaterThan(100));
      expect(names.toSet().length, names.length,
          reason: 'duplicate getter names in AppStrings');
    });

    test('EN rendering stayed byte-identical for the migrated chrome', () {
      // Spot-check the brief's English-exactness rule on tricky shapes:
      // escaped apostrophes, em-dashes, uppercase badges, colons.
      final src = File('lib/core/l10n/app_strings.dart').readAsStringSync();
      for (final lit in [
        "Sunni / Shafi\\'i",
        "Sunnah Mu\\'akkadah",
        'Avatar not changed — \$error',
        'DETECTED TEXT',
        'Alert before prayer:',
        'View all \$count saved hadith',
      ]) {
        expect(src, contains(lit), reason: 'migrated EN literal drift: $lit');
      }
    });
  });

  group('census pin — hardcoded Text literals in lib/features', () {
    test('only the allowlisted literal remains', () {
      // EVERY remaining Text('<Capital...') literal must justify itself
      // here. New hits fail this test; the count is pinned exactly.
      const allowlist = <String>{
        // Proper/sacred noun by itself as a source label (not chrome copy)
        // — brief's SKIP class. Phase A decision (2026-09): stays English.
        'lib/features/tools/presentation/hajj_guide_screen.dart|Text(\'Quran\',',
        // Pass D2 decision (2026-09): the Reading Theme segment labels.
        // Settings is NOT one of A2's ten wired files; every tile title
        // in it ('Dark Mode', 'Font Size', ...) is a literal passed
        // through a variable, and Night/Paper are product-surface names
        // (the same class as the brief's chrome). A real i18n wiring of
        // settings would migrate this whole file, not these two labels.
        'lib/features/settings/presentation/settings_screen.dart|value: '
            'QibraReadingTheme.night, label: Text(\'Night\')),',
        'lib/features/settings/presentation/settings_screen.dart|value: '
            'QibraReadingTheme.paper, label: Text(\'Paper\')),',
      };
      final rx = RegExp(r"Text\(\s*'[A-Z]");
      final hits = <String>[];
      for (final entry in Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()) {
        if (!entry.path.endsWith('.dart')) continue;
        final lines = entry.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (rx.hasMatch(lines[i])) {
            hits.add('${entry.path}|${lines[i].trim()}');
          }
        }
      }
      expect(hits.length, allowlist.length,
          reason: 'Text-literal census moved: $hits — every literal must be '
              'migrated (add an AppStrings getter) or explicitly allowlisted '
              'WITH a reason here.');
      for (final h in hits) {
        expect(allowlist.contains(h), isTrue,
            reason: 'new unallowlisted hardcoded literal: $h');
      }
    });
  });
}
