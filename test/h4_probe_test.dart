// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: exfil analyzer findings', () async {
    final a = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final all = '${a.stdout}${a.stderr}'
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final bad = all.where((l) {
      final i = l.indexOf(' - ');
      if (i < 1) return false;
      final sev = l.substring(i + 3).split(' ').first;
      return sev == 'error' || sev == 'warning';
    }).toList();
    final pack = <String>[];
    for (final l in bad) {
      final i = l.indexOf(' - ');
      final sev = l.substring(i + 3).split(' ').first;
      final rule = l.substring(i + 3 + sev.length + 1);
      pack.add('${l.substring(0, i)}|$sev|$rule');
    }
    var out = 'H4P28 exit=${a.exitCode} n=${bad.length} :: ${pack.join(" ;; ")}';
    if (out.length > 950) out = '${out.substring(0, 944)}...TAIL';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
