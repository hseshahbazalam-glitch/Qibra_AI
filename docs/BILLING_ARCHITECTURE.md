# Billing architecture

Store is **unconfigured**. No Play Billing / StoreKit / RevenueCat plugin is wired.

## Authority

1. Client JSON `isPremium` is ignored.
2. `StoreVerifier` always returns unverified.
3. `EntitlementPolicy.derive(verified: false)` never grants.
4. Offline cache cannot mint premium (`serverValidated` false).
5. `/users/me` `is_premium` stays false.

A **test-only** `verified: true` path exists so grace / cancel / expiry / refund / revoke can be unit-tested. Production code never sets `verified`.

## States

`none` → `pending` → `active` → (`cancelled` still entitled until `expiresAt`) → `in_grace` → `expired`  
`refunded` / `revoked` drop access immediately.

## Free features

Quran, Hadith, Prayer, Duas, Qibla, Tasbih are **not gated**.

`billing_production_ready` remains **false**.
