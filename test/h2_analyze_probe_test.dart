// H2PROBE (transient): full-project analyze inside the suite — verbatim
// error lines for qh_pass_test.dart ride the annotation channel.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('h2a: outer analyze verbatim', () async {
    String out = '';
    int code = -1;
    try {
      final r = await Process.start('flutter', [
        'analyze',
        '--no-fatal-infos',
      ]);
      final o = r.stdout.transform(Utf8Decoder()).join();
      final e = r.stderr.transform(Utf8Decoder()).join();
      final j = await Future.wait([o, e]);
      code = await r.exitCode;
      out = 'EXIT=$code\n${j[0]}\n${j[1]}';
    } catch (err) {
      out = 'PROBE FAILED: $err';
    }
    final all = const LineSplitter().convert(out);
    final keep = <String>[];
    keep.add('H2A EXIT=$code LINES=${all.length}');
    for (final raw in all) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      if (c.startsWith('error') ||
          c.startsWith('warning') ||
          c.contains('qh_pass') ||
          c.contains('analyze found') ||
          c.contains('issue')) {
        keep.add(c);
      }
      if (keep.length > 60) break;
    }
    for (final l in keep.take(40)) {
      final v = l.length > 230 ? '${l.substring(0, 230)}…' : l;
      print('::error::H2A $v');
    }
  }, timeout: const Timeout(Duration(minutes: 19)));
}
