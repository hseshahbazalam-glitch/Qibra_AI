// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: lib findings + test/ findings + suite verdict', () async {
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

    String trim(String l, int k) => l.length > k ? l.substring(0, k) : l;
    List<String> find(List<String> lines, int cap) => lines
        .where((l) =>
            RegExp(r' - (error|warning|info) - ').hasMatch(l) ||
            l.contains('issues found'))
        .take(cap)
        .toList();

    final gate = await run(['analyze', '--no-fatal-infos']);
    final mine = await run([
      'analyze',
      '--no-fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final t = await run(['test', '--reporter', 'compact']);
    final tlast = t.isEmpty ? '-' : trim(t.last, 200);
    var out = 'H4P31 G[${gate.first}] ' +
        '${find(gate, 2).map((l) => trim(l, 130)).join(" ;; ")} ' +
        '|| S[${mine.first}] ' +
        '${find(mine, 2).map((l) => trim(l, 130)).join(" ;; ")} ' +
        '|| T[${t.first}] ' +
        '${trim(t.last, 240)} ' +
        '|| T2 ' +
        '${trim(t.length > 2 ? t[t.length - 2] : '-', 160)}';
    if (out.length > 960) out = '${out.substring(0, 954)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
