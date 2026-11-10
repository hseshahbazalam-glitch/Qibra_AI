// H2PROBE (transient): dart-analyze the materialized pass test — verdict
// rides the annotation channel. (No solo '${x}' strings: that lint is
// warning-tier and reds the gate — caught blind for four rounds.)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2a: dart-analyze the materialized pass test', () async {
    String out = '';
    try {
      final mat = await Process.run('git', [
        'show',
        'HEAD~1:test/features/quran/qh_pass_test.dart',
      ]);
      if (mat.exitCode != 0) {
        out = 'MATERIALIZE FAILED exit=${mat.exitCode}';
      } else {
        final dir = Directory('.qhscan');
        dir.createSync();
        final f = File('.qhscan/qh_pass_test.dart');
        f.writeAsStringSync('${mat.stdout}');
        final r = await Process.run('dart', [
          'analyze',
          '.qhscan/qh_pass_test.dart',
        ]);
        out = 'EXIT=${r.exitCode} '
            'LEN=${(mat.stdout as String).length}\n'
            '${r.stdout}\n'
            '${r.stderr}';
      }
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final keep = <String>['H2A lines=${all.length}'];
    for (final raw in all) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      keep.add(c);
      if (keep.length > 40) break;
    }
    for (final l in keep.take(42)) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2A $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
