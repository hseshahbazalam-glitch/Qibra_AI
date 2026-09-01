# Sync protocol

Anonymous-first: local bookmarks/settings/progress work offline. Cloud sync runs only when `AppApi.isBackendEnabled` is true **and** the user is authenticated.

## Conflict rules

| Entity | Rule |
| --- | --- |
| Settings / preferences | last `updated_at` wins |
| Reading progress | latest valid payload for `kind` wins (upsert) |
| Bookmarks | set-union of `(collection, item_id)`; deletes are tombstones (`deleted: true` on `/sync`) |
| Refresh sessions | not synced; server-side revoke |

Do not upload Quran/Hadith full text. Store references (`surah`+`ayah`, `bookSlug`+`hadithNumber`).

## Queue (client)

`SyncOpStatus`: pending → processing → completed | failed | conflict.

Batch cap: **500** operations (`sync_batch_too_large`).

Never queue passwords or tokens.

## Anonymous → account

Local state is **not** wiped on login. When backend is enabled, enqueue local ops then merge with GET/POST `/sync`. This pass does not enable the client backend flag.
