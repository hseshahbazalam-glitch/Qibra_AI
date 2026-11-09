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
    for (final f in [
      'test/features/quran/mushaf_pass_m_test.dart',
      'test/features/quran/mushaf_pass_m5_test.dart',
    ]) {
      final r = await _run('bash', [
        '-lc',
        'flutter test $f 2>&1 | grep -E '
            r'"\[E\]|Some tests failed|All tests passed" | head -10'
      ]);
      print('::error::M6RAW ${f.split('/').last} :: '
          '${r.length > 1400 ? r.substring(r.length - 1400) : r}');
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
