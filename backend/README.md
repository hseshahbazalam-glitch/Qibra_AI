# Qibra AI FastAPI backend

This backend sits beside the existing Flutter app. It does not replace the
mobile project and it does not change `docs/api/API_CONTRACT.md`.

Base URL implemented by the contract:

```
/api/v1
```

The same routes are also mounted at `/v1` so the current Flutter `AppApi`
client can connect later without a contract rewrite. Flutter stays
anonymous-first (`AppApi.isBackendEnabled == false`) until this service is
deployed.

## Run locally

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Open `http://localhost:8000/docs` for the live schema.

## Tests

```bash
cd backend
python3 -m pytest
```

## Data sources

- Quran and Hadith are read from the existing Flutter assets in `assets/data/`.
- Duas are the offline masnoon catalog already shipped in `lib/features/duas`.
- Tafsir lookups never invent commentary. If a licensed corpus is not bundled,
  the API says so and returns the matching translation labelled as translation.

## Auth

JWT access tokens are issued by `POST /api/v1/auth/register` and
`POST /api/v1/auth/login`. Profile routes require `Authorization: Bearer <token>`.
Passwords are stored as PBKDF2-SHA256 hashes. No API keys belong in the Flutter
client.
