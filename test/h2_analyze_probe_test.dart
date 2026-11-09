// H2PROBE (transient): name the last 626/1 red.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2n: scoped red exfil', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/features/hadith/hadith_pass_h2_test.dart',
        'test/features/hadith/hadith_redesign_test.dart',
        'test/features/hadith/hadith_topclass_test.dart',
        'test/core/i18n_phase_a_test.dart',
        'test/core/i18n_pass_a2_test.dart',
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
      if (keep.length > 36) break;
    }
    if (keep.isEmpty) keep.add('SCOPED GREEN (len=${out.length})');
    for (final l in keep) {
      final v = l.length > 225 ? '${l.substring(0, 225)}…' : l;
      print('::error::H2N $v');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
