// H2PROBE (transient): outer-suite replay — names both real reds.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2r: replay the WHOLE suite and exfil every [E] window', () async {
    String out = '';
    try {
      final files = <String>[];
      for (final e in Directory('test')
          .listSync(recursive: true)
          .whereType<File>()) {
        final p = e.path;
        if (p.endsWith('_test.dart') && !p.contains('h2_analyze_probe')) {
          files.add(p);
        }
      }
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        ...files,
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
    for (var i = 0; i < all.length; i++) {
      final c = all[i].trim();
      if (c.endsWith('[E]') || c.contains('passed') ||
          c.contains('failed') || c.startsWith('EXIT')) {
        keep.add(c);
        if (keep.length > 8) break;
      }
    }
    if (keep.isEmpty) {
      keep.add('NO [E] LINES len=${out.length}');
      keep.addAll(all.take(10));
    }
    if (keep.isEmpty) keep.add('SILENT-ALL-GREEN len=${all.length}');
    for (var n = 0; n < keep.length; n++) {
      final l = keep[n];
      final v = l.length > 200 ? '${l.substring(0, 200)}…' : l;
      print('::error::H2R n$n $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
