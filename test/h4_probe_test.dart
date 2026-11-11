// test/h4_probe_test.dart — TRANSIENT diagnostic probe (H4 round only, deleted
// with its own commit before the pass closes). Channel: `::error::` prints from
// a GREEN test in the suite step — the only CI surface that survives log
// truncation, and it needs the test/ tree (flutter test runs nothing else).
// Runs the analyzer over the whole package (the truth the red gate hides) and
// echoes its error/warning lines verbatim, plus the H4 suite verdict.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: raw analyze stderr for the parse error', () async {
    Future<ProcessResult> res(List<String> args) => Process.run('flutter', args,
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    List<String> linesOf(ProcessResult r) {
      final out = <String>[];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        out.addAll(l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty));
      }
      return out;
    }

    String cut(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    // (1) analyzer over test/ — its raw output names the file for a parse error
    final a = await res(['analyze', '--no-fatal-infos', '--fatal-infos', 'test']);
    final al = linesOf(a);
    final ah = al
        .where((l) =>
            !l.contains(' - info - ') &&
            (l.contains(' - error - ') ||
                l.contains(' - warning - ') ||
                l.contains('Error') ||
                l.contains('error:') ||
                l.contains('expected') ||
                l.contains('issues')))
        .toList();
    print('::error::P45 A exit=${a.exitCode} n=${al.length} k=${ah.length}');
    for (var i = 0; i < ah.length && i < 4; i++) {
      print('::error::P45 a$i ${cut(ah[i], 178)}');
    }
    // (2) dart format = a PARSE-ONLY oracle over every test file (needs no
    // package resolution); it prints the exact file + line of each parse error.
    final b = await Process.run('dart', ['format', '--output=none', 'test'],
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    final bl = linesOf(b);
    final bh = bl.where((l) => l.contains('Error') || l.contains('error')).toList();
    print('::error::P45 F exit=${b.exitCode} n=${bl.length} k=${bh.length}');
    for (var i = 0; i < bh.length && i < 4; i++) {
      print('::error::P45 f$i ${cut(bh[i], 178)}');
    }
    // (3) same oracle over lib/ (cheap, settles the lib question for good)
    final c = await Process.run('dart', ['format', '--output=none', 'lib'],
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    final cl = linesOf(c);
    final ch = cl.where((l) => l.contains('Error') || l.contains('error')).toList();
    print('::error::P45 L exit=${c.exitCode} n=${cl.length} k=${ch.length} '
        '${ch.isEmpty ? cut(cl.isEmpty ? '-' : cl.last, 120) : cut(ch.first, 120)}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
