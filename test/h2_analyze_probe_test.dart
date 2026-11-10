// H2PROBE (transient): name the two real reds — proven H2 exfil shape.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2r: scoped red exfil (quran+tasbih dirs)', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/features/quran/',
        'test/features/tasbih/',
      ]);
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
    for (final raw in all) {
      final c = raw.trim();
      if (c.contains('[E]') ||
          c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          c.startsWith('Reason:') ||
          c.startsWith('reason:')) {
        keep.add(c);
      }
      if (keep.length > 30) break;
    }
    if (keep.isEmpty) {
      keep.add('RAW-DUMP len=${out.length}');
      keep.addAll(all.take(12));
    }
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2R $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
