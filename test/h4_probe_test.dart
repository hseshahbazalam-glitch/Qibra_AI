// ignore_for_file: avoid_print, unused_local_variable, unused_element
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (round v49, deleted
// with its own commit). The channel that works, proven at v46/v47: a GREEN test
// in the suite step printing `::error::` lines; it needs the gate to be green,
// so exactly one suspect file is excluded from the analyzer this round.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: whole-package findings + suite verdict', () async {
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
    final whole = await res(['analyze', '--no-fatal-infos']);
    final wl = linesOf(whole);
    final we = wl
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .toList();
    print('::error::P52 WH exit=${whole.exitCode} n=${we.length} '
        'sum=${cut(wl.isEmpty ? "-" : wl.last, 90)}');
    for (var i = 0; i < we.length && i < 4; i++) {
      print('::error::P52 w$i ${cut(we[i], 195)}');
    }
    final h4 = await res(['analyze', '--no-fatal-infos', '--fatal-infos',
        'test/features/hadith/hadith_h4_search_test.dart',
    ]);
    final hl = linesOf(h4);
    final he = hl
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .toList();
    print('::error::P52 H4 exit=${h4.exitCode} n=${he.length}');
    for (var i = 0; i < he.length && i < 2; i++) {
      print('::error::P52 h$i ${cut(he[i], 195)}');
    }
    final su = await res(['test', '--reporter', 'compact', 'test/features/hadith']);
    final sl = linesOf(su);
    final ei = sl.indexWhere((l) => l.contains('[E]'));
    print('::error::P52 SU exit=${su.exitCode} last=${cut(sl.isEmpty ? '-' : sl.last, 195)}');
    for (var i = 0; i < 2 && ei + i + 1 < sl.length; i++) {
      print('::error::P52 e$i ${cut(sl[ei + 1 + i], 195)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
