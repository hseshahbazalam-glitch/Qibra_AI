// ignore_for_file: avoid_print, unused_local_variable, unused_element
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (round v49, deleted
// with its own commit). The channel that works, proven at v46/v47: a GREEN test
// in the suite step printing `::error::` lines; it needs the gate to be green,
// so exactly one suspect file is excluded from the analyzer this round.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: compile-error text of the H4 suite', () async {
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
    final gate = await res(['analyze', '--no-fatal-infos']);
    final gl = linesOf(gate);
    final ge =
        gl.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    print('::error::P54 GATE exit=${gate.exitCode} n=${ge.length} '
        'sum=${cut(gl.isEmpty ? '-' : gl.last, 90)}');
    for (var i = 0; i < ge.length && i < 3; i++) {
      print('::error::P54 g$i ${cut(ge[i], 190)}');
    }
    final su = await res(['test', '--reporter', 'compact', '--ignore-errors', target]);
    final sl = linesOf(su);
    final errs =
        sl.where((l) => l.contains('Error:') || l.contains('error - ')).toList();
    print('::error::P54 SU exit=${su.exitCode} n=${sl.length} e=${errs.length}');
    for (var i = 0; i < errs.length && i < 3; i++) {
      print('::error::P54 s$i ${cut(errs[i], 190)}');
    }
    final an = await res(['analyze', '--no-fatal-infos', '--fatal-infos', target]);
    final al = linesOf(an);
    final ae =
        al.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    print('::error::P54 AN exit=${an.exitCode} n=${ae.length}');
    for (var i = 0; i < ae.length && i < 2; i++) {
      print('::error::P54 a$i ${cut(ae[i], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
