// H2PROBE (transient): name the QH test-file analyzer reds.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2o: analyze the QH test file, exfil diagnostics', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'analyze', '--no-fatal-infos',
        'test/features/quran/qh_pass_test.dart',
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
      if (c.contains('error') || c.contains('warning')) keep.add(c);
      if (keep.length > 30) break;
    }
    if (keep.isEmpty) keep.add('TEST FILE ANALYZE-CLEAN (len=${out.length})');
    for (final l in keep) {
      final v = l.length > 235 ? '${l.substring(0, 235)}…' : l;
      print('::error::H2O $v');
    }
  }, timeout: const Timeout(Duration(minutes: 18)));
}
