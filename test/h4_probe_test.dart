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
  test('probe: run flutter analyze; print every finding', () async {
    // v21 — same proven v20 channel (GREEN test body + print lines),
    // plus the failing expect so BOTH annotations (suite step + the
    // [E] block in the test step) carry the finding lines.
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '\${r.stdout}\${r.stderr}';
    final bad = raw
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '')
            .trim())
        .where((l) =>
            l.contains(' - error') ||
            l.contains(' - warning') ||
            l.contains('issues found') ||
            l.contains('No issues'))
        .toList();
    print('H4P exit=\${r.exitCode} n=\${bad.length}');
    for (var i = 0; i < bad.length && i < 8; i++) {
      print('H4P f\$i \${bad[i]}');
    }
    expect(r.exitCode, 0, reason: 'H4P exit=\${r.exitCode} n=\${bad.length}');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
