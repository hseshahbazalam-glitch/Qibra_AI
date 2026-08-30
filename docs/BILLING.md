# Billing

See `BILLING_ARCHITECTURE.md`.

- Billing is unconfigured until a real store product and receipt verifier exist.
- Never trust `isPremium` from API JSON.
- Restore and verify endpoints return `store_unconfigured`.
- Do not log receipts or purchase tokens.
- Quran / Hadith / Prayer stay free.
