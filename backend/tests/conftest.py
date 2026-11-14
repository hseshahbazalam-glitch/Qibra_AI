import os
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

# QB-001 / QB-004 made both of these required, with no code-side fallback — so the
# suite declares them, exactly as a deployment does. QIBRA_ENV=dev is the *explicit*
# opt-in that lets the tests use an in-memory SQLite database; a production boot that
# forgets it now fails closed instead of landing on the permissive branch by accident.
os.environ.setdefault("QIBRA_ENV", "dev")
os.environ.setdefault(
    "DATABASE_URL", "sqlite+pysqlite:///:memory:"
)  # allowed because QIBRA_ENV=dev, not because it is a default
os.environ.setdefault("JWT_SECRET", "qibra-test-only-signing-secret-32b+")  # 38 bytes


@pytest.fixture(autouse=True)
def _reset_rate_limit_between_tests():
    from app.middleware.rate_limit import reset_rate_limit_store
    from app.services.ai_quota import reset_ai_quota_store
    from app.services.login_guard import reset_login_guard_store

    reset_rate_limit_store()
    reset_ai_quota_store()
    reset_login_guard_store()
    yield
    reset_rate_limit_store()
    reset_ai_quota_store()
    reset_login_guard_store()
