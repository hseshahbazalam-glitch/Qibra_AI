import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/a11y/app_a11y.dart';
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/design_system/contrast.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/observability/observability.dart';
import 'package:qibra_ai/core/offline/reachability.dart';

void main() {
  test('phase 4 — auth sync SQLAlchemy Alembic', () {
    expect(AppA11y.minTapTarget, 48);
    expect(AppLocales.supported.length, 3);
    expect(EditionResolver.isBundled('ar'), isTrue);
    expect(BillingService.instance.storeStatus, StoreStatus.unconfigured);
    expect(Observability.instance.consent.enabled, isFalse);
    expect(const ReachabilityState(Reachability.unknown).isOnline, isFalse);
    expect(Contrast.goldText.toARGB32(), 0xFF6B542B);
  });
}
