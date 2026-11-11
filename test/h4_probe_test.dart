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
  test('probe: run flutter analyze; FAIL with the findings', () async {
    // v19 — every earlier channel was wrong: test-step stdout goes only
    // to the LOG file (never an annotation); prints from GREEN tests
    // never annotate at all; the step's Process-completed line is its
    // stderr tail. So the probe must FAIL with the findings IN its
    // uncaught-exception header, SHORT enough to survive the ~1000-char
    // annotation window: one compact line per finding, capped at 3.
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}${r.stderr}';
    final bad = raw
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '')
            .replaceAll('\r', '')
            .trim())
        .where((l) => l.contains('error -') || l.contains('warning -'))
        .map((l) {
          final i = l.indexOf(' - ');
          final path = i > 0 ? l.substring(0, i).split('/').last : l;
          final tail = i > 0 ? l.substring(i + 3) : '';
          return tail.isEmpty ? path : '$path:${tail.substring(0, tail.length > 48 ? 48 : tail.length)}';
        })
        .take(3)
        .toList();
    final summary = raw
        .split('\n')
        .map((l) => l.trim())
        .firstWhere(
            (l) => l.contains('issue') || l.contains('No issues'),
            orElse: () => 'no-summary');
    if (r.exitCode == 0) {
      expect(1, 1, reason: 'ANALYZE-PASSED n=${bad.length}');
    }
    expect(0, bad.isEmpty ? 1 : 0,
        reason: 'A1[${bad.length > 0 ? bad[0] : ''}] '
            'A2[${bad.length > 1 ? bad[1] : ''}] '
            'A3[${bad.length > 2 ? bad[2] : ''}] '
            'SUM[$summary]');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
