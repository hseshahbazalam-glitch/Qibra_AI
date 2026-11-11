// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v82, deleted with its
// own commit). v81 burned 13 min replaying the whole package (the 11-min timeout
// killed it mid-run — no payload, disclosed). The scope is now the MINIMAL pair
// that reproduces: my new H4 file + the multilang file, in both orders, inside
// one process (--concurrency 1), each reported as a short line around its [E].
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _h4 = 'test/features/hadith/hadith_h4_search_test.dart';
const _ml = 'test/features/hadith/hadith_multilang_test.dart';

Future<List<String>> _pair(String a, String b) async {
  final r = await Process.run(
      'flutter', ['test', '--reporter', 'compact', '--concurrency', '1', a, b],
      workingDirectory: Directory.current.path,
      environment: Platform.environment);
  final src = <String>[];
  for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
    src.addAll(l
        .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
        .split('\r')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty));
  }
  String cut(String s, int k) => s.length > k ? '${s.substring(0, k)}…' : s;
  final ei = src.indexWhere((l) => l.contains('[E]'));
  final res = <String>['exit=${r.exitCode} n=${src.length} ei=$ei'];
  if (ei >= 0) {
    for (var j = -2; j < 4 && ei + j < src.length; j++) {
      if (ei + j < 0) continue;
      res.add('${j > 0 ? '+' : ''}$j|${cut(src[ei + j], 160)}');
    }
  } else {
    res.add('last|${cut(src.isEmpty ? '-' : src.last, 160)}');
  }
  return res;
}

void main() {
  test('probe: the H4 x multilang interaction, both orders', () async {
    final forward = await _pair(_h4, _ml);
    final backward = await _pair(_ml, _h4);
    for (var i = 0; i < forward.length; i++) {
      print('::error::P82 F$i ${forward[i]}');
    }
    for (var i = 0; i < backward.length; i++) {
      print('::error::P82 B$i ${backward[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
