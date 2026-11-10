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
      if (c.endsWith('[E]')) {
        keep.add('=== AT $i ===');
        for (var k = i; k < i + 18 && k < all.length; k++) {
          keep.add(all[k].trim());
        }
        if (keep.length > 95) break;
      }
    }
    if (keep.isEmpty) {
      keep.add('NO [E] LINES len=${out.length}');
      keep.addAll(all.take(10));
    }
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2R $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
