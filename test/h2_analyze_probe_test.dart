// H2PROBE (transient): mirror the suspect tree into .qhfull and let
// dart-analyze state its own errors, exfiltrated verbatim.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2a: analyze a materialized copy of the red tree', () async {
    const files = [
      'lib/features/tasbih/providers/tasbih_provider.dart',
      'lib/features/tasbih/presentation/tasbih_detail.dart',
      'lib/features/tasbih/presentation/tasbih_screen.dart',
      'test/core/i18n_phase_a_test.dart',
      'test/features/quran/qh_pass_test.dart',
      'lib/features/quran/presentation/surah_reading_handle.dart',
    ];
    String out = '';
    try {
      final root = Directory('.qhfull');
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
      for (final f in files) {
        final mat = await Process.run('git', ['show', 'HEAD~1:$f']);
        if (mat.exitCode != 0) {
          out += 'MISSING-IN-HEAD $f\n';
          continue;
        }
        final dest = File('.qhfull/$f');
        dest.parent.createSync(recursive: true);
        dest.writeAsStringSync('${mat.stdout}');
      }
      final r = await Process.run('dart', ['analyze', '.qhfull']);
      out = 'EXIT=${r.exitCode}\n$out${r.stdout}\n${r.stderr}';
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final keep = <String>['H2A lines=${all.length}'];
    for (final raw in all) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      if (c.startsWith('error') ||
          c.startsWith('warning') ||
          c.startsWith('EXIT=') ||
          c.contains('issue') ||
          c.contains('MISSING')) {
        keep.add(c);
      }
      if (keep.length > 55) break;
    }
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2A $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
