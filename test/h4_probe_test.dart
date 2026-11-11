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

void main() {
  test('probe: analyze findings AND its verdict line', () async {
    // v25: the suite-step annotation window is ~1000 chars — spend it
    // fully: 4 finding lines, then the analyzer's FINAL lines (which
    // contain the '<n> issues found' / 'No issues found' verdict that
    // the gate-step annotation always cuts off). Silence after the
    // H4PROBE marker now means the RUNNER died (12-min self-timeout),
    // not the channel.
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
    final bad = all
        .where((l) => l.contains(' - error') || l.contains(' - warning'))
        .toList();
    print('::error::H4P exit=${r.exitCode} n=${bad.length} lines=${all.length}');
    for (var i = 0; i < bad.length && i < 4; i++) {
      final l = bad[i];
      print('::error::H4P f$i ${l.length > 160 ? l.substring(0, 160) : l}');
    }
    for (final l in all.length > 3 ? all.sublist(all.length - 3) : all) {
      print('::error::H4P tail ${l.length > 160 ? l.substring(0, 160) : l}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
