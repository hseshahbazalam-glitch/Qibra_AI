// test/h4_probe_test.dart — TRANSIENT replay probe (H4 round only).
// Channel: green test + `::error::`-prefixed prints (the only bytes that
// survive: runner annotations, ~10 per run). v27 additionally runs the
// test suite with --ignore-errors so a broken test file cannot hide the
// rest of the findings. DELETE before the pass closes (retirement commit).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _e(String s) => '::error::$s';

void main() {
  test('probe: analyzer findings + suite verdict', () async {
    final a = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final all = '${a.stdout}${a.stderr}'
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final bad =
        all.where((l) => l.contains(' - error') || l.contains(' - warning')).toList();
    print(_e('H4P v27 analyze exit=${a.exitCode} bad=${bad.length} lines=${all.length}'));
    for (var i = 0; i < bad.length && i < 5; i++) {
      final l = bad[i];
      print(_e('H4P f$i ${l.length > 150 ? l.substring(0, 150) : l}'));
    }
    print(_e('H4P last ${all.isEmpty ? '-' : all.last.substring(0, all.last.length > 150 ? 150 : all.last.length)}'));
    final t = await Process.run(
      'flutter',
      ['test', '--reporter', 'compact', '--ignore-errors', 'test/features/hadith/hadith_h4_search_test.dart'],
      workingDirectory: Directory.current.path,
      environment: Platform.environment,
    );
    final tl = '${t.stdout}${t.stderr}'
        .split('\n')
        .map((l) => l.replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    print(_e('H4P suite exit=${t.exitCode} lines=${tl.length}'));
    for (var i = 0; i < tl.length && i < 3; i++) {
      final l = tl[i];
      print(_e('H4P s$i ${l.length > 150 ? l.substring(0, 150) : l}'));
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
