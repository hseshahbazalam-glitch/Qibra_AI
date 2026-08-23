# Qibra API 0.6.0

In-process FastAPI service for auth, users, bookmarks, sync, retrieval-only AI, and billing stubs.

This is not a production deployment. Quran/Hadith corpora stay on the Flutter client.

```bash
cd backend
python3 -m pip install -r requirements.txt
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Health: `GET /health`, `GET /api/v1/health`, `GET /v1/health`.

Tests (run each phase file separately):

```bash
python3 -m pytest backend/tests/test_phase3.py
python3 -m pytest backend/tests/test_phase4.py
# ... through test_phase15.py
```
