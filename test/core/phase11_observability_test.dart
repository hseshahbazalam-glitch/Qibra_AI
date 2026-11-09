import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/observability/observability.dart';


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
      _m6bad.add('core_phase11_observability_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase11_observability_test :: $d :: ${e.toString().split('\n').first}');
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
  });

  test('consent default off and allowlist', () {
    final obs = Observability.instance;
    obs.consent = ObservabilityConsent.off;
    obs.record('opened_home');
    expect(obs.snapshot(), isEmpty);
    expect(obs.consent.enabled, isFalse);
    expect(EventAllowlist.isAllowed('opened_home'), isTrue);
    expect(EventAllowlist.isAllowed('email_leaked'), isFalse);
    expect(EventAllowlist.isAllowed('random_dump'), isFalse);
  });

  test('redactor strips email token geo', () {
    final out = LogRedactor.redact('a@b.com bearer xyz lat=21.4');
    expect(out.contains('a@b.com'), isFalse);
    expect(out.contains('21.4'), isFalse);
  });

  test('metrics skip forbidden names; crash hook has no payload', () {
    final m = LocalMetrics();
    m.inc('gps_fix');
    m.inc('rag_no_context');
    m.noteCrash();
    expect(m.snapshot().containsKey('gps_fix'), isFalse);
    expect(m.snapshot()['rag_no_context'], 1);
    expect(m.snapshot()['crash_hook'], 1);
  });
}
