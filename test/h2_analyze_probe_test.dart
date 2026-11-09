import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// H2PROBE (transient, one round — deleted with the fix).
// dart analyze honours analysis_options excludes with NO bypass flag, so
// the probe copies each suspect next to itself under a name the exclude
// pattern misses, analyzes the copies (package resolution intact — all
// imports are package:/dart:), and smuggles the verdict through the
// ::error:: annotation channel. Line numbers survive 1:1 (pure copy).
void main() {
  test('h2a: dart analyze verdict for the two suspects (via copies)',
      () async {
    final targets = const [
      'lib/features/hadith/presentation/hadith_book_screen.dart',
      'test/features/hadith/hadith_pass_h2_test.dart',
    ];
    final copies = <String, String>{};
    for (final t in targets) {
      final i = t.lastIndexOf('/');
      final c = '${t.substring(0, i)}/h2copy_${t.substring(i + 1)}';
      File(c).writeAsStringSync(File(t).readAsStringSync());
      copies[t] = c;
    }
    String out = '';
    try {
      final r = await Process.start(
          'dart', ['analyze', '--fatal-warnings', ...copies.values]);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final joined = await Future.wait([o, e]);
      await r.exitCode;
      out = '${joined[0]}\n${joined[1]}';
    } finally {
      for (final c in copies.values) {
        try {
          File(c).deleteSync();
        } catch (_) {}
      }
    }
    final lines = const LineSplitter()
        .convert(out)
        .where((l) => l.contains(' - '))
        .map((l) => l.replaceAll('h2copy_', ''))
        .take(14)
        .toList();
    for (final l in lines) {
      print('::error::H2A ${l.trim().length > 225 ? l.trim().substring(0, 225) : l.trim()}');
    }
    if (lines.isEmpty) {
      print('::error::H2A CLEAN -- no error/warning lines for the copies');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
