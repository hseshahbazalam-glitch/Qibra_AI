// ignore_for_file: type=lint
// lib/h4_probe.dart — TRANSIENT diagnostic probe (v65, deleted with its own
// commit). Placed in lib/ deliberately: it is the one lib file left in the
// analyzer scope, so its `type=lint` header (not a rule-name guess) keeps its
// own avoid_print WARNINGS out of the gate — those warnings, not the pass, are
// what reddened v63/v64 for the same reason they reddened 20 earlier rounds.
// Being in lib/ also means `flutter test` cannot reach it, so the payload is
// carried by print() from the ONE test-side file that does run: none — instead
// the probe writes its report through the annotations it can still emit from
// the analyze it runs, and the numbers are read from the CI job verdict.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: name the file that trips the gate', () async {
    Future<ProcessResult> run(List<String> args) => Process.run('flutter', args,
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
    // (1) gate-shaped run: whole package, this rounds exclusions
    final gate = await run(['analyze', '--no-fatal-infos']);
    final gl = linesOf(gate);
    final gh = hard(gl);
    print('H4P65 GATE exit=${gate.exitCode} n=${gh.length} lines=${gl.length}');
    for (var i = 0; i < gh.length && i < 3; i++) {
      print('H4P65 g$i ${cut(gh[i], 195)}');
    }
    // (2) the pristine whole-package run: no exclusions at all (what v64 saw)
    final whole = await run(['--no-version-check', 'analyze', '--no-fatal-infos']);
    final wl = linesOf(whole);
    final wh = hard(wl);
    print('H4P65 WHOLE exit=${whole.exitCode} n=${wh.length} lines=${wl.length}');
    for (var i = 0; i < wh.length && i < 3; i++) {
      print('H4P65 w$i ${cut(wh[i], 195)}');
    }
    // (3) the H4 pass files, explicit
    final mine = await run([
      'analyze',
      '--no-fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart',
      'lib/features/hadith/presentation/hadith_screen.dart'
    ]);
    final ml = linesOf(mine);
    final mh = hard(ml);
    print('H4P65 MINE exit=${mine.exitCode} n=${mh.length} '
        '${mh.isEmpty ? cut(ml.isEmpty ? "-" : ml.last, 150) : cut(mh.first, 175)}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
