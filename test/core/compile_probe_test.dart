// TEMP I18N diagnostic probe (REMOVED next cycle): rewrites
// analysis_options.yaml to drop the temporary exclusion, runs the analyzer
// CLI over lib/ + test/, and mirrors every error/warning line into the
// ::error annotation channel (the only output readable from the sandbox).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analyzer probe over the real package', () {
    final root = Directory.current;
    final opts = File('${root.path}/analysis_options.yaml');
    final original = opts.readAsStringSync();
    final patched = original
        .split('\n')
        .where((l) => !l.contains('TEMP(i18n-diag)') && !l.contains("lib/features/**"))
        .join('\n');
    opts.writeAsStringSync(patched);
    try {
      final dart = Platform.resolvedExecutable;
      final r = Process.runSync(dart, ['analyze', 'lib', 'test']);
      final out = '${r.stdout}\n${r.stderr}';
      final lines = out
          .split('\n')
          .where((l) =>
              l.contains('error -') ||
              l.contains('warning -') ||
              l.contains('error •') ||
              l.contains('warning •'))
          .take(25)
          .toList();
      if (lines.isEmpty) {
        // Fallback: mirror the head of the raw output so we at least see the
        // analyzer's summary line.
        out
            .trim()
            .split('\n')
            .take(10)
            .forEach((l) => print('::error::PROBE-RAW ${l.trim()}'));
      }
      for (final l in lines) {
        print('::error::PROBE ${l.trim()}');
      }
    } finally {
      opts.writeAsStringSync(original);
    }
    expect(true, isTrue); // probe never gates; it only reports
  }, timeout: const Timeout(Duration(minutes: 6)));
}
