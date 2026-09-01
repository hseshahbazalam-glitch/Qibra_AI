import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import StaticPool

from ..config import get_settings


class Base(DeclarativeBase):
    pass


def _make_engine(url: str):
    env = os.environ.get("QIBRA_ENV", "").strip().lower()
    if env in {"prod", "production"} and url.startswith("sqlite"):
        raise RuntimeError("SQLite is not allowed when QIBRA_ENV=production; use PostgreSQL")
    kwargs: dict = {"future": True}
    if url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False}
        if ":memory:" in url:
            kwargs["poolclass"] = StaticPool
    elif url.startswith("postgresql"):
        kwargs["pool_pre_ping"] = True
        kwargs["pool_size"] = 5
    return create_engine(url, **kwargs)


engine = _make_engine(get_settings().database_url)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def reset_engine(url: str | None = None):
    global engine, SessionLocal
    from . import models  # noqa: F401 — register tables on Base.metadata

    if url:
        engine = _make_engine(url)
        SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
    Base.metadata.create_all(bind=engine)
