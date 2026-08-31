// Store billing is unconfigured. Client must not trust JSON isPremium.
// Quran, Hadith, and Prayer stay free. Receipts are never logged.

import '../cache/cache_store.dart';

enum StoreStatus { unconfigured, available, unavailable }

enum SubscriptionState {
  none,
  pending,
  active,
  inGrace,
  cancelled,
  expired,
  refunded,
  revoked,
}

class Entitlement {
  const Entitlement({
    required this.isPremium,
    required this.source,
    this.state = SubscriptionState.none,
    this.serverValidated = false,
    this.productId = '',
    this.store = 'unconfigured',
    this.reason = '',
  });

  final bool isPremium;
  final String source;
  final SubscriptionState state;
  final bool serverValidated;
  final String productId;
  final String store;
  final String reason;
}

abstract final class EntitlementPolicy {
  static const freeFeatures = {
    'quran',
    'hadith',
    'prayer',
    'duas',
    'qibla',
    'tasbih',
  };

  static bool isGated(String feature) {
    if (freeFeatures.contains(feature)) return false;
    return false;
  }

  static Entitlement derive({
    required bool verified,
    required DateTime now,
    SubscriptionState state = SubscriptionState.none,
    String source = 'unconfigured',
    String productId = '',
    String store = 'unconfigured',
    DateTime? expiresAt,
    DateTime? graceEndsAt,
  }) {
    if (!verified) {
      return Entitlement(
        isPremium: false,
        source: source,
        state: state,
        store: store,
        productId: productId,
        reason: 'unverified',
      );
    }
    if (state == SubscriptionState.refunded ||
        state == SubscriptionState.revoked) {
      return Entitlement(
        isPremium: false,
        source: source,
        state: state,
        serverValidated: true,
        store: store,
        productId: productId,
        reason: state.name,
      );
    }
    if (state == SubscriptionState.pending) {
      return Entitlement(
        isPremium: false,
        source: source,
        state: state,
        serverValidated: true,
        store: store,
        productId: productId,
        reason: 'pending',
      );
    }
    if (state == SubscriptionState.inGrace) {
      if (graceEndsAt != null && now.isBefore(graceEndsAt)) {
        return Entitlement(
          isPremium: true,
          source: source,
          state: SubscriptionState.inGrace,
          serverValidated: true,
          store: store,
          productId: productId,
        );
      }
      return Entitlement(
        isPremium: false,
        source: source,
        state: SubscriptionState.expired,
        serverValidated: true,
        store: store,
        productId: productId,
        reason: 'grace_elapsed',
      );
    }
    if (state == SubscriptionState.active ||
        state == SubscriptionState.cancelled) {
      if (expiresAt != null && !now.isBefore(expiresAt)) {
        if (graceEndsAt != null && now.isBefore(graceEndsAt)) {
          return Entitlement(
            isPremium: true,
            source: source,
            state: SubscriptionState.inGrace,
            serverValidated: true,
            store: store,
            productId: productId,
          );
        }
        return Entitlement(
          isPremium: false,
          source: source,
          state: SubscriptionState.expired,
          serverValidated: true,
          store: store,
          productId: productId,
          reason: 'expired',
        );
      }
      return Entitlement(
        isPremium: true,
        source: source,
        state: state,
        serverValidated: true,
        store: store,
        productId: productId,
      );
    }
    return Entitlement(
      isPremium: false,
      source: source,
      state: state,
      serverValidated: true,
      store: store,
      productId: productId,
      reason: 'not_entitled',
    );
  }
}

class BillingService {
  BillingService({CacheStore? cache}) : _cache = cache;

  BillingService._() : _cache = null;

  static final BillingService instance = BillingService._();

  final CacheStore? _cache;
  static const cacheKey = 'entitlement_v1';

  StoreStatus get storeStatus => StoreStatus.unconfigured;

  Future<Entitlement> currentEntitlement() async {
    return const Entitlement(isPremium: false, source: 'store_unconfigured');
  }

  bool trustPremiumFromJson(Map<String, dynamic> json) {
    return false;
  }

  Future<Entitlement> restorePurchases() async {
    return const Entitlement(
      isPremium: false,
      source: 'store_unconfigured',
      reason: 'store_unconfigured',
    );
  }

  Entitlement applyOfflineCache(Entitlement? cached, {required bool online}) {
    if (cached == null) {
      return const Entitlement(isPremium: false, source: 'missing_cache');
    }
    if (!cached.serverValidated) {
      return Entitlement(
        isPremium: false,
        source: cached.source,
        state: cached.state,
        serverValidated: false,
        reason: 'unvalidated_cache',
      );
    }
    if (!online) {
      return Entitlement(
        isPremium: cached.isPremium,
        source: cached.source,
        state: cached.state,
        serverValidated: false,
        productId: cached.productId,
        store: cached.store,
        reason: 'offline_cached',
      );
    }
    return cached;
  }

  Future<void> persistNonGrant(CacheStore store) async {
    await store.write(
      cacheKey,
      '{"is_premium":false,"source":"store_unconfigured"}',
      source: 'billing',
    );
  }

  CacheStore? get cache => _cache;
}
