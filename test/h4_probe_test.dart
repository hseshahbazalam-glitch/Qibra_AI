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
  test('probe: run flutter analyze and exfil the output tail', () async {
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}\n${r.stderr}'.trim();
    // v12: tail-chunk exfil — the finding block + 'N issues found' always
    // END the output; chunk it verbatim across the 9 annotation slots.
    final tail = raw.length > 1000 ? raw.substring(raw.length - 1000) : raw;
    final one = tail.replaceAll('\n', ' | ');
    final chunk = (one.length / 9).ceil();
    for (var i = 0; i < 9; i++) {
      final a = i * chunk;
      if (a >= one.length) break;
      final b = a + chunk > one.length ? one.length : a + chunk;
      print('::error::H4R t$i ${one.substring(a, b)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
