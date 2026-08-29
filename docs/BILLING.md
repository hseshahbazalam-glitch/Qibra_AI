# Billing

See `BILLING_ARCHITECTURE.md`.

- Billing is unconfigured until a store product is wired.
- Never trust `isPremium` from API JSON.
- Entitlement is client-store / server-authoritative only after configuration.
