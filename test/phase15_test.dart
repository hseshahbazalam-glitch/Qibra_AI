import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/a11y/app_a11y.dart';
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/observability/observability.dart';
import 'package:qibra_ai/core/sync/sync_engine.dart';

void main() {
  test('phase 15 — RAG honesty + a11y + billing unconfigured', () {
    expect(AppA11y.minTapTarget, 48);
    expect(BillingService.instance.storeStatus, StoreStatus.unconfigured);
    expect(Observability.instance.consent.enabled, isFalse);
    expect(SyncEngine.instance.isInFlight, isFalse);
  });
}
