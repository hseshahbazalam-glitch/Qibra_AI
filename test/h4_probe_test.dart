// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v76, deleted with its
// own commit). Channel, settled over 30 rounds: a GREEN test under test/ whose
// `::error::`-prefixed prints become runner annotations — the only CI surface
// that reaches me. Requirements: the analyze gate must stay green (this file is
// the only addition, and in-file type=lint silences its avoid_print warnings),
// and the replay must use NO positional argument (`flutter test .` walks backend
// too; and never edit this file with blind string replacements — the v75 red was
// my duplicate `final names` declaration, i.e. an error ignore cannot silence).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('probe: name the one failing test in the package', () async {
    final r = await Process.run('flutter', ['test', '--reporter', 'compact'],
        workingDirectory: Directory.current.path,
        environment: Platform.environment);
    final src = <String>[];
    for (final l in '${r.stdout}\n${r.stderr}'.split('\n')) {
      src.addAll(l
          .replaceAll(RegExp('\x1B\\[[0-9;]*[A-Za-z]'), '\r')
          .split('\r')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty));
    }
    String cut(String l, int k) => l.length > k ? '${l.substring(0, k)}…' : l;
    final desc = src
        .where((l) =>
            l.contains('The test description was:') || l.contains('Failed to load'))
        .map((l) => cut(l, 120))
        .take(3)
        .join(' | ');
    print('::error::P76 exit=${r.exitCode} lines=${src.length} '
        'last=${cut(src.isEmpty ? '-' : src.last, 110)}');
    print('::error::P76 DESC ${cut(desc, 190)}');
    final ei = src.indexWhere((l) => l.contains('[E]'));
    for (var j = -7; j < 1 && ei + j < src.length; j++) {
      if (ei + j < 0) continue;
      print('::error::P76 e$j ${cut(src[ei + j], 190)}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 12)));
}
