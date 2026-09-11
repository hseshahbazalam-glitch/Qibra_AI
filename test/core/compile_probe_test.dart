// TEMP I18N diagnostic probe (removed next cycle): runs the full suite with
// the json reporter and mirrors the three failing tests' identities plus
// trimmed failure blocks into the ::error annotation channel.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String flat(String s) => s.replaceAll('\n', ' | ').trim();

void main() {
  test('suite-failure probe', () async {
    final pr = await Process.start('flutter', ['test', '--reporter=json']);
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
    final code = await pr.exitCode
        .timeout(const Duration(minutes: 12), onTimeout: () {
      pr.kill(ProcessSignal.sigkill);
      return -99;
    });
    await Future.wait<void>(<Future<void>>[f1, f2]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => <Future<void>>[]);
    final names = <String, String>{};
    for (final raw in bo.toString().split('\n')) {
      if (!raw.startsWith('{')) continue;
      Object? j;
      try {
        j = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      final m = j as Map<String, dynamic>;
      if (m['type'] == 'testStart') {
        final t = m['test'] as Map<String, dynamic>;
        names['${t['id']}'] = '${t['name']} :: ${t['url'] ?? ''}';
      }
      if (m['type'] == 'testDone' && m['result'] != 'success') {
        print('::error::FAILED-TEST ${names['${m['testID']}'] ?? m['testID']}');
      }
      if (m['type'] == 'error') {
        print('::error::ERR ${names['${m['testID']}'] ?? ''} '
            '${flat((m['error'] ?? '').toString()).substring(0, (m['error'] ?? '').toString().length < 600 ? (m['error'] ?? '').toString().length : 600)}');
      }
    }
    if (names.isEmpty) {
      be.toString().split('\n').take(10).forEach((l) {
        print('::error::RAW ${flat(l)}');
      });
    }
    expect(code, 0); // keep the step red so it is noticed, content is the point
  }, timeout: const Timeout(Duration(minutes: 15)));
}
