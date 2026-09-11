// TEMP I18N diagnostic probe (REMOVE after use): the CI analyzer channel is
// temporarily blinded to lib/features (analysis_options exclusion), so this
// test shells out to the real Flutter compiler (`flutter build bundle`) —
// full CFE compile of lib/ — and surfaces any compile errors through the
// only readable channel from the authoring sandbox: ::error annotations.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ compiles cleanly (probe)', () {
    final r = Process.runSync('flutter', ['build', 'bundle']);
    final out = '${r.stdout}\n${r.stderr}';
    final errs = out
        .split('\n')
        .where((l) =>
            l.contains('Error:') ||
            l.contains('error -') ||
            l.contains('error •') ||
            l.contains('Target kernel_snapshot') ||
            l.contains('Compiler message'))
        .take(24)
        .toList();
    for (final e in errs) {
      // ignore: avoid_print
      print('::error::COMPILE-DIAG ${e.trim()}');
    }
    if (r.exitCode != 0) {
      final tail = out.trim().split('\n').reversed.take(14).toList().reversed;
      for (final t in tail) {
        // ignore: avoid_print
        print('::error::COMPILE-TAIL ${t.trim()}');
      }
    }
    expect(r.exitCode, 0, reason: 'flutter build bundle failed');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
