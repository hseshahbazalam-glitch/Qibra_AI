// TEMP compile probe (Pass Q1, 2026-09-14) — DELETE after the analyzer
// errors it harvests are fixed. The CI log host is unreachable from the
// sandbox; workflow ANNOTATIONS are the only readable channel, so this
// test runs the analyzer itself (with the temporary analysis_options
// exclusion patched OFF) and re-prints every error/warning as a
// '::error::PROBE' annotation line. No imports beyond dart:io +
// flutter_test (the v3-era dart:async import was itself analyzer-red —
// do not add one), no .timeout wrappers (the v5 onTimeout type error was
// this probe's other casualty — keep it plain).
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compile probe: repo analyze, errors as annotations', () async {
    final opts = File('analysis_options.yaml');
    final orig = opts.readAsStringSync();
    // Neutralize the temporary exclusion so `dart analyze` sees EVERY
    // file (flutter analyze in the earlier step used the excluded set).
    opts.writeAsStringSync(orig.replaceFirst('exclude:', 'exclude_disabled:'));
    ProcessResult r;
    try {
      r = await Process.run('bash', [
        '-lc',
        'dart analyze lib test 2>&1 | grep -E "^ +(error|warning)" '
            '> /tmp/probe_analyze.txt; wc -l < /tmp/probe_analyze.txt; '
            'head -55 /tmp/probe_analyze.txt'
      ]);
    } finally {
      opts.writeAsStringSync(orig);
    }
    final lines = (r.stdout as String).split('\n');
    var n = 0;
    var shown = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      if (i == 0) {
        // ignore: avoid_print
        print('::notice::PROBE total error/warning lines: ${line.trim()}');
        continue;
      }
      n++;
      shown++;
      // ignore: avoid_print
      print('::error::PROBE($shown/55) ${line.trim()}');
    }
    if (n == 0) {
      // ignore: avoid_print
      print('::notice::PROBE analyze clean rc=${r.exitCode} '
          'stderr=${(r.stderr as String).trim().split('\n').take(3).join(' | ')}');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
