// H2PROBE (transient): real analyzer output for the post-R red.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2m: scoped analyzer exfil', () async {
    String out = '';
    try {
      final r = await Process.start('flutter', ['analyze', '--no-fatal-infos',
          'lib/features/hadith', 'test/features/hadith', 'test/core/a11y_pass_test.dart', 'lib/core/l10n']);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final j = await Future.wait([o, e]);
      await r.exitCode;
      out = '${j[0]}\n${j[1]}';
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final lines = const LineSplitter().convert(out);
    final keep = <String>[];
    for (final raw in lines) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      if (c.contains('error') || c.contains('warning') ||
          RegExp(r'issues found|No issues').hasMatch(c)) {
        keep.add(c);
      }
      if (keep.length > 38) break;
    }
    if (keep.isEmpty) keep.add('SCOPE CLEAN (len=${out.length})');
    for (final l in keep) {
      final v = l.length > 225 ? '${l.substring(0, 225)}…' : l;
      print('::error::H2M $v');
    }
  }, timeout: const Timeout(Duration(minutes: 22)));
}
