# Qibra AI

Islamic super app. Flutter client plus a FastAPI backend that implements the
published HTTP contract.

This is the existing project. Do not scaffold a new Flutter app on top of it.

## What’s here

- **Flutter** — offline-first Quran, prayer, hadith, duas, qibla, tools, and a local family space
- **FastAPI** — `docs/api/API_CONTRACT.md` served from `backend/` on `/api/v1`
- **Docs** — architecture, design, testing, and backend notes under `docs/`
- **Tests** — Flutter suites in `test/`, backend suites in `backend/tests/`

The contract file is frozen. Feature work implements it; it does not rewrite it.

## Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The current build keeps `AppApi.isBackendEnabled = false`, so sign-in and the
cloud AI proxy stay off until the backend is deployed. Offline modules still
work.

## Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m pytest
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Phase 15 family space

Family space is local-first under **More → Account**. It does not claim
cross-device invites while backend authentication is disabled.
