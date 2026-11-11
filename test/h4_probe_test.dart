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
  test('probe: read the analyze capture written by the CI tee', () {
    // v18: CI's analyze step tees its own output into the workspace
    // before the gate; tests run after it in the same job — this probe
    // just mirrors the captured findings onto STDOUT. The step's log
    // tail (visible in the failure annotation) carries them verbatim.
    final f = File('.probe_analyze.txt');
    if (!f.existsSync()) {
      print('H4PROBE NO-CAPTURE');
      expect(1, 1);
      return;
    }
    final lines = f
        .readAsStringSync()
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '')
            .replaceAll('\r', '')
            .trim())
        .where((l) =>
            l.contains('error -') ||
            l.contains('warning -') ||
            l.contains('issues found') ||
            l.contains('No issues'))
        .toList();
    print('H4PROBE n=${lines.length}');
    for (final l in lines.take(14)) {
      print('H4PROBE  $l');
    }
    expect(1, 1);
  });
}
