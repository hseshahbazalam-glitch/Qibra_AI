# Phase 10 audit — Premium / subscription architecture

**Date:** 2026-08-31  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `03ae680`  
**This file written before Phase 10 implementation.**

**Verdict: NOT APPROVED for production.** Billing is an honest stub. There is **no** App Store / Play Billing / RevenueCat plugin. `billing_production_ready` is false. `AppApi.isBackendEnabled` is false. Flutter SDK **NOT RUN**. Device **NOT RUN**. Store sandboxes **NOT RUN**.

Do not restyle UI. Do not add a paywall. Do not gate Quran / Hadith / Prayer. Do not trust `isPremium` from JSON. Do not invent store receipts or mark the store configured. Do not replace Phase 4–9 auth/sync/RAG/prayer/notification/offline contracts.

---

## 1. Current billing surface

| Piece | Status |
| --- | --- |
| `lib/core/billing/billing_service.dart` | PRESENT & WIRED stub. `StoreStatus.unconfigured`. Entitlement always `isPremium: false`. `trustPremiumFromJson` always false. |
| `backend/app/services/billing_service.py` | PRESENT. Status unconfigured. JSON ignored. |
| `backend/app/services/store_verify.py` | PRESENT. `configured = False`. `verify(*)` always False. |
| `backend/app/services/entitlement.py` | PRESENT BUT PLACEHOLDER. Only `is_premium` + `source`. No subscription states. |
| `backend/app/routers/billing.py` | PRESENT. `GET /billing/status`, `POST /billing/verify` (no body). Always not premium. |
| `in_app_purchase` / Play Billing / StoreKit | **MISSING** from `pubspec.yaml`. Do not add in this environment — cannot verify. |
| Paywall / restore UI | **MISSING**. Do not create (no UI redesign). |
| Entitlement SQL table | **MISSING**. Must not persist client-claimed premium. |

---

## 2. Auth / user premium

`AppUser.fromJson` forces `isPremium: false`. `/users/me` and `/auth` responses hard-code `is_premium: false`. `isPremiumUserProvider` reads that field (always false). **KEEP.**

---

## 3. What is not a store

No shared secret, no Google service account, no App Store Connect key, no webhook. Observability must not log receipts. Cache must not store receipt blobs or tokens.

Quran, Hadith, Prayer, Duas remain **free**. Feature flags in `AppFeatureFlags` are unrelated to IAP.

---

## 4. Gaps vs production-grade (honest)

| Capability | Today | This environment can implement |
| --- | --- | --- |
| Entitlement state machine | missing | yes — pure function |
| Purchase verification | always false | keep false; do not fake Apple/Google |
| Restore | missing | stub `store_unconfigured` |
| Grace / cancel / expire / refund / revoke | missing | derive() given a **verified** snapshot; production verifier never verifies |
| Offline cache | missing | cache non-premium snapshot; cannot upgrade offline |
| Backend authority | status endpoint | server never grants from client JSON |
| Store plugin | missing | **do not invent** |

---

## 5. Security boundaries

- Client JSON `is_premium: true` → ignore.
- Unconfigured verifier → never grant.
- Offline cache cannot mint premium.
- Refund/revoke (if verified later) must drop premium.
- Quran/Hadith/Prayer not behind entitlement.
- `billing_production_ready` stays false.

---

## 6. Tests today

`test/phase10_*.dart` — flag checks. `backend/tests/test_phase10.py` — unconfigured + ignore JSON. Flutter **NOT RUN**.

---

## 7. Planned edits (after this audit)

State machine + restore/verify routes that remain unconfigured; offline cache of **non-grant**; Dart/Python mirrors; docs. No IAP plugin. No paywall. No Phase 4–9 rewrites.
