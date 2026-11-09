import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// H2PROBE (transient, one round — deleted with the next commit).
void main() {
  test('h2a: dart analyze verdict for the two suspects', () async {
    final r = await Process.start('dart', [
      'analyze',
      '--suppress-exclude',
      '--fatal-warnings',
      'lib/features/hadith/presentation/hadith_book_screen.dart',
      'test/features/hadith/hadith_pass_h2_test.dart',
    ]);
    final out = r.stdout.transform(Utf8Decoder()).join();
    final err = r.stderr.transform(Utf8Decoder()).join();
    final joined = await Future.wait([out, err]);
    await r.exitCode;
    final lines = const LineSplitter()
        .convert('${joined[0]}\n${joined[1]}')
        .where((l) => l.contains('error') || l.contains('warning'))
        .take(14)
        .toList();
    for (final l in lines) {
      print('::error::H2A ${l.trim().length > 225 ? l.trim().substring(0, 225) : l.trim()}');
    }
    if (lines.isEmpty) {
      print('::error::H2A NO error/warning lines from the analyzer');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
