// test/h4_probe_test.dart — TRANSIENT diagnostic probe (H4 round only, deleted
// with its own commit before the pass closes). Channel: `::error::` prints from
// a GREEN test in the suite step — the only CI surface that survives log
// truncation, and it needs the test/ tree (flutter test runs nothing else).
// Runs the analyzer over the whole package (the truth the red gate hides) and
// echoes its error/warning lines verbatim, plus the H4 suite verdict.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: the finding lines and the compiler message', () async {
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
    // (1) whole-package analyze, GATE FLAGS, error/warning findings only
    final whole = await res(['analyze', '--no-fatal-infos']);
    final wl = linesOf(whole);
    final we = wl
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .toList();
    print('::error::P47 WH exit=${whole.exitCode} n=${wl.length} e=${we.length}');
    for (var i = 0; i < we.length && i < 5; i++) {
      print('::error::P47 w$i ${cut(we[i], 190)}');
    }
    // (2) the explicit single-file analyze, ALL lines (n was 5 — see them all)
    final one = await res(['analyze', '--no-fatal-infos', '--fatal-infos', target]);
    final ol = linesOf(one);
    print('::error::P47 ON exit=${one.exitCode} n=${ol.length}');
    for (var i = 0; i < ol.length && i < 4; i++) {
      print('::error::P47 o$i ${cut(ol[i], 190)}');
    }
    // (3) the compiler message (truncation: print from the FIRST [E])
    final su = await res(['test', '--reporter', 'compact', target]);
    final sl = linesOf(su);
    final ei = sl.indexWhere((l) => l.contains('[E]'));
    print('::error::P47 SU exit=${su.exitCode} n=${sl.length} eIdx=$ei');
    for (var i = 0; i < 4 && ei + i + 1 < sl.length; i++) {
      print('::error::P47 e$i ${cut(sl[ei + 1 + i], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
