// H2PROBE (transient, one round): nested rerun of the hadith test dir;
// the outer suite stdout hides WHICH test is red — smuggle [E] names +
// their expect diffs through ::error:: annotations.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2b: nested hadith-dir rerun for [E] context', () async {
    final r = await Process.start('flutter', [
      'test',
      '--reporter',
      'expanded',
      'test/features/hadith/',
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
          c.contains('A RenderFlex') ||
          c.startsWith('Test failed') ||
          c.contains('was thrown') ||
          c.contains('_test.dart:') && c.startsWith('#') ||
          c.startsWith('00:') && c.contains('[E]')) {
        keep.add(c.length > 220 ? '${c.substring(0, 220)}…' : c);
      }
    }
    if (keep.isEmpty) keep.add('HADITH DIR GREEN — culprit is elsewhere');
    for (final l in keep) {
      print('::error::H2E $l');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
