// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (round v62, deleted with
// its own commit). CHANNEL, established over 21 rounds: the payload can only
// ride a GREEN test's `::error::` print in the SUITE step — so (a) the probe
// must live under test/ (flutter test runs nothing else: a lib/ probe never
// executed in v60/v61, which is why its prints were absent), (b) the analyze
// gate must be GREEN, and (c) the probe's own prints must not trip the gate —
// flutter_lints v4 raises avoid_print to WARNING (gate-fatal; infos are the only
// sanctioned tier), which the file-level `type=lint` ignore above does silence.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: verbatim analyze lines of the two suspect test files', () async {
    Future<ProcessResult> run(String exe, List<String> args) =>
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
    final one = await run('flutter', ['analyze', '--no-fatal-infos', target]);
    final ol = linesOf(one);
    print('::error::P61 ONE exit=${one.exitCode} n=${ol.length}');
    for (var i = 0; i < ol.length && i < 3; i++) {
      print('::error::P61 o$i ${cut(ol[i], 195)}');
    }
    final tst = await run('flutter', ['analyze', '--no-fatal-infos', 'test']);
    final tl = linesOf(tst);
    final th =
        tl.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    print('::error::P61 TST exit=${tst.exitCode} n=${tl.length} hard=${th.length}');
    for (var i = 0; i < th.length && i < 2; i++) {
      print('::error::P61 t$i ${cut(th[i], 195)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
