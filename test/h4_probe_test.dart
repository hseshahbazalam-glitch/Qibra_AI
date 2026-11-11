// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: gate oracle + suite verdict', () async {
    Future<ProcessResult> res(List<String> args) => Process.run('flutter', args,
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    List<String> linesOf(ProcessResult r) {
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
    final gate = linesOf(await res(['analyze', '--no-fatal-infos']));
    final suite = linesOf(await res(['test', '--reporter', 'compact', '--ignore-errors']));
    final hard = gate
        .where((l) =>
            l.contains('Error:') || l.contains('error - ') || l.contains('expected'))
        .take(4)
        .map((l) => trim(l, 130))
        .join(' ;; ');
    final fails = suite
        .where((l) => l.startsWith('[E]') || l.contains('Failed to load'))
        .take(2)
        .map((l) => trim(l, 150))
        .toList();
    var out = 'H4P34 GATE exit=${gate.first} ${gate.length - 1}L [$hard] || SUITE exit=${suite.first} '
        '${suite.length - 1}L tail="${trim(suite.last, 150)}" fails=${fails.join(" ;; ")}';
    if (out.length > 970) out = '${out.substring(0, 964)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
