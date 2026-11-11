// test/h4_probe_test.dart — TRANSIENT replay probe (H4 round only).
// The CI test step truncates its log; the ONLY channel that survives is
// the annotations API, capped at ~10 ::error lines per run. QH lesson:
// the probe must FAIL, or flutter test swallows the captured output —
// only a red test's stderr reaches the job log for the runner to annotate.
// This probe replays exactly the pass's test file with the compact
// reporter and exfils up to 9 indexed lines ([E] + Expected/Which detail).
// DELETE before the pass closes (retirement commit, disclosed).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _clean(String l) {
  final s = l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim();
  return s.length > 120 ? '${s.substring(0, 120)}…' : s;
}

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
    final src = raw.split('\n');
    final pick = <String>[];
    for (var i = 0; i < src.length && pick.length < 8; i++) {
      final l = src[i].trim();
      if (l.contains('[E]')) {
        pick.add(_clean(l));
        for (var j = i + 1;
            j < src.length && pick.length < 8 && pick.length > 0; j++) {
          final e = src[j].trim();
          if (e.contains('[E]')) break;
          if (e.startsWith('Expected:') ||
              e.startsWith('Actual:') ||
              e.startsWith('Which:')) {
            pick.add(_clean(e));
          }
          if (e.startsWith('00:') ||
              e.startsWith('To run') ||
              e.isEmpty) {
            continue;
          }
          if (pick.length >= 8) break;
        }
      }
    }
    // QH PROBE PRECEDENCE (h2_analyze_probe, ab43613): the channel that
    // arrives as an annotation is the harness print() — the reporter
    // echoes test prints; raw stderr writes get captured and swallowed.
    if (pick.isEmpty) {
      pick.add('NO-E-LINES rawlen=${raw.length} exit=${r.exitCode}');
    }
    for (var i = 0; i < pick.length; i++) {
      print('::error::H4R n$i ${pick[i]}');
    }
    print('::error::H4R nX keep=${pick.length} exit=${r.exitCode}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
