// test/h4_probe_test.dart — TRANSIENT replay probe (H4 round only).
// The CI test step truncates its log; the ONLY channel that survives is
// the annotations API, capped at ~10 ::error lines per run. This probe
// replays exactly the failing file with the compact reporter and exfils
// up to 8 unique indexed [E] lines. DELETE before the pass closes.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: replay hadith_h4_search_test and exfil the [E] lines',
      () async {
    final r = await Process.run('flutter', [
      'test',
      '--reporter',
      'compact',
      'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final raw = '${r.stdout}\n${r.stderr}';
    final ansi = RegExp('\x1B\\[[0-9;]*[A-Za-z]');
    final lines = raw
        .split('\n')
        .map((l) => l.replaceAll(ansi, '').trimRight())
        .where((l) => l.contains('[E]') || l.contains('failed') || l.contains('passed'))
        .toList();
    final keep = lines.take(9).toList();
    for (var i = 0; i < keep.length; i++) {
      final msg = keep[i].length > 170 ? '${keep[i].substring(0, 170)}…' : keep[i];
      stderr.writeln('::error::H4R n$i $msg');
    }
    // Marker so a zero-[E] replay still annotates (probe self-report).
    stderr.writeln('::error::H4R nX keep=${keep.length} exit=${r.exitCode}');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
