import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// H2PROBE round 2 (transient): book-screen only, 40-line window.
void main() {
  test('h2a: dart analyze verdict for the book screen (via copy)',
      () async {
    const targets = [
      'test/features/hadith/',
    ];
    String out = '';
    final r = await Process.start('flutter', [
      'test',
      '--reporter',
      'expanded',
      'test/',
    ]);
    final o = r.stdout.transform(Utf8Decoder()).join();
    final e = r.stderr.transform(Utf8Decoder()).join();
    final joined = await Future.wait([o, e]);
    await r.exitCode;
    out = '${joined[0]}\n${joined[1]}';
    final all = const LineSplitter().convert(out);
    final lines = <String>[];
    for (var i = 0; i < all.length && lines.length < 40; i++) {
      final c = all[i].trim();
      if (c.startsWith('00:') && c.contains('[E]')) lines.add(c);
    }
    for (var i = 0; i < all.length; i++) {
      final c = all[i].trim();
      if (c.startsWith('Expected:') || c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          c.startsWith('#1 ') && c.contains('test') ||
          c.contains('hadith_pass_h2_test.dart:') && c.contains(':')) {
        lines.add(c);
      }
      if (lines.length > 70) break;
    }
    for (final l in lines) {
      final v = l.replaceAll('h2copy_', '').trim();
      print('::error::H2H ${v.length > 225 ? v.substring(0, 225) : v}');
    }
    if (false) {
      print('::error::H2H none');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
