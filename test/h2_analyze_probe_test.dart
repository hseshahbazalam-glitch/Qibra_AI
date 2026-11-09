// H2PROBE (transient). Nested single-test rerun: the expanded reporter
// line that carries 'Expected:' / 'Actual:' / the overflow message is
// invisible to the outer suite stdout channel, so re-run JUST the red
// test and smuggle its verdict through ::error:: annotations.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2b: nested rerun of the anatomy test for its expect diff',
      () async {
    final r = await Process.start('flutter', [
      'test',
      '--reporter',
      'expanded',
      'test/features/hadith/hadith_pass_h2_test.dart',
      '--plain-name',
      'D1 anatomy: badge',
    ]);
    final o = r.stdout.transform(Utf8Decoder()).join();
    final e = r.stderr.transform(Utf8Decoder()).join();
    final joined = await Future.wait([o, e]);
    await r.exitCode;
    final all = '${joined[0]}\n${joined[1]}'.split('\n');
    final keep = <String>[];
    for (var i = 0; i < all.length && keep.length < 14; i++) {
      final c = all[i].trim();
      if (c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          c.startsWith('A RenderFlex') ||
          c.startsWith('Test failed') ||
          c.contains('was thrown') ||
          c.startsWith('00:') && c.contains('[E]')) {
        keep.add(c.length > 220 ? '${c.substring(0, 220)}…' : c);
      }
    }
    if (keep.isEmpty) keep.add('NO HITS — see the raw tail instead');
    for (final l in keep) {
      print('::error::H2D $l');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
