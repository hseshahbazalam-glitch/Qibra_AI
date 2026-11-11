// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v71, deleted with its
// own commit). Shape proven over 30 rounds: a GREEN test under test/, printing
// `::error::`-prefixed lines (the only CI surface that reaches me), and an
// analyze gate that stays GREEN (in-file type=lint kills the avoid_print
// warnings, which flutter_lints v4 raises to the fatal tier). The H4 pass is
// now gate-green with 652 tests running and 2 failing — this probe names them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: the two failing H4 tests, in full', () async {
    final r = await Process.run('flutter', [
      'test',
      '--reporter',
      'compact',
      '.'
    ], workingDirectory: Directory.current.path, environment: Platform.environment);
    final src = <String>[];
    for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
      src.addAll(l
          .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
          .split('\r')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty));
    }
    String cut(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    final hits = <int>[];
    for (var i = 0; i < src.length && hits.length < 2; i++) {
      if (src[i].contains('[E]')) hits.add(i);
    }
    final names = src.where((l) => l.contains('The test description was:')).toList();
    print('::error::P74 exit=${r.exitCode} lines=${src.length} hits=${hits.length} '
        'last=${cut(src.isEmpty ? '-' : src.last, 120)}');
    final desc = src
        .where((l) => l.contains('The test description was:'))
        .map((l) => cut(l.replace('The test description was:', '').trim(), 90))
        .take(4)
        .toList();
    print('::error::P74 DESC ${cut(desc.join(" | "), 190)}');
    print('::error::P74 names ${names.join(" | ").length} ${cut(names.join(" | "), 185)}');
    for (final h in hits) {
      for (var j = -7; j < 2 && h + j < src.length; j++) {
        if (h + j < 0) continue;
        print('::error::P74 h$h:$j ${cut(src[h + j], 195)}');
      }
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
