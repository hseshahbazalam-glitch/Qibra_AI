// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: trustworthy gate + explicit test-suite verdict', () async {
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
    final mine = linesOf(await res(
        ['analyze', '--no-fatal-infos', 'test/features/hadith/hadith_h4_search_test.dart']));
    final suite = linesOf(
        await res(['test', '--reporter', 'compact', '--ignore-errors']));
    final hard = mine
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .take(3)
        .map((l) => trim(l, 145))
        .join(' ;; ');
    var out = 'H4P35 GATE exit=${gate.first} "${trim(gate.length > 1 ? gate[1] : '-', 90)}" || '
        'MINE exit=${mine.first} n=${mine.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).length} '
        '[$hard] || SUITE exit=${suite.first} tail="${trim(suite.last, 170)}"';
    if (out.length > 970) out = '${out.substring(0, 964)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
