// ignore_for_file: type=lint
// test/h4_probe_test.dart relocated to lib/ — THE CHANNEL BUG that made every
// H4 probe from v9 to v35 dead on arrival: a probe living under test/ can
// never run in a round where the test/ tree is excluded from the analyzer (the
// file is skipped, not analyzed), and in a round where it IS analyzed, its own
// fail() keeps the gate red. Here the probe is in scope (self-ignores its
// findings), the gate step stays the untouched project-wide command, and the
// payload rides a failed test through the annotations API. TRANSIENT — deleted
// with its own commit before the pass closes.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: explicit findings via ::error:: prints', () async {
    Future<ProcessResult> res(List<String> args) => Process.run('flutter', args,
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    List<String> linesOf(ProcessResult r) {
      final out = <String>['x${r.exitCode}'];
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
    final tst = linesOf(await res(['analyze', '--no-fatal-infos', '--fatal-infos', 'test']));
    final h4 = linesOf(await res(['analyze', '--no-fatal-infos', '--fatal-infos',
        'test/features/hadith/hadith_h4_search_test.dart']));
    final suite = linesOf(await res(['test', '--reporter', 'compact', '--ignore-errors',
        'test/features/hadith/hadith_h4_search_test.dart']));
    void emit(String tag, List<String> lines, int cap) {
      final hits =
          lines.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
      print('::error::${tag} exit=${lines.first} n=${hits.length} sum=${cut(lines.last, 110)}');
      for (var i = 0; i < hits.length && i < cap; i++) {
        print('::error::${tag} f$i ${cut(hits[i], 165)}');
      }
      if (hits.isEmpty) {
        for (var i = 0; i < lines.length && i < 2; i++) {
          print('::error::${tag} r$i ${cut(lines[i], 165)}');
        }
      }
    }

    emit('TST', tst, 2);
    emit('H4F', h4, 2);
    print('::error::SUI exit=${suite.first} last=${cut(suite.last, 150)}');
    final fails = suite.where((l) => l.startsWith('[E]')).take(2);
    for (final l in fails) {
      print('::error::SUI e ${cut(l, 160)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
