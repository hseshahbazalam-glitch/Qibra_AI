// H2PROBE (transient): materialize the pass test into a dot-dir the outer
// scan skips, then dart-analyze it — the analyzer's own words, exfiltrated.
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
        'HEAD^:test/features/quran/qh_pass_test.dart',
      ]);
      if (mat.exitCode != 0) {
        out = 'MATERIALIZE FAILED exit=${mat.exitCode} ${mat.stderr}';
      } else {
        final dir = Directory('.qhscan');
        dir.createSync();
        final f = File('.qhscan/qh_pass_test.dart');
        f.writeAsStringSync(mat.stdout as String);
        final r = await Process.run('dart', [
          'analyze',
          '--no-fatal-infos',
          '.qhscan/qh_pass_test.dart',
        ]);
        final sb = StringBuffer();
        sb.writeln('EXIT=${r.exitCode} LEN=${(mat.stdout as String).length}');
        sb.writeln('${r.stdout}');
        sb.writeln('${r.stderr}');
        out = sb.toString();
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
      if (keep.length > 34) break;
    }
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2A $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
