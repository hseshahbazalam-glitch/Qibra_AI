// test/features/quran/m6_meta_test.dart
// M6META (transient): one round of REAL eyes on the runner output.
// The annotation channel only sees ::error:: prints, and flutter
// analyze/test details die in stdout — so run the tools as
// subprocesses inside a test and smuggle their reports. Deleted
// with the fix that names the culprit.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<String> _run(String exe, List<String> args) async {
  final r = await Process.run(exe, args);
  return '${r.stdout}\n${r.stderr}';
}

void main() {
  test('M6META: analyze report + per-file suite triage', () async {
    final an = await _run(
        'bash', ['-lc', 'flutter analyze --no-fatal-infos 2>&1 | tail -c 2000']);
    print('::error::M6ANALYZE :: '
        '${an.length > 1500 ? an.substring(an.length - 1500) : an}');
    for (final f in [
      'test/features/quran/mushaf_pass_m_test.dart',
      'test/features/quran/mushaf_pass_m4_test.dart',
      'test/features/quran/mushaf_pass_m5_test.dart',
      'test/features/quran/mushaf_pass_m6_probe_test.dart',
      'test/features/quran/mushaf_pass_d2_test.dart',
      'test/features/quran/quran_reading_pass_q2_test.dart',
    ]) {
      final r = await _run(
          'bash', ['-lc', 'flutter test $f --reporter expanded 2>&1 | tail -c 2500']);
      print('::error::M6RAW ${f.split('/').last} :: '
          '${r.length > 1500 ? r.substring(r.length - 1500) : r}');
  }, timeout: const Timeout(Duration(minutes: 25)));
}
