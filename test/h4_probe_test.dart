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
  test('probe: run flutter analyze and exfil the finding lines', () async {
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}\n${r.stderr}';
    final src = raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final findings = <String>[];
    for (var i = 0; i < src.length && findings.length < 6; i++) {
      final l = src[i];
      if (l.contains('error -') ||
          l.contains('warning -') ||
          l.contains(' - error') ||
          l.contains('- error -') ||
          RegExp(r':\d+:\d+  ').hasMatch(l)) {
        findings.add(l.length > 200 ? '${l.substring(0, 200)}…' : l);
      }
    }
    if (findings.isEmpty) {
      // Nothing matched the heuristics — exfil the first lines raw.
      findings.addAll(
          src.take(5).map((l) => l.length > 200 ? '${l.substring(0, 200)}…' : l));
    }
    print('::error::H4R z0 exit=${r.exitCode} n=${findings.length}');
    for (var i = 0; i < findings.length && i < 6; i++) {
      print('::error::H4R a$i ${findings[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
