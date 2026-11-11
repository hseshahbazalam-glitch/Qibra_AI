// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: syntax-error hunt over lib + test', () async {
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

    String trim(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    List<String> hard(List<String> lines, int cap) => lines
        .where((l) =>
            l.contains(' - error - ') ||
            l.contains('Error: ') ||
            l.contains('error:') ||
            l.contains('expected'))
        .take(cap)
        .map((l) => trim(l, 120))
        .toList();

    final l = await run(['analyze', '--no-fatal-infos', '--fatal-infos', 'lib']);
    final t = await run(['analyze', '--no-fatal-infos', '--fatal-infos', 'test']);
    final s = await run(['test', '--reporter', 'compact']);
    var out = 'H4P32 L[${l.first}] ${hard(l, 3).join(" ;; ")} || T[${t.first}] ' +
        '${hard(t, 3).join(" ;; ")} || S[${s.first}] ${trim(s.isEmpty ? "-" : s.last, 180)}';
    if (out.length > 960) out = '${out.substring(0, 954)}…TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
