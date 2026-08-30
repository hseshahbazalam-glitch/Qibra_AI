# Offline sync

Phase 6 `SyncEngine` is the only client engine. There is no second queue.

```
LOCAL CHANGE → persist locally → enqueue SyncOp
  → NETWORK + backendAvailable → upload batch
  → merge (Phase 6 rules) → ack / conflict
```

While `AppApi.isBackendEnabled` is false, `flushWhenOnline` is a no-op after persisting.

## Queue record

id, collection, type, payload (references only), updatedAt, status, attemptCount, errorCode/lastError, nextRetryAt.

Enqueue of the same `collection+id` replaces the previous op (idempotent slot). JSON dump `qibra_sync_queue_v1` survives restart.

## Retry

Retry: timeout, connection failure, 5xx, 429.  
Do **not** retry: 401/403/404/409/422 and other permanent 4xx.

Backoff: 250ms × 2^attempt, cap 30s, optional jitter (`RetryPolicy`).

## Conflicts (unchanged)

Bookmarks: set-union with tombstones. Progress/settings: latest `updated_at` wins.

Never queue passwords, tokens, GPS, or scripture text.
