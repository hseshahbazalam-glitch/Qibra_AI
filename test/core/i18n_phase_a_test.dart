// I18N PHASE A — AppStrings coverage + census pin.
//
// Coverage is SOURCE-PARSED: every getter's definition IS its per-locale
// value (they all route through _t(en, ar, ur)), so parsing app_strings.dart
// checks every getter — present and future — with zero name-list drift.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
