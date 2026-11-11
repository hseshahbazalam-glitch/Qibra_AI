// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v83, deleted with its
// own commit). v82 cleared the obvious pair (H4 x multilang, both orders: green),
// so the red comes from a THIRD hadith file — but the directory run buries the
// [E] line far from the annotation window. The trick this round is a RELAY: the
// expensive replay writes its findings to a file and finishes EARLY; a second
// test at the end of the suite (the only position whose prints are inside the
// log tail) reads that file back and prints it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _relay = File('${Directory.systemTemp.path}/h4p83.txt');

Future<List<String>> _fails(List<String> args) async {
  final r = await Process.run('flutter', args,
      workingDirectory: Directory.current.path, environment: Platform.environment);
  final src = <String>[];
  for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
    src.addAll(l
        .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
        .split('\r')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty));
  }
  String cut(String s, int k) => s.length > k ? '${s.substring(0, k)}…' : s;
  final names = src
      .where((l) => l.contains('[E]'))
      .map((l) => cut(l, 168))
      .take(4)
      .toList();
  final sum = cut(src.isEmpty ? '-' : src.last, 60);
  return ['exit=${r.exitCode} sum=$sum', ...names];
}

void main() {
  test('probe A: replay the hadith directory', () async {
    final dir =
        await _fails(['test', '--reporter', 'compact', 'test/features/hadith']);
    _relay.writeAsStringSync('DIR ${dir.join("\n")}\n');
    print('::error::P83 A ${dir.first}');
    for (var i = 1; i < dir.length && i < 3; i++) {
      print('::error::P83 Ad$i ${dir[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('probe B: relay (dir) + suite replay when there is no relay yet', () async {
    if (_relay.existsSync()) {
      print('::error::P83 RELAY ${_relay.readAsStringSync().replaceAll("\n", " // ")}');
      return;
    }
    final all = await _fails(['test', '--reporter', 'compact']);
    for (var i = 0; i < all.length && i < 5; i++) {
      print('::error::P83 SU$i ${all[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 9)));
}
