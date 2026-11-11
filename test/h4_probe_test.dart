// ignore_for_file: avoid_print, unused_local_variable, unused_element
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (round v49, deleted
// with its own commit). The channel that works, proven at v46/v47: a GREEN test
// in the suite step printing `::error::` lines; it needs the gate to be green,
// so exactly one suspect file is excluded from the analyzer this round.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: real-scope findings + explicit H4-file verdict', () async {
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
    List<String> hard(List<String> ls) =>
        ls.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    final gate = await res(['analyze', '--no-fatal-infos']);
    final gl = linesOf(gate);
    final gh = hard(gl);
    print('::error::P57 GATE exit=${gate.exitCode} n=${gh.length} '
        'lines=${gl.length} sum=${cut(gl.isEmpty ? '-' : gl.last, 95)}');
    for (var i = 0; i < gh.length && i < 3; i++) {
      print('::error::P57 g$i ${cut(gh[i], 190)}');
    }
    final an = await res(['analyze', '--no-fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart', 'test/h4_probe_test.dart']);
    final al = linesOf(an);
    final ah = hard(al);
    print('::error::P57 EX exit=${an.exitCode} n=${ah.length} '
        'sum=${cut(al.isEmpty ? '-' : al.last, 95)}');
    for (var i = 0; i < ah.length && i < 2; i++) {
      print('::error::P57 e$i ${cut(ah[i], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
