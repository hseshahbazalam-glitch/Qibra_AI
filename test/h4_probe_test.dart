// test/h4_probe_test.dart — TRANSIENT diagnostic probe (H4 round only, deleted
// with its own commit before the pass closes). Channel: `::error::` prints from
// a GREEN test in the suite step — the only CI surface that survives log
// truncation, and it needs the test/ tree (flutter test runs nothing else).
// Runs the analyzer over the whole package (the truth the red gate hides) and
// echoes its error/warning lines verbatim, plus the H4 suite verdict.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: whole-package analyze findings + H4 suite verdict', () async {
    Future<ProcessResult> res(List<String> args) => Process.run('flutter', args,
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    List<String> linesOf(ProcessResult r) {
      final out = <String>[];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        out.addAll(l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty));
      }
      return out;
    }

    String cut(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    final gate = await res(['analyze', '--no-fatal-infos']);
    final gl = linesOf(gate);
    final gh = gl.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    print('::error::H4P43 ANALYZE exit=${gate.exitCode} n=${gh.length} '
        'sum=${cut(gl.isEmpty ? '-' : gl.last, 110)}');
    for (var i = 0; i < gh.length && i < 5; i++) {
      print('::error::H4P43 f$i ${cut(gh[i], 175)}');
    }
    final one = await res([
      'analyze',
      '--no-fatal-infos',
      '--fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart'
    ]);
    final ml = linesOf(one);
    final mh = ml.where((l) => RegExp(r' - \w+ - ').hasMatch(l)).toList();
    print('::error::H4P44 H4FILE exit=${one.exitCode} n=${mh.length} '
        'sum=${cut(ml.isEmpty ? "-" : ml.last, 100)}');
    for (var i = 0; i < mh.length && i < 4; i++) {
      print('::error::H4P44 h$i ${cut(mh[i], 175)}');
    }
    final suite = await res([
      'test',
      '--reporter',
      'compact',
      '--ignore-errors',
      'test/features/hadith/hadith_h4_search_test.dart'
    ]);
    final sl = linesOf(suite);
    print('::error::H4P43 SUITE exit=${suite.exitCode} '
        'last=${cut(sl.isEmpty ? '-' : sl.last, 175)}');
    final ev = sl.where((l) => l.startsWith('[E]')).take(3).toList();
    for (var i = 0; i < ev.length; i++) {
      print('::error::H4P43 e$i ${cut(ev[i], 175)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
