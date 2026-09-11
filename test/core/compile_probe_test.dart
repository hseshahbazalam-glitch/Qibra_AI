// TEMP I18N diagnostic probe v6 (removed next cycle): re-runs the suite
// under the json reporter and mirrors each failing test's name plus a
// trimmed error block through ::error annotations. Recursion-guarded.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String flat(String s) => s.replaceAll('\n', ' | ').trim();

void main() {
  test('suite-name mirror probe', () async {
    if (Platform.environment['I18N_PROBE_NESTED'] == '1') {
      return; // inner run: stay silent
    }
    final pr = await Process.start(
        'flutter',
        <String>['test', '--reporter=json'],
        environment: <String, String>{'I18N_PROBE_NESTED': '1'},
        includeParentEnvironment: true);
    final bo = StringBuffer();
    final be = StringBuffer();
    final f1 = pr.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(bo.writeln);
    final f2 = pr.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(be.writeln);
    await pr.exitCode.timeout(const Duration(minutes: 11), onTimeout: () {
      pr.kill(ProcessSignal.sigkill);
      return -99;
    });
    await Future.wait<void>(<Future<void>>[f1, f2]);
    final names = <int, String>{};
    for (final raw in bo.toString().split('\n')) {
      if (!raw.startsWith('{')) continue;
      Object? j;
      try {
        j = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      final m = j! as Map<String, dynamic>;
      if (m['type'] == 'testStart') {
        final t = m['test']! as Map<String, dynamic>;
        names[t['id']! as int] =
            '${t['name']} :: ${t['url'] ?? 'app'}';
      }
      if (m['type'] == 'testDone' && m['result'] != 'success' && m['hidden'] != true) {
        print('::error::FAILED-TEST ${names[m['testID']] ?? m['testID']}');
      }
      if (m['type'] == 'error') {
        final e = (m['error'] ?? '').toString();
        print('::error::ERR ${names[m['testID']] ?? ''} ${flat(e).substring(0, e.length < 650 ? e.length : 650)}');
      }
    }
    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 13)));
}
