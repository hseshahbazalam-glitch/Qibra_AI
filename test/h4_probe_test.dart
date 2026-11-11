// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v80, deleted with its
// own commit; v79 died because my header re-assembly ate the two imports — a
// dead-simple mistake, disclosed). v78 named the last red test:
// test/features/hadith/hadith_multilang_test.dart 'availability matrix ⇔ data on
// disk'. The compact reporter had moved past it at the [E] marker, so this round
// greps the assertion detail (Expected / Actual / Which / reason) directly.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: the assertion behind the multilang red', () async {
    final r = await Process.run('flutter', [
      'test',
      '--reporter',
      'compact',
      'test/features/hadith/hadith_multilang_test.dart'
    ], workingDirectory: Directory.current.path, environment: Platform.environment);
    final src = <String>[];
    for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
      src.addAll(l
          .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
          .split('\r')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty));
    }
    String cut(String s, int k) => s.length > k ? '${s.substring(0, k)}…' : s;
    final hits = <String>[];
    for (final s in src) {
      if (s.contains('Expected:') ||
          s.contains('Actual:') ||
          s.contains('Which:') ||
          s.contains('matrix says') ||
          s.contains('package:qibra_ai/')) {
        hits.add(cut(s, 150));
        if (hits.length == 7) break;
      }
    }
    print('::error::P80 exit=${r.exitCode} n=${src.length} k=${hits.length}');
    for (var i = 0; i < hits.length && i < 6; i++) {
      print('::error::P80 d$i ${hits[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
