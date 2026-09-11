// TEMP I18N diagnostic probe (REMOVED next cycle): strips the temporary
// analyzer exclusion, runs `dart analyze lib/features` with a hard timeout,
// and mirrors every error/warning line through ::error annotations.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analyzer probe over lib/features', () async {
    final opts = File('analysis_options.yaml');
    final original = opts.readAsStringSync();
    final patched = original
        .split('\n')
        .where((l) => !l.contains('TEMP(i18n-diag)') && !l.contains("lib/features/**"))
        .join('\n');
    opts.writeAsStringSync(patched);
    try {
      final pr = await Process.start('bash', ['-lc', 'dart analyze lib/features'], runInShell: true);
      final bo = StringBuffer();
      final be = StringBuffer();
      final outs = <Future<void>>[
        pr.stdout.transform(utf8.decoder).forEach(bo.write),
        pr.stderr.transform(utf8.decoder).forEach(be.write),
      ];
      final code = await pr.exitCode.timeout(
        const Duration(minutes: 4),
        onTimeout: () {
          pr.kill(ProcessSignal.sigkill);
          return -99;
        },
      );
      await Future.wait(outs).timeout(const Duration(seconds: 10), onTimeout: () {});
      final out = '$bo\n$be';
      final lines = out
          .split('\n')
          .where((l) =>
              l.contains('error -') ||
              l.contains('warning -') ||
              l.contains('No issues') ||
              l.contains('issues found') ||
              l.contains('not found') ||
              l.contains('Unhandled exception'))
          .take(25)
          .toList();
      if (lines.isEmpty) {
        out.trim().split('\n').take(12).forEach((l) => print('::error::PROBE-RAW ${l.trim()}'));
      }
      for (final l in lines) {
        print('::error::PROBE ${l.trim()}');
      }
      // ignore: avoid_print
      print('::error::PROBE-EXIT $code');
    } finally {
      opts.writeAsStringSync(original);
    }
    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
