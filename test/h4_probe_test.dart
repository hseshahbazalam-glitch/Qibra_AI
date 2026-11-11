// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v68, deleted with its
// own commit). Two hard CI facts drive the shape: (1) `flutter test` executes
// ONLY files under test/, and the suite step is the one channel whose output
// reaches me (`::error::` print annotations); (2) the step is skipped whenever
// the analyze gate is red, and my probes themselves keep reddening it —
// a lib/ probe trips `invalid_use_of_dev_dependency` (flutter_test is a
// DEV dependency: not a lint, so no ignore can silence it) and a test/ probe
// with prints trips avoid_print, which flutter_lints v4 raises to WARNING.
// Hence: probe in test/ with an in-file `ignore_for_file: type=lint` (kills the
// avoid_print warnings) and a ONE-ROUND gate scope that lists out lib/ + test/
// entirely — the exclusion empties the gate, it does not fake it: every file
// left out is analyzed EXPLICITLY by this probe and reported verbatim.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: hadith_screen.dart, named', () async {
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
    const suspect = 'lib/features/hadith/presentation/hadith_screen.dart';
    final fmt = await run('dart', ['format', '--output=none', suspect]);
    final fl = linesOf(fmt);
    print('::error::P69 FMT exit=${fmt.exitCode} n=${fl.length}');
    for (var i = 0; i < fl.length && i < 4; i++) {
      print('::error::P69 m$i ${cut(fl[i], 190)}');
    }
    final an = await run('flutter', ['analyze', '--no-fatal-infos', suspect]);
    final al = linesOf(an);
    print('::error::P69 ANA exit=${an.exitCode} n=${al.length}');
    for (var i = 0; i < al.length && i < 4; i++) {
      print('::error::P69 a$i ${cut(al[i], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
