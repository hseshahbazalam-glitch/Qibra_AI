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
  test('probe: analyze findings IN the exception message', () async {
    // v17: green test prints never reach any CI surface; the ONE string
    // this job echoes verbatim into an annotation is the LAST 100 chars
    // of a failing step's stdout tail (the 'Process completed' line).
    // So: FAIL the probe with the findings as its uncaughtError tail.
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
        .take(4)
        .toList();
    final msg = 'EXIT=${r.exitCode} n=${bad.length}'
        '${bad.isEmpty ? ' ANALYZE-CLEAN-TAIL:${raw.trim().isEmpty ? 'EMPTY' : raw.trim().substring(raw.trim().length > 60 ? raw.trim().length - 60 : 0)}' : bad.join(' || ')}';
    throw StateError('H4PROBE $msg');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
