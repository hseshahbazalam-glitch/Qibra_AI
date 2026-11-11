// ignore_for_file: type=lint
// test/h4_probe_test.dart — TRANSIENT diagnostic probe (v79, deleted with its
// own commit). v78 named the last red test (test/features/hadith/hadith_multilang_test.dart
// — 'availability matrix ⇔ data on disk'), but the compact reporter had already
// moved on to the NEXT test at the [E] marker, so the window showed progress
// lines instead of the assertion. This round greps the failure detail directly.
void main() {
  test('probe: the assertion behind the multilang red', () async {
    final r = await Process.run('flutter',
        ['test', '--reporter', 'compact', 'test/features/hadith/hadith_multilang_test.dart'],
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
    final hits = <String>[];
    for (var i = 0; i < src.length && hits.length < 7; i++) {
      final l = src[i];
      if (l.contains('Expected:') ||
          l.contains('Actual:') ||
          l.contains('Which:') ||
          l.contains('reason:') ||
          l.contains('matrix says') ||
          l.contains('package:qibra_ai/')) {
        hits.add(cut(l, 150));
      }
    }
    print('::error::P79 exit=${r.exitCode} n=${src.length} k=${hits.length}');
    for (var i = 0; i < hits.length && i < 6; i++) {
      print('::error::P79 d$i ${hits[i]}');
    }
    expect(1, 1);
  }, timeout: const Timeout(Duration(minutes: 11)));
}
