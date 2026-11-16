import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/observability/observability.dart';

void main() {
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
