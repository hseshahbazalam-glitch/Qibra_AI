// Store billing is unconfigured. Client must not trust JSON isPremium.

enum StoreStatus { unconfigured, available, unavailable }

class Entitlement {
  const Entitlement({required this.isPremium, required this.source});
  final bool isPremium;
  final String source;
}

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  StoreStatus get storeStatus => StoreStatus.unconfigured;

  Future<Entitlement> currentEntitlement() async {
    return const Entitlement(isPremium: false, source: 'store_unconfigured');
  }

  bool trustPremiumFromJson(Map<String, dynamic> json) {
    // Never trust server/user JSON for premium.
    return false;
  }
}
