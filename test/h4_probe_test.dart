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
  test('probe: print a channel marker from the suite step', () {
    // v23 — decisive channel test: does a GREEN test's print in the
    // suite step arrive anywhere in this job (annotations-wise)? If
    // H4PMARK shows up, the prints ARE exfiltrable and the v20/v22
    // silence meant the probe never RAN or its child analyze died.
    // Also run the child and print its exit code + raw lengths.
    print('H4PMARK channel-probe 0');
    final r = Process.runSync(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    print('H4PMARK exit=${r.exitCode} out=${r.stdout.toString().length} err=${r.stderr.toString().length}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
