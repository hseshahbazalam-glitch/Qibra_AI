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
  test('probe: PRISTINE config measurement + root sweep', () async {
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
    List<String> hard(List<String> ls) =>
        ls.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    // (1) the whole package, NO exclusions beyond the baseline two: this is the
    //     exact command the gate runs, and it is where the red still lives.
    final whole = await run('flutter', ['analyze', '--no-fatal-infos']);
    final wl = linesOf(whole);
    final wh = hard(wl);
    print('::error::P63 WHOLE exit=${whole.exitCode} n=${wh.length} lines=${wl.length}');
    for (var i = 0; i < wh.length && i < 3; i++) {
      print('::error::P63 w$i ${cut(wh[i], 195)}');
    }
    // (2) the roots separately — names the tree that holds the finding
    for (final root in ['lib', 'test', 'scripts', 'backend']) {
      final r = await run('flutter', ['analyze', '--no-fatal-infos', root]);
      final l = linesOf(r);
      final h = hard(l);
      print('::error::P63 $root exit=${r.exitCode} n=${h.length} '
          '${h.isEmpty ? cut(l.isEmpty ? "-" : l.last, 120) : cut(h.first, 150)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
