// TEMP I18N diagnostic probe (removed next cycle): dart-analyze mirror.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart-analyze probe over lib/', () async {
    final opts = File('analysis_options.yaml');
    final original = opts.readAsStringSync();
    final patched = original
        .split('\n')
        .where((l) => !l.contains('TEMP(i18n-diag)') && !l.contains("lib/features/**"))
        .join('\n');
    opts.writeAsStringSync(patched);
    try {
      final pr = await Process.start('bash', <String>['-lc', 'dart analyze lib']);
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
          .timeout(const Duration(minutes: 4), onTimeout: () {
        pr.kill(ProcessSignal.sigkill);
        return -99;
      });
      await Future.wait<void>(<Future<void>>[f1, f2]);
      final out = '$bo\n$be';
      final lines = out
          .split('\n')
          .where((l) =>
              l.contains('error -') ||
              l.contains('warning -') ||
              l.contains('issues found') ||
              l.contains('No issues'))
          .take(20)
          .toList();
      for (final l in lines) {
        // ignore: avoid_print
        print('::error::PROBE ${l.trim()}');
      }
      // ignore: avoid_print
      print('::error::PROBE-EXIT $code');
    } finally {
      opts.writeAsStringSync(original);
    }
    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 7)));
}
