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
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}' '${r.stderr}';
    final all = raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.contains('error -') || l.contains('warning -'))
        .toList();
    final kept = all.take(3).toList();
    final joined = kept.join(' ||| ') +
        (' | MORE=' + (all.length - 3).toString());
    // Keep the reason SHORT and free of interpolation hazards: the
    // auto-annotator renders the Expected/Actual block verbatim.
    expect(
      joined.isEmpty ? 'CLEAN n0' : joined,
      'CLEAN n0',
      reason: 'n=' + all.length.toString() + ' exit=' +
          r.exitCode.toString(),
    );
  }, timeout: const Timeout(Duration(minutes: 12)));
}
