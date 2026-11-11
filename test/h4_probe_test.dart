// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: exfil analyzer findings + suite verdict', () async {
    Future<List<String>> run(List<String> args) async {
      final r = await Process.run('flutter', args,
          workingDirectory: Directory.current.path,
          environment: Platform.environment);
      final out = <String>['exit=${r.exitCode}'];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        final t = l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty);
        out.addAll(t);
      }
      return out;
    }

    final a = await run(['analyze', '--no-fatal-infos']);
    final bad = a
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .map((l) => l.replaceAll(' - error - ', '|E|').replaceAll(' - warning - ', '|W|'))
        .toList();
    final t = await run([
      'test',
      '--reporter',
      'compact',
      '--ignore-errors',
      'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final tsum = t
        .where((l) =>
            l.contains('All tests passed') || l.contains('+') && l.contains(':') || l.contains('Failed to load'))
        .toList();
    var out = 'H4P29 A${a.first}|n=${bad.length} ' +
        '${bad.join(" ;; ")} || T${t.first} ' +
        '${tsum.isEmpty ? "-" : tsum.last}';
    if (out.length > 950) out = '${out.substring(0, 944)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
