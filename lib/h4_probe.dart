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
  test('probe: gate verdict + explicit test-file findings + suite verdict', () async {
    Future<ProcessResult> res(List<String> args) => Process.run('flutter', args,
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    List<String> linesOf(ProcessResult r) {
      final out = <String>['exit=${r.exitCode}'];
      for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
        out.addAll(l
            .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
            .split('\r')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty));
      }
      return out;
    }

    String trim(String l, int k) => l.length > k ? l.substring(0, k) : l;
    final gate = linesOf(await res(['analyze', '--no-fatal-infos']));
    final mine = linesOf(await res([
      'analyze',
      '--no-fatal-infos',
      '--fatal-infos',
      'test/features/hadith/hadith_h4_search_test.dart'
    ]));
    final suite = linesOf(await res([
      'test',
      '--reporter',
      'compact',
      '--ignore-errors',
      'test/features/hadith/hadith_h4_search_test.dart'
    ]));
    final hard = mine
        .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
        .take(3)
        .map((l) => trim(l, 150))
        .join(' ;; ');
    final nHard = mine.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).length;
    var out = 'H4P36 GATE exit=${gate.first} "${trim(gate.length > 1 ? gate[1] : '-', 80)}" || '
        'MINE exit=${mine.first} n=$nHard [$hard] || SUITE exit=${suite.first} '
        '"${trim(suite.last, 160)}"';
    if (out.length > 970) out = '${out.substring(0, 964)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
