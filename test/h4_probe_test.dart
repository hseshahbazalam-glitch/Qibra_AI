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
  test('probe: run flutter analyze; FAIL with the finding count', () async {
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}\n${r.stderr}'.trim();
    final bad = raw
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '')
            .trim()
            .replaceAll('\n', ''))
        .where((l) => l.contains('error') || l.contains('warning'))
        .where((l) => !l.contains('issues found'))
        .toList();
    // The ANNOTATION itself carries the truth: red test => 'probe: run
    // flutter analyze; FAIL with the finding count' line with
    // 'Expected/Actual' below shows exit + how many lines mention
    // error/warning. If the gate still fails with bad=0, the step
    // failure is NOT from a printed finding (e.g. crash -> read raw tail
    // in the test-step annotation: it holds the full failure block).
    expect(
      '${r.exitCode}',
      '0',
      reason: 'exit=${r.exitCode} bad=${bad.length} '
          'head1=${bad.isEmpty ? "-" : bad.first}',
    );
  }, timeout: const Timeout(Duration(minutes: 12)));
}
