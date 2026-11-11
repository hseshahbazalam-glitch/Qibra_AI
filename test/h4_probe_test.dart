// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v77, deleted with its
// own commit). v76 printed nothing reachable because a FULL-suite replay writes
// ~5000 lines after its own prints and the annotation window is the log TAIL —
// so replays here are SMALL and per-directory, one line of verdict each: the
// first directory that answers is the one that holds the last red test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _dirs = [
  'test/core',
  'test/features/hadith',
  'test/features/ai',
  'test/features/settings',
];

void main() {
  test('probe: which directory holds the red test', () async {
    final out = <String>[];
    for (final d in _dirs) {
      if (!Directory(d).existsSync()) {
        out.add('$d:ABSENT');
        continue;
      }
      final r = await Process.run(
          'flutter', ['test', '--reporter', 'compact', d],
          workingDirectory: Directory.current.path,
          environment: Platform.environment);
      final src = '${r.stdout}\n${r.stderr}'
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final last = src.isEmpty ? '-' : src.last;
      out.add('$d:${r.exitCode}[${last.length > 46 ? last.substring(0, 46) : last}]');
    }
    print('::error::P77 ${out.join(" ")}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
