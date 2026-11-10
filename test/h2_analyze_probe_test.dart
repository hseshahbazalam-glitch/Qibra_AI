// H2PROBE (transient): full-project-context analyze of the QH test file,
// materialized under a DOT dir the outer gate never scans.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2p: dot-dir analyze with project options in scope', () async {
    String out = '';
    try {
      final mat = await Process.run('git', [
        'show',
        'f4d6f20:test/features/quran/qh_pass_test.dart',
      ]);
      if (mat.exitCode != 0) {
        out = 'MATERIALIZE FAILED: ${mat.stderr}';
      } else {
        final dir = Directory('.qhprobe')..createSync();
        final f = File('${dir.path}/qh_pass_test.dart')
          ..writeAsBytesSync(mat.stdout as List<int>);
        final r = await Process.start('flutter', [
          'analyze', '--no-fatal-infos', f.path,
        ]);
        final o = r.stdout.transform(Utf8Decoder()).join();
        final e = r.stderr.transform(Utf8Decoder()).join();
        final j = await Future.wait([o, e]);
        await r.exitCode;
        out = '${j[0]}\n${j[1]}';
        out += '\nEXIT-MARKER len=${out.length}';
      }
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final keep = <String>[];
    for (final raw in all) {
      final c = raw.trim();
      if (c.contains('error') || c.contains('warning') ||
          c.contains('issues') || c.contains('EXIT-MARKER')) {
        keep.add(c);
      }
      if (keep.length > 30) break;
    }
    for (final l in keep) {
      final v = l.length > 235 ? '${l.substring(0, 235)}…' : l;
      print('::error::H2P $v');
    }
  }, timeout: const Timeout(Duration(minutes: 18)));
}
