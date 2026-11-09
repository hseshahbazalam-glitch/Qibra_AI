// H2PROBE (transient): name the last D4 red.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2l: scoped D4-red exfil', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/features/hadith/hadith_pass_h2_test.dart',
        'test/features/hadith/hadith_topclass_test.dart',
        'test/features/hadith/hadith_redesign_test.dart',
        'test/features/hadith/content_pass_test.dart',
        'test/features/hadith/hadith_multilang_test.dart',
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
          c.startsWith('reason:') ||
          RegExp(r'^#\d').hasMatch(c)) {
        keep.add(c);
      }
      if (keep.length > 40) break;
    }
    if (keep.isEmpty) keep.add('SCOPED GREEN (${out.length} chars)');
    for (final l in keep) {
      final v = l.length > 225 ? '${l.substring(0, 225)}…' : l;
      print('::error::H2L $v');
    }
  }, timeout: const Timeout(Duration(minutes: 22)));
}
