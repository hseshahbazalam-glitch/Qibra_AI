"""Shared pytest fixtures."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = BACKEND_ROOT.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


@pytest.fixture()
def client(tmp_path, monkeypatch):
    monkeypatch.setenv("QIBRA_DATABASE_PATH", str(tmp_path / "qibra-test.db"))
    monkeypatch.setenv("QIBRA_JWT_SECRET", "test-secret")
    monkeypatch.setenv("QIBRA_ASSETS_ROOT", str(REPO_ROOT / "assets" / "data"))
    monkeypatch.setenv("QIBRA_ENV", "test")

    from app.core.config import get_settings
    from app.services.user_store import reset_user_store

    get_settings.cache_clear()
    reset_user_store()

    from app.main import create_app

    application = create_app()
    with TestClient(application) as test_client:
        yield test_client

    get_settings.cache_clear()
    reset_user_store()


def envelope_keys(payload: dict) -> set[str]:
    return set(payload)


ENVELOPE = {"success", "message", "data", "timestamp", "traceId"}
