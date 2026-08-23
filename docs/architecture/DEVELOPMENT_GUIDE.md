# Qibra AI development guide

Work in the existing repository. Do not create a new Flutter project and do
not rewrite `docs/api/API_CONTRACT.md`.

## Layout

```
lib/                 Flutter application (Riverpod + GoRouter)
assets/data/         Offline Quran and Hadith corpora
backend/             FastAPI implementation of the published contract
docs/api/            Frozen HTTP contract
test/                Flutter tests
backend/tests/       Backend contract and domain tests
```

## Flutter

The app is anonymous-first while `AppApi.isBackendEnabled` is `false`. Quran,
prayer, hadith, duas, qibla, and family space work offline.

When a backend is deployed, point `AppApi.baseUrl` at that host and enable
the flag. Do not mint fake JWTs on the client.

## FastAPI

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m pytest
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The contract base path is `/api/v1`. The same router is also mounted at `/v1`
for the current Flutter client.

## Quality bar

- `python3 -m pytest` in `backend/`
- `flutter analyze` and `flutter test` when the Flutter SDK is available
- No fabricated Quran, Hadith, or tafsir citations
- No secrets in client assets
