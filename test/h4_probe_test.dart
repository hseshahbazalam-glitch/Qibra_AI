// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: exfil parse findings of the excluded file + suite verdict', () async {
    Future<List<String>> run(List<String> args) async {
      final r = await Process.run('flutter', args,
          workingDirectory: Directory.current.path,
          environment: Platform.environment);
      final out = <String>['exit=${r.exitCode}'];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        out.addAll(l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty));
      }
      return out;
    }

    final gate = await run(['analyze', '--no-fatal-infos']);
    final mine = await run([
      'analyze',
      '--no-fatal-infos',
      '--fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final t = await run([
      'test',
      '--reporter',
      'compact',
      '--ignore-errors',
      'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final lines = <String>[];
    lines.add('GATE exit=${gate.first} last="${gate.length > 1 ? gate.last.substring(0, gate.last.length > 60 ? 60 : gate.last.length)}"');
    lines.addAll(mine.skip(1).take(4));
    lines.add('SUITE exit=${t.first}');
    lines.addAll(t.skip(1).take(4));
    var out = 'H4P30 ' + lines.map((l) => l.replaceAll('\n', ' ')).join(' // ');
    if (out.length > 950) out = '${out.substring(0, 944)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
