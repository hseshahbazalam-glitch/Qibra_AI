"""QB-004 — the database is a required, non-silent boot input, and /health shows only
its type so a wrong Render setting is visible without leaking credentials.

Red first: at 9aedc87 `config.py:35` defaults to `sqlite+pysqlite:///:memory:`, nothing
refuses it outside `QIBRA_ENV=production`, and /health says nothing about the database.
"""

from pathlib import Path

import pytest

from app.config import BootConfigError, database_summary, database_url_or_raise

PG = "postgresql+psycopg://dbuser:supersecret@db.internal:5432/qibra"
MEM = "sqlite+pysqlite:///:memory:"


def test_missing_url_refuses_to_boot_in_every_environment():
    for env in ({}, {"QIBRA_ENV": "production"}, {"QIBRA_ENV": "dev"}):
        with pytest.raises(BootConfigError) as exc:
            database_url_or_raise(env)
        assert "DATABASE_URL" in str(exc.value)


def test_sqlite_is_refused_unless_dev_is_explicit():
    with pytest.raises(BootConfigError) as exc:
        database_url_or_raise({"DATABASE_URL": MEM})
    assert "QIBRA_ENV=dev" in str(exc.value)
    with pytest.raises(BootConfigError):
        database_url_or_raise({"DATABASE_URL": MEM, "QIBRA_ENV": "staging"})
    assert database_url_or_raise({"DATABASE_URL": MEM, "QIBRA_ENV": "dev"}) == MEM


def test_postgres_is_accepted_anywhere():
    assert database_url_or_raise({"DATABASE_URL": PG}) == PG
    assert (
        database_url_or_raise({"DATABASE_URL": PG, "QIBRA_ENV": "production"}) == PG
    )


def test_whitespace_only_url_is_not_a_url():
    with pytest.raises(BootConfigError):
        database_url_or_raise({"DATABASE_URL": "   "})


def test_summary_reports_type_only_never_credentials():
    summary = database_summary(PG)
    assert summary["type"] == "postgresql"
    assert summary["in_memory"] is False
    blob = str(summary)
    for secret in ("supersecret", "dbuser", "db.internal", "5432", "//"):
        assert secret not in blob


def test_summary_marks_an_in_memory_database_as_such():
    assert database_summary(MEM) == {"type": "sqlite", "in_memory": True}
    file_db = database_summary("sqlite+pysqlite:///./qibra.db")
    assert file_db == {"type": "sqlite", "in_memory": False}


def test_health_endpoint_reports_the_type_and_no_credentials():
    from helpers import fresh_client

    with fresh_client() as client:
        body = client.get("/health").json()
        assert body["database"]["type"] == "sqlite"
        assert body["database"]["in_memory"] is True
        blob = str(body)
        for banned in ("://", "@", "sqlite+pysqlite"):
            assert banned not in blob


def test_the_memory_url_is_no_longer_a_source_default():
    """config.py must not carry a default URL at all — missing is an error, not a
    quietly-ephemeral database."""
    source = (
        Path(__file__).resolve().parents[1] / "app" / "config.py"
    ).read_text(encoding="utf-8")
    # no ambient read with a fallback at all — both values come from the guards
    assert 'os.environ.get("DATABASE_URL"' not in source
    assert 'os.environ.get("JWT_SECRET"' not in source
    for line in source.splitlines():
        if ":memory:" in line:
            assert "in_memory" in line, line  # only the /health detector may name it
