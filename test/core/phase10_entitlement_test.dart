import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/cache/cache_store.dart';

void main() {
  final now = DateTime.utc(2026, 8, 31, 12);

  test('store stays unconfigured and JSON is not trusted', () {
    expect(BillingService.instance.storeStatus, StoreStatus.unconfigured);
    expect(
      BillingService.instance.trustPremiumFromJson({'isPremium': true}),
      isFalse,
    );
    expect(EntitlementPolicy.isGated('quran'), isFalse);
    expect(EntitlementPolicy.isGated('hadith'), isFalse);
    expect(EntitlementPolicy.isGated('prayer'), isFalse);
  });

  test('unverified snapshots never grant', () {
    final ent = EntitlementPolicy.derive(
      verified: false,
      now: now,
      state: SubscriptionState.active,
      expiresAt: now.add(const Duration(days: 30)),
    );
    expect(ent.isPremium, isFalse);
    expect(ent.serverValidated, isFalse);
  });

  test('verified grace, cancel, expiry, refund', () {
    final exp = now.add(const Duration(days: 1));
    final grace = now.add(const Duration(days: 4));
    final active = EntitlementPolicy.derive(
      verified: true,
      now: now,
      state: SubscriptionState.active,
      source: 'test',
      expiresAt: exp,
      graceEndsAt: grace,
    );
    expect(active.isPremium, isTrue);
    final inGrace = EntitlementPolicy.derive(
      verified: true,
      now: exp.add(const Duration(hours: 1)),
      state: SubscriptionState.active,
      source: 'test',
      expiresAt: exp,
      graceEndsAt: grace,
    );
    expect(inGrace.state, SubscriptionState.inGrace);
    expect(inGrace.isPremium, isTrue);
    final cancelled = EntitlementPolicy.derive(
      verified: true,
      now: now,
      state: SubscriptionState.cancelled,
      source: 'test',
      expiresAt: exp,
    );
    expect(cancelled.isPremium, isTrue);
    final refunded = EntitlementPolicy.derive(
      verified: true,
      now: now,
      state: SubscriptionState.refunded,
      source: 'test',
      expiresAt: exp,
    );
    expect(refunded.isPremium, isFalse);
  });

  test('offline cache cannot mint premium', () async {
    final billing = BillingService(cache: CacheStore(backend: MemoryCacheBackend()));
    final cached = billing.applyOfflineCache(
      const Entitlement(
        isPremium: true,
        source: 'client_json',
        serverValidated: false,
      ),
      online: false,
    );
    expect(cached.isPremium, isFalse);
    expect(cached.serverValidated, isFalse);
    final restored = await billing.restorePurchases();
    expect(restored.isPremium, isFalse);
  });
}
