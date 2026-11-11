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
  test('probe: bisect round 2', () async {
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

    String cut(String l, int k) => l.length > k ? l.substring(0, k) : l;
    String pack(List<String> lines, int cap) {
      final hits = lines.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
      final infos = lines.where((l) => l.contains(' - info - ')).length;
      return 'exit=${lines.first} n=${hits.length} i=$infos ' +
          hits.take(cap).map((l) => cut(l, 150)).join(' ;; ');
    }

    final three = linesOf(await res([
      'analyze',
      '--no-fatal-infos',
      '--fatal-infos',
      'lib/core/l10n/app_strings.dart',
      'lib/features/hadith/data/services/hadith_database_service.dart',
      'lib/features/hadith/providers/hadith_provider.dart',
    ]));
    final tst = linesOf(await res(['analyze', '--no-fatal-infos', '--fatal-infos', 'test']));
    var out = 'H4P41 THREE ${pack(three, 2)} || TEST ${pack(tst, 3)}';
    if (out.length > 980) out = '${out.substring(0, 974)}...TRUNC';
    fail(out);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
