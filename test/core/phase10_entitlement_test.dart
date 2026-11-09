import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/billing/billing_service.dart';
import 'package:qibra_ai/core/cache/cache_store.dart';


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
      _m6bad.add('core_phase10_entitlement_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase10_entitlement_test :: $d :: ${e.toString().split('\n').first}');
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
    print('::error::M6BADEND core_phase10_entitlement_test ${_m6bad.length}');
  });

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
