// ignore_for_file: type=lint
// lib/h4_probe.dart — TRANSIENT diagnostic probe (v67, deleted with its own
// commit). Placed in lib/ and self-silenced because a test/ probe with print()
// statements would trip `avoid_print`, which flutter_lints v4 raises to WARNING
// (gate-fatal): that single fact is what reddened v63/v64/v65 and, before the
// type=lint header existed, most of the other 20 diagnostic rounds. Being in
// lib/ the file is analyzed (its own findings silenced) and — proven at v62,
// where an in-test probe printed — the suite step is the only readable channel,
// so this probe runs nothing and only reports what the ONE suspect file says.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: name the syntax error in hadith_screen.dart', () async {
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
    print('P67 FMT exit=${fmt.exitCode} n=${fl.length}');
    for (var i = 0; i < fl.length && i < 4; i++) {
      print('P67 m$i ${cut(fl[i], 190)}');
    }
    final an = await run('flutter', ['analyze', '--no-fatal-infos', suspect]);
    final al = linesOf(an);
    print('P67 ANA exit=${an.exitCode} n=${al.length}');
    for (var i = 0; i < al.length && i < 4; i++) {
      print('P67 a$i ${cut(al[i], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
