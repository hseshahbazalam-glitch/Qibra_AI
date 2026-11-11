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
  test('probe: replicate the analyze gate exactly and print findings', () async {
    // v24: the gate is `flutter analyze --no-fatal-infos` (exit 1 on any
    // error OR warning; infos sanctioned). The gate step annotates only
    // its TAIL, so this probe re-runs the same command and PRINTS the
    // first findings — a green test's prints stream through the
    // reporter, which the SUITE step keeps in its annotation (the
    // Process-completed tail of a failing suite carries them).
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}${r.stderr}';
    final all = raw
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '')
            .trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final bad =
        all.where((l) => l.contains(' - error') || l.contains(' - warning')).toList();
    print('H4PROBE exit=${r.exitCode} n=${bad.length}');
    for (var i = 0; i < bad.length && i < 6; i++) {
      print('H4PROBE f$i ${bad[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
