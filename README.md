# Qibra AI

Existing Flutter app for Quran, Hadith, Prayer, Qibla, AI, Tools, and Auth.

Ivory / forest / gold UI (`QibraColors`, `QibraPage`, `QibraAppBar`). Recitation audio is not bundled.

Backend 0.6.0 lives in `backend/` (`/api/v1` and `/v1`). It is an in-memory FastAPI service, not a production deploy.

```bash
cd backend && python3 -m pip install -r requirements.txt
python3 -m pytest backend/tests/test_phase3.py
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
