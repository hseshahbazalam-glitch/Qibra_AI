// test/h4_probe_test.dart — TRANSIENT diagnostic probe (H4 round only, deleted
// with its own commit before the pass closes). Channel: `::error::` prints from
// a GREEN test in the suite step — the only CI surface that survives log
// truncation, and it needs the test/ tree (flutter test runs nothing else).
// Runs the analyzer over the whole package (the truth the red gate hides) and
// echoes its error/warning lines verbatim, plus the H4 suite verdict.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: parse-error location via the formatter oracle', () async {
    Future<ProcessResult> res(List<String> args, [String exe = 'flutter']) =>
        Process.run(exe, args,
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
    const target = 'test/features/hadith/hadith_h4_search_test.dart';
    // (1) the formatter is a pure-PARSER oracle: its stderr prints
    //     "<file>:<line>:<col>: <message>" for every syntax error.
    final fmt = await res(['format', '--output=none', '--summary=none', target], 'dart');
    final fl = linesOf(fmt);
    print('::error::P46 FMT exit=${fmt.exitCode} n=${fl.length}');
    for (var i = 0; i < fl.length && i < 5; i++) {
      print('::error::P46 m$i ${cut(fl[i], 178)}');
    }
    // (2) the analyzer on that one path (file-level findings incl. parse errors)
    final an = await res(['analyze', '--no-fatal-infos', '--fatal-infos', target]);
    final al = linesOf(an);
    final ah = al.where((l) => !l.contains(' - info - ')).toList();
    print('::error::P46 AN exit=${an.exitCode} n=${al.length} k=${ah.length}');
    for (var i = 0; i < ah.length && i < 3; i++) {
      print('::error::P46 a$i ${cut(ah[i], 178)}');
    }
    // (3) the suite verdict for the same file (compile errors name file:line too)
    final su = await res(['test', '--reporter', 'compact', target]);
    final sl = linesOf(su);
    print('::error::P46 SU exit=${su.exitCode} n=${sl.length}');
    for (var i = 0; i < sl.length && i < 3; i++) {
      print('::error::P46 s$i ${cut(sl[i], 178)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
