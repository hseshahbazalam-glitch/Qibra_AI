// H2PROBE (transient): scoped nested rerun, fully guarded finally.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2b: scoped rerun — hadith h2 + h1 files, exact reds', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/core/perf_pass_test.dart',
        'test/core/device_log_fixes_test.dart',
        'test/stage_c_font_test.dart',
        'test/core/stage_c_font_test.dart',
        'test/features/hadith/hadith_redesign_test.dart',
        'test/features/hadith/hadith_multilang_test.dart',
      ]);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final j = await Future.wait([o, e]);
      await r.exitCode;
      out = '${j[0]}\n${j[1]}';
    } catch (err) {
      out = 'PROBE PROCESS FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final lines = <String>[];
    for (final raw in all) {
      final c = raw.trim();
      if (c.contains('[E]') ||
          c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          c.startsWith('untranslated literal') ||
          c.startsWith('reason:') ||
          RegExp(r'^#\d').hasMatch(c)) {
        lines.add(c);
      }
      if (lines.length > 55) break;
    }
    if (lines.isEmpty) lines.add('EMPTY OUTPUT — ${out.length} chars');
    for (final l in lines) {
      final v = l.length > 225 ? '${l.substring(0, 225)}…' : l;
      print('::error::H2J $v');
    }
  }, timeout: const Timeout(Duration(minutes: 24)));
}
