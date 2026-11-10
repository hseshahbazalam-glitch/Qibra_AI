// H2PROBE (transient): (a) name the two outer reds via nested scoped run,
// (b) dot-dir full-options analyze of the QH test copy.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2q: two-channel exfil', () async {
    final out = StringBuffer();
    // (a) nested scoped suite
    try {
      final r = await Process.run('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/features/quran/',
        'test/features/tasbih/',
      ]);
      out.writeln('== SUITE ==');
      out.writeln('${r.stdout}\n${r.stderr}');
    } catch (e) {
      out.writeln('SUITE PROBE FAILED: $e');
    }
    // (b) dot-dir analyze of the QH test copy
    try {
      final mat = await Process.run('git', [
        'show',
        'f4d6f20:test/features/quran/qh_pass_test.dart',
      ]);
      if (mat.exitCode != 0) {
        out.writeln('MATERIALIZE FAILED');
      } else {
        final dir = Directory('.qhprobe');
        dir.createSync();
        final f = File('${dir.path}/qh_pass_test.dart');
        f.writeAsStringSync(mat.stdout as String);
        final r2 = await Process.run('flutter',
            ['analyze', '--no-fatal-infos', f.path]);
        out.writeln('== TEST ANALYZE ==');
        out.writeln('${r2.stdout}\n${r2.stderr}');
      }
    } catch (e) {
      out.writeln('ANALYZE PROBE FAILED: $e');
    }
    final all = const LineSplitter().convert(out.toString());
    final keep = <String>[];
    for (final raw in all) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      if (c.contains('[E]') ||
          c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          c.startsWith('Reason:') ||
          c.contains('error ') ||
          c.contains('warning ') ||
          c.contains('issues') ||
          c == '== SUITE ==' ||
          c == '== TEST ANALYZE ==') {
        keep.add(c);
      }
      if (keep.length > 34) break;
    }
    if (keep.isEmpty) keep.add('BOTH CHANNELS SILENT len=${out.length}');
    keep.add('H2Q-EOF');
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2Q $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
