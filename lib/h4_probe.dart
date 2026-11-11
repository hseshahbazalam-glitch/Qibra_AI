// ignore_for_file: type=lint
// TRANSIENT diagnostic probe (H4 round only) — lives in lib/ so the analyzer
// keeps it in scope (a test/ probe is skipped whenever test/ leaves the gate,
// which killed v9..v35) and its own findings are self-ignored. It runs the
// analyzer in MACHINE format (one line per diagnostic, severity prefix '4=' ==
// error) and ships the packed findings in a failed test's message — the only
// CI channel that survives both log truncation and a red gate. DELETED before
// the pass closes.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: machine-format analyzer findings', () async {
    Future<List<String>> run(List<String> args) async {
      final r = await Process.run('flutter', args,
          workingDirectory: Directory.current.path,
          environment: Platform.environment);
      final out = <String>['x${r.exitCode}'];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        out.addAll(l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty));
      }
      return out;
    }

    String cut(String l, int k) => l.length > k ? l.substring(0, k) : l;
    String pack(List<String> lines) {
      final found = <String>[];
      var infos = 0;
      for (final l in lines) {
        if (!l.contains('\x02')) continue;
        if (l.contains('4=')) {
          found.add(l);
        } else {
          infos++;
        }
      }
      String one(String l) {
        final p = l.split('\x02').skip(2).toList();
        final loc = p.length > 2 ? '${p[1]}:${p[2]}' : '?';
        final code = p.length > 3 ? p[3] : '?';
        final msg = p.length > 4 ? p[4] : l;
        final file = (p.isNotEmpty ? p[0] : '')
            .replaceFirst('/home/runner/work/Qibra_AI/Qibra_AI/', '');
        return cut('$file|$loc|$code|$msg', 120);
      }

      return 'i$infos ' + found.take(6).map(one).join(' ;; ');
    }

    final lib = await run(['analyze', '--machine', 'lib']);
    final tst = await run(['analyze', '--machine', 'test']);
    var out = 'H4P37 LIB${lib.first} ' +
        '${pack(lib)} || TEST${tst.first} ${pack(tst)}';
    if (out.length > 980) out = '${out.substring(0, 974)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
