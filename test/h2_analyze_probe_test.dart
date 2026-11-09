// H2PROBE (final round): full-tree nested rerun, [E] names only.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2k: which file owns the last red', () async {
    String out = '';
    try {
      final r = await Process.start('flutter',
          ['test', '--reporter', 'expanded', 'test/']);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final j = await Future.wait([o, e]);
      await r.exitCode;
      out = '${j[0]}\n${j[1]}';
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final keep = <String>[];
    for (var i = 0; i < all.length && keep.length < 12; i++) {
      final c = all[i].trim();
      if (c.contains('[E]') ||
          c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:')) {
        keep.add(c);
      }
    }
    if (keep.isEmpty) keep.add('FULL TREE GREEN — outer red was contention');
    for (final l in keep) {
      final v = l.length > 225 ? '${l.substring(0, 225)}…' : l;
      print('::error::H2K $v');
    }
  }, timeout: const Timeout(Duration(minutes: 23)));
}
