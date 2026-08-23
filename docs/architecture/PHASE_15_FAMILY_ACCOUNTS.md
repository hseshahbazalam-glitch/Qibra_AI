# Phase 15 — Family space

Phase 15 evolves Qibra AI's existing Family A experience with a family-space foundation. It does not create a second app or replace the current authentication and navigation architecture.

## Delivered

- A Family space entry in **More → Account**.
- A local-first family model with an owner and up to seven additional members.
- Create, rename, add-member, remove-member, and delete-space flows.
- A generated invite code that can be copied for sharing on the same device or during an in-person setup.
- Encrypted local persistence through the existing `FlutterSecureStorage` provider.
- Clear UI copy that avoids presenting local data as cloud accounts or cross-device sync.

## Boundary

The current build intentionally has backend authentication disabled (`AppApi.isBackendEnabled == false`). For that reason, Phase 15 stores the family space on-device and does not claim to send invitations, join a family from another account, or sync activity across devices. The model and provider form the seam for those operations when the Qibra backend is deployed.

## Navigation

- Route: `/family`
- Entry point: `MoreScreen` → `Family space`
- Primary navigation remains Home, Quran, Prayer, Hadith, AI, and More.
