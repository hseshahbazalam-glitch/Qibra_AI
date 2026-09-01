import os
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret")


@pytest.fixture(autouse=True)
def _reset_rate_limit_between_tests():
    from app.middleware.rate_limit import reset_rate_limit_store

    reset_rate_limit_store()
    yield
    reset_rate_limit_store()
