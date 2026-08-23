import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.main import app  # noqa: E402
from app.services.store import reset_store  # noqa: E402


@pytest.fixture()
def client():
    reset_store()
    with TestClient(app) as test_client:
        yield test_client


def register(client: TestClient, email="user@qibra.ai", password="Secret123", name="Amina"):
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "name": name},
    )
    return response


def auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}
