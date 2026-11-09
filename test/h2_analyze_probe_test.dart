// H2PROBE (transient). Copies land in test/h2probe/ under a NON _test.dart
// suffix so no parallel dir-scanning suite can ever see them mid-run.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2b: scoped rerun + stack frames for every hadith red', () async {
    const targets = [
      'lib/features/hadith/presentation/hadith_book_screen.dart',
      'lib/core/l10n/app_strings.dart',
    ];
    Directory('test/h2probe').createSync(recursive: true);
    final cs = <String>[];
    for (final t in targets) {
      final i = t.lastIndexOf('/');
      final name = t.substring(i + 1).replaceAll('.dart', '');
      final c = 'test/h2probe/h2copy_$name.probe.dart';
      File(c).writeAsStringSync(File(t).readAsStringSync());
      cs.add(c);
    }
    String out = '';
    try {
      final r = await Process.start('dart', ['analyze', ...cs]);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final joined = await Future.wait([o, e]);
      await r.exitCode;
      final aout = const LineSplitter()
          .convert('${joined[0]}\n${joined[1]}')
          .where((l) => l.contains(' - '))
          .take(12)
          .join(' || ');
      out += 'ANALYZE: $aout\n';
    } finally {
      for (final c in cs) {
        try {
          File(c).deleteSync();
        } catch (_) {}
        Directory('test/h2probe').deleteSync(recursive: true);
      }
    }
    final r2 = await Process.start('flutter', [
      'test',
      '--reporter',
      'expanded',
      'test/features/hadith/hadith_pass_h2_test.dart',
      'test/features/hadith/hadith_pass_h1_test.dart',
      'test/core/perf_pass_test.dart',
      'test/core/device_log_fixes_test.dart',
      'test/stage_c_font_test.dart',
    ]);
    final o2 = r2.stdout.transform(Utf8Decoder()).join();
    final e2 = r2.stderr.transform(Utf8Decoder()).join();
    final j2 = await Future.wait([o2, e2]);
    await r2.exitCode;
    final all = const LineSplitter().convert('${j2[0]}\n${j2[1]}');
    final lines = <String>[];
    for (final raw in all) {
      final c = raw.trim();
      if (c.startsWith('00:') && c.contains('[E]') ||
          c.startsWith('Expected:') ||
          c.startsWith('Actual:') ||
          c.startsWith('Which:') ||
          RegExp(r'^#\d').hasMatch(c) && c.contains('probe_h2_test.dart:')) {
        lines.add(c);
      }
      if (lines.length > 60) break;
    }
    out += 'SUITE:\n${lines.join('\n')}';
    for (final l in out.split('\n')) {
      final v = l.trim();
      if (v.isEmpty) continue;
      print('::error::H2I ${v.length > 225 ? v.substring(0, 225) : v}');
    }
  }, timeout: const Timeout(Duration(minutes: 24)));
}
