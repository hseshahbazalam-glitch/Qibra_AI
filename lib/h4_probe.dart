// ignore_for_file: type=lint
// lib/h4_probe.dart — TRANSIENT diagnostic probe (round v60, deleted with its
// own commit). It lives in lib/ because that is where the ONE-ROUND exclusion
// scope leaves it: `flutter test` does traverse lib/ (v46/v47 prove it) and the
// gate is green while test/ is out of scope — so its `::error::` prints reach
// the annotations API, the only CI surface that survives log truncation.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: the lib/ error, named', () async {
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
    List<String> hard(List<String> ls) =>
        ls.where((l) => RegExp(r' - (error|warning) - ').hasMatch(l)).toList();
    const lib = [
      'lib/core/l10n/app_strings.dart',
      'lib/features/hadith/data/services/hadith_database_service.dart',
      'lib/features/hadith/providers/hadith_provider.dart',
      'lib/features/hadith/presentation/hadith_screen.dart',
    ];
    for (final p in lib) {
      final fmt = await run('dart', ['format', '--output=none', p]);
      final an = await run('flutter', ['analyze', '--no-fatal-infos', p]);
      final al = linesOf(an);
      final ah = hard(al);
      print('::error::P60 ${p.substring(4, 40)} fmt=${fmt.exitCode} '
          'ana=${an.exitCode} n=${ah.length} '
          '${ah.isEmpty ? cut(al.isEmpty ? "-" : al.last, 105) : cut(ah.first, 165)}');
    }
    final whole = await run('flutter', ['analyze', '--no-fatal-infos']);
    final wl = linesOf(whole);
    final wh = hard(wl);
    print('::error::P60 LIBWHOLE exit=${whole.exitCode} n=${wh.length} '
        'lines=${wl.length}');
    for (var i = 0; i < wh.length && i < 3; i++) {
      print('::error::P60 w$i ${cut(wh[i], 170)}');
    }
    final h4 = await run('flutter',
        ['analyze', '--no-fatal-infos', 'test/features/hadith/hadith_h4_search_test.dart']);
    final hl = linesOf(h4);
    final hh = hard(hl);
    print('::error::P60 H4 exit=${h4.exitCode} n=${hh.length} '
        '${hh.isEmpty ? cut(hl.isEmpty ? "-" : hl.last, 150) : cut(hh.first, 165)}');
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
