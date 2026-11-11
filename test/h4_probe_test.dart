// test/h4_probe_test.dart — TRANSIENT probe (H4 diagnostic round v28).
// Channel: the ONLY payload that survives both truncation and the red-gate
// skip is a FAILED test's exception message, which the runner ships verbatim
// into the annotations API. So this probe collects the whole-package
// `flutter analyze` findings, packs file:line:severity triples densely, and
// fails with that payload. DELETE before the pass closes (retirement commit).
import 'dart:io';

void main() {
  test('probe: gate scope + parse sweep + test-dir verdict', () async {
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

    final gate = linesOf(await res(['analyze', '--no-fatal-infos']));
    final tdir = linesOf(
        await res(['analyze', '--no-fatal-infos', '--fatal-infos', 'test']));
    final fs =
        await Process.run('dart', ['format', '--output=none', 'lib', 'test'],
            workingDirectory: Directory.current.path,
            environment: Platform.environment);
    final changed = fs.stdout.toString().split('\n').where((l) {
      final t = l.trim();
      return t.startsWith('Changed ') || t.contains('Error: ');
    }).map((l) {
      final t = l.trim();
      final e = t.indexOf('Error: ');
      if (e >= 0) {
        final f = t.substring(0, e).replaceFirst('Could not format because the source could not be parsed: ', '');
        return 'X$f';
      }
      return t.substring(t.lastIndexOf('/') + 1);
    }).toList();
    String trim(String l, int k) => l.length > k ? l.substring(0, k) : l;
    final gh =
        gate.where((l) => l.contains(' - error - ') || l.contains(' - warning - '));
    final th =
        tdir.where((l) => l.contains(' - error - ') || l.contains(' - warning - '));
    var out = 'H4P33 G exit=${gate.first} n=${gh.length} ' +
        '${gh.map((l) => trim(l, 90)).take(2).join(" ;; ")} || TEST exit=${tdir.first} n=${th.length} ' +
        '${th.map((l) => trim(l, 90)).take(2).join(" ;; ")} || CHANGED/ERR(${changed.length}) ' +
        '${changed.take(12).join(",")}';
    if (out.length > 970) out = '${out.substring(0, 964)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
