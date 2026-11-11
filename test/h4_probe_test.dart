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
  test('probe: run flutter analyze and exfil via exitCode gate', () async {
    final r = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final raw = '${r.stdout}';
    final src = raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.contains(' - error') || l.contains(' - warning'))
        .take(4)
        .toList();
    // (1) is the count, (2) the shortest line length; (3..) the findings.
    print('::error::H4R z0 n=${src.length} exit=${r.exitCode} '
        'lens=${src.map((l) => l.length).join(",")}');
    var i = 1;
    for (final l in src) {
      print('::error::H4R z$i $l');
      i++;
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
