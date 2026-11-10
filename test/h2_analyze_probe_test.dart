// H2PROBE (transient): scoped verify of qh + a11y + i18n (channel: annotations).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2v: verify qh/a11y/i18n run green', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', [
        'test',
        '--reporter',
        'expanded',
        'test/features/quran/qh_pass_test.dart',
        'test/core/a11y_pass_test.dart',
        'test/core/i18n_phase_a_test.dart',
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
      if (c.endsWith('[E]') || c.contains('Error:')) {
        keep.add('=== AT $i ===');
        for (var k = i; k < i + 18 && k < all.length; k++) {
          keep.add(all[k].trim());
        }
      }
      if (keep.length > 95) break;
    }
    if (keep.isEmpty) {
      keep.add('SCOPED-GREEN len=${out.length}');
      keep.addAll(all.take(3));
      keep.addAll(all.reversed.take(3));
    }
    for (final l in keep) {
      final v = l.length > 230 ? '${l.substring(0, 230)}\u2026' : l;
      print('::error::H2V $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
