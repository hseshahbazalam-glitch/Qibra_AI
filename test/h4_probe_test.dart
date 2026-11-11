// ignore_for_file: avoid_print, unused_local_variable, unused_element
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (round v49, deleted
// with its own commit). The channel that works, proven at v46/v47: a GREEN test
// in the suite step printing `::error::` lines; it needs the gate to be green,
// so exactly one suspect file is excluded from the analyzer this round.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: parse-oracle over the changed lib files', () async {
    Future<ProcessResult> run(String exe, List<String> args) =>
        Process.run(exe, args,
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
    const lib = [
      'lib/core/l10n/app_strings.dart',
      'lib/features/hadith/data/services/hadith_database_service.dart',
      'lib/features/hadith/providers/hadith_provider.dart',
      'lib/features/hadith/presentation/hadith_screen.dart',
    ];
    for (final p in lib) {
      final fmt = await run('dart', ['format', '--output=none', p]);
      final fl = linesOf(fmt);
      final bad =
          fl.where((l) => l.contains('Error') || l.contains('error')).toList();
      print('::error::P58 FMT ${p.split('/').last} exit=${fmt.exitCode} '
          '${bad.isEmpty ? cut(fl.join(" | "), 150) : cut(bad.join(" | "), 175)}');
      final an = await run('flutter', ['analyze', '--no-fatal-infos', p]);
      final al = linesOf(an);
      final ah = al
          .where((l) => RegExp(r' - (error|warning) - ').hasMatch(l))
          .toList();
      print('::error::P58 ANA ${p.split('/').last} exit=${an.exitCode} n=${ah.length} '
          '${ah.isEmpty ? cut(al.isEmpty ? "-" : al.last, 150) : cut(ah.first, 175)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
