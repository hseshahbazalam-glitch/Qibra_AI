// test/features/quran/m6_meta_test.dart
// M6META (transient): one round of REAL eyes on the runner output.
// The annotation channel only sees ::error:: prints, and flutter
// analyze/test details die in stdout — so run the tools as
// subprocesses inside a test and smuggle their reports. Deleted
// with the fix that names the culprit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<String> _run(String exe, List<String> args) async {
  final p = await Process.start(exe, args);
  final out = p.stdout.transform(Utf8Decoder()).join();
  final err = p.stderr.transform(Utf8Decoder()).join();
  final joined = await Future.wait([out, err]);
  await p.exitCode;
  return '${joined[0]}\n${joined[1]}';
}

void main() {
  test('M6META: analyze report + per-file suite triage', () async {
    final an = await _run('flutter', ['analyze', '--no-fatal-infos']);
    final lines = const LineSplitter()
        .convert(an)
        .where((l) => l.contains(' error ') || l.contains(' warning '))
        .toList();
    print('::error::M6ANALYZE x${lines.length} :: '
        '${lines.take(10).join(' || ').substring(0,
            lines.take(10).join(' || ').length < 1600
                ? lines.take(10).join(' || ').length
                : 1600)}');
    for (final f in [
      'test/features/quran/mushaf_pass_m_test.dart',
      'test/features/quran/mushaf_pass_m4_test.dart',
      'test/features/quran/mushaf_pass_m5_test.dart',
      'test/features/quran/mushaf_pass_m6_probe_test.dart',
      'test/features/quran/mushaf_pass_d2_test.dart',
      'test/features/quran/quran_reading_pass_q2_test.dart',
    ]) {
      final r = await _run('flutter', ['test', f]);
      final fails = const LineSplitter()
          .convert(r)
          .where((l) =>
              l.contains('[E]') || l.contains('Some tests failed') || l.contains('All tests passed'))
          .toList();
      print('::error::M6TRIAGE ${f.split('/').last} :: '
          '${fails.join(' ;; ').length > 1500 ? fails.join(' ;; ').substring(0, 1500) : fails.join(' ;; ')}');
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
