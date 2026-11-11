// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v81, deleted with its
// own commit). v80 proved the multilang file is GREEN alone (exit 0) while the
// directory run has 1 red, so the failure is ORDER-dependent; and the full-suite
// run names its own red test — both are read here as short indexed lines
// (reverse order: the annotation window is the log tail, so the payload is
// printed in its own `::error::` lines, never as one long line).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _clean(ProcessResult r) {
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

String _cut(String s, int k) => s.length > k ? '${s.substring(0, k)}…' : s;

Future<List<String>> _failures(List<String> args) async {
  final r = await Process.run('flutter', args,
      workingDirectory: Directory.current.path, environment: Platform.environment);
  final src = _clean(r);
  final ei = src.lastIndexWhere((l) => l.contains('[E]'));
  final res = <String>['exit=${r.exitCode} n=${src.length} ei=$ei'];
  for (var j = -6; j < 3 && ei + j < src.length; j++) {
    if (ei + j < 0) continue;
    res.add('${j > 0 ? '+' : ''}$j|${_cut(src[ei + j], 165)}');
  }
  return res;
}

void main() {
  test('probe: the red test, in both scopes', () async {
    final dir = await _failures([
      'test',
      '--reporter',
      'compact',
      'test/features/hadith',
      '--concurrency',
      '1'
    ]);
    final all = await _failures(['test', '--reporter', 'compact']);
    for (var i = 0; i < dir.length; i++) {
      print('::error::P81 D$i ${dir[i]}');
    }
    for (var i = 0; i < all.length; i++) {
      print('::error::P81 A$i ${all[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
