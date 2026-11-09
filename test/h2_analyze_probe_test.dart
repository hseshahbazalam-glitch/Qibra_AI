import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// H2PROBE round 2 (transient): book-screen only, 40-line window.
void main() {
  test('h2a: dart analyze verdict for the book screen (via copy)',
      () async {
    const targets = [
      'lib/features/hadith/presentation/hadith_book_screen.dart',
      'test/features/hadith/hadith_pass_h2_test.dart',
      'lib/core/l10n/app_strings.dart',
    ];
    final cs = <String>[];
    for (final t in targets) {
      final i = t.lastIndexOf('/');
      final c = '${t.substring(0, i)}/h2copy_${t.substring(i + 1)}';
      File(c).writeAsStringSync(File(t).readAsStringSync());
      cs.add(c);
    }
    String out = '';
    try {
      final r = await Process.start('dart', ['analyze', ...cs]);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final joined = await Future.wait([o, e]);
      await r.exitCode;
      out = '${joined[0]}\n${joined[1]}';
    } finally {
      for (final c in cs) {
        try {
          File(c).deleteSync();
        } catch (_) {}
      }
    }
    final lines = const LineSplitter()
        .convert(out)
        .where((l) => (l.contains(' - ') && !l.contains(' info - ')) ||
            l.contains('issues found'))
        .take(40)
        .toList();
    for (final l in lines) {
      final v = l.replaceAll('h2copy_', '').trim();
      print('::error::H2G ${v.length > 225 ? v.substring(0, 225) : v}');
    }
    if (lines.isEmpty) {
      print('::error::H2G CLEAN — no error/warning lines');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
