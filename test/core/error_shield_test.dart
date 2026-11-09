// Error Shield pass — LocalErrorLog logic (filesystem-free), redaction
// proof, file caps, shield wiring source pins, and dead-tile removal.
// The phase11_observability pins (consent default-off, payload-free crash
// hook) are re-asserted unchanged by their own suite; this file adds the
// shield's contract on top.
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/observability/error_log.dart';

import 'dart:io';

String repoRoot() => Directory.current.path;
String read(String rel) =>
    File('${repoRoot()}/${rel}').readAsStringSync();


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('core_error_shield_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('core_error_shield_test :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {

  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
    print('::error::M6BADEND core_error_shield_test ${_m6bad.length}');
  });

  group('LocalErrorLog ring', () {
    test('cap 100: recording 105 evicts the oldest five', () async {
      final captured = <String>[];
      final log = LocalErrorLog.forTesting((c) => captured.add(c));
      for (var i = 0; i < 105; i++) {
        log.record(StateError('e$i'), null, context: 't');
      }
      final lines = log.lines();
      expect(lines.length, 100);
      expect(lines.first.contains('e5'), isTrue);
      expect(lines.last.contains('e104'), isTrue);
      // exactly e0..e4 evicted, e5 is the new head
      expect(
        lines.where((l) => RegExp(r'\| Bad state: e[0-4] \|').hasMatch(l)).isEmpty,
        isTrue,
      );
      expect(lines.any((l) => RegExp(r'\| Bad state: e5 \|').hasMatch(l)), isTrue);
    });

    test('entry is ONE line with 4 pipe fields and an ISO timestamp', () {
      final log = LocalErrorLog.forTesting((_) {});
      log.record(
        StateError('boom\nmultiline|attacker'),
        StackTrace.fromString('frame0\nframe1\nframe2\nframe3'),
        context: 'unit',
      );
      final line = log.lines().single;
      expect(line.contains('\n'), isFalse);
      expect(line.split('|').length, 4);
      expect(line, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}')));
      expect(line, contains('unit'));
      // stack capped to the FIRST THREE frames
      expect(line, contains('frame0'));
      expect(line, contains('frame2'));
      expect(line.contains('frame3'), isFalse);
    });

    test('redaction: email, bearer token, coordinates never reach a line', () {
      final log = LocalErrorLog.forTesting((_) {});
      log.record(
        StateError(
          'sync failed for user=me@corp.example Authorization: Bearer '
          'eyJhbGciOi-abcdef.ghijklmnop.QRSTUVWXYZ012 lat=51.5074 lon=-0.1278 '
          'receipt=rcpt_9f8a',
        ),
        null,
        context: 'email@leak.test',
      );
      final line = log.lines().single;
      expect(line.contains('me@corp.example'), isFalse);
      expect(line.contains('@corp'), isFalse);
      expect(line.contains('eyJhbGciOi-abcdef'), isFalse);
      expect(line.contains('51.5074'), isFalse);
      expect(line.contains('-0.1278'), isFalse);
      expect(line.contains('leak.test'), isFalse);
      expect(line, contains('[redacted-geo]'));
    });

    test('flush: coalesced microtask writes capped contents to the sink', () async {
      final captured = <String>[];
      final log = LocalErrorLog.forTesting((c) => captured.add(c));
      log.record(StateError('x1'), null);
      log.record(StateError('x2'), null);
      await Future<void>.delayed(Duration.zero);
      expect(captured.length, 1); // burst collapsed into one flush
      expect(captured.single.split('\n').where((l) => l.isNotEmpty).length, 2);
    });
  });

  group('file caps (pure)', () {
    test('keeps the LAST 200 lines', () {
      final capped = LocalErrorLog.capFileContents(
        List.generate(500, (i) => 'line$i'),
      );
      final lines = capped.trimRight().split('\n');
      expect(lines.length, 200);
      expect(lines.first, 'line300');
      expect(lines.last, 'line499');
    });

    test('256KB ceiling drops from the front on a line boundary', () {
      final fat = 'z' * (100 * 1024);
      final capped = LocalErrorLog.capFileContents([
        'old-$fat',
        'mid-$fat',
        'new-$fat',
      ]);
      expect(capped.length, lessThanOrEqualTo(256 * 1024));
      expect(capped.endsWith('new-$fat\n'), isTrue);
      expect(capped.contains('old-'), isFalse);
    });
  });

  group('shield wiring (source pins)', () {
    test('main.dart runs inside the zone and installs the shield', () {
      final src = read('lib/main.dart');
      expect(src, contains('runZonedGuarded('));
      expect(src, contains('ErrorShield.install()'));
      // install() runs BEFORE the zone opens, and the zone opening adds
      // no synchronous-await delay to binding init: between
      // runZonedGuarded( and ensureInitialized only the install comment
      // and the arrow live (the pre-existing dotenv/portrait awaits are
      // untouched semantics, not new pre-runApp work — the repo perf pin
      // on those remains the authority).
      final open = src.substring(
        src.indexOf('runZonedGuarded('),
        src.indexOf('ensureInitialized'),
      );
      expect(open.contains('await'), isFalse);
      expect(src.indexOf('ErrorShield.install()'),
          lessThan(src.indexOf('runZonedGuarded(')));
    });

    test('error_shield.dart hooks both channels and consumes platform errors', () {
      final src = read('lib/core/observability/error_shield.dart');
      expect(src, contains('FlutterError.onError'));
      expect(src, contains('FlutterError.presentError'));
      expect(src, contains('PlatformDispatcher.instance.onError'));
      expect(src, contains('return true'));
    });
  });

  group('dead tiles removed (build-or-delete)', () {
    test('login no longer contains the Biometric affordance', () {
      final src = read('lib/features/auth/presentation/login_screen.dart');
      expect(src.contains('Biometric'), isFalse);
      expect(src.contains('_buildBiometricButton'), isFalse);
      // honest-disabled social buttons KEEP (verdict: they label
      // '(soon)', disable taps, and announce 'unavailable' via Semantics)
      expect(src, contains('AuthSocialButtons'));
    });

    test('tafseer no longer contains the dead More-options toast', () {
      final src = read('lib/features/tafseer/presentation/tafseer_screen.dart');
      expect(src.contains('coming soon'), isFalse);
      expect(src.contains('_showMoreOptions'), isFalse);
      expect(src.contains('_showToast'), isFalse);
    });
  });
}
