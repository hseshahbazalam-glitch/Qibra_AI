// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v78, deleted with its
// own commit). v77 narrowed the last red to test/features/hadith (63 pass, 1
// fail) while the H4 file itself is 17/17 green, so the failure belongs to an
// OLDER hadith test and is scope-sensitive: this round replays that directory
// and lifts the failing test NAME plus its Expected/Actual/Which lines.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: name the red hadith test', () async {
    final r = await Process.run('flutter',
        ['test', '--reporter', 'compact', 'test/features/hadith'],
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
    String cut(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    final ei = src.indexWhere((l) => l.contains('[E]'));
    final names = src
        .where((l) =>
            l.contains('The test description was:') || l.contains('Failed to load'))
        .join(' | ');
    print('::error::P78 exit=${r.exitCode} n=${src.length} ei=$ei '
        'last=${cut(src.isEmpty ? "-" : src.last, 90)}');
    print('::error::P78 NAMES ${cut(names, 195)}');
    if (ei >= 0) {
      for (var j = -8; j < 2 && ei + j < src.length; j++) {
        if (ei + j < 0) continue;
        print('::error::P78 w$j ${cut(src[ei + j], 195)}');
      }
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
