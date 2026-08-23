# Qibra backend notes

The published HTTP contract lives in `docs/api/API_CONTRACT.md` and must not
be rewritten by feature work.

This tree adds a FastAPI implementation of that contract next to the existing
Flutter application.

## Envelope

Every JSON response uses:

```json
{
  "success": true,
  "message": "OK",
  "data": {},
  "timestamp": "2026-08-23T00:00:00Z",
  "traceId": "uuid"
}
```

## Boundary with Flutter

- Contract paths: `/api/v1/...`
- Flutter `AppApi` prefix today: `/v1/...`
- Both prefixes are served by `backend/app/main.py`
- Family space (Phase 15) stays local-first. It is not in the published
  contract and is not claimed as a cloud account API.
