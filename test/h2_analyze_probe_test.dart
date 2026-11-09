// H2PROBE (transient, one round). The CI suite log hides the failing
// test NAMES behind the step output; the annotation channel only sees
// ::error:: lines. This probe re-runs the suspect file in a nested
// flutter test (single file — minutes, not the full-suite timeout)
// and smuggles the [E] lines + their Expected/Actual context back as
// annotations. Deleted with the fix.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2b: nested rerun of the suspect file for [E] context', () async {
    final r = await Process.start('flutter',
        ['test', '--reporter', 'compact', 'test/features/hadith/hadith_pass_h2_test.dart']);
    final o = r.stdout.transform(Utf8Decoder()).join();
    final e = r.stderr.transform(Utf8Decoder()).join();
    final joined = await Future.wait([o, e]);
    await r.exitCode;
    final all = '${joined[0]}\n${joined[1]}'.split('\n');
    final keep = <String>[];
    for (var i = 0; i < all.length && keep.length < 20; i++) {
      final l = all[i];
      if (l.contains('[E]')) {
        keep.add(l.trim());
        // RAW following lines — the assertion message lives between the
        // banner lines; no filter this time.
        for (var j = i + 1; j < all.length && keep.length < 20 && j < i + 14; j++) {
          final c = all[j].trim();
          if (c.isEmpty) continue;
          keep.add(c.length > 220 ? '${c.substring(0, 220)}…' : c);
        }
      }
    }
    if (keep.isEmpty) keep.add('NO [E] LINES — suspect file is GREEN');
    for (final l in keep) {
      print('::error::H2B $l');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
