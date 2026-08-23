"""SQLite-backed user and profile store."""

from __future__ import annotations

import sqlite3
import threading
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any

from app.core.config import get_settings
from app.core.security import hash_password, verify_password


def _utcnow() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


@dataclass
class UserRecord:
    id: str
    email: str
    name: str
    password_hash: str
    avatar_url: str | None
    phone_number: str | None
    language: str
    theme: str
    created_at: str
    updated_at: str
    deleted: bool = False

    def public_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "avatar_url": self.avatar_url,
            "phone_number": self.phone_number,
            "language": self.language,
            "theme": self.theme,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "is_email_verified": False,
            "is_premium": False,
        }


class UserStore:
    def __init__(self, database_path: str) -> None:
        self._path = database_path
        self._lock = threading.Lock()
        self._revoked: set[str] = set()
        self._reset_tokens: dict[str, str] = {}
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self._path, check_same_thread=False)
        connection.row_factory = sqlite3.Row
        return connection

    def _init_schema(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT NOT NULL UNIQUE,
                    name TEXT NOT NULL,
                    password_hash TEXT NOT NULL,
                    avatar_url TEXT,
                    phone_number TEXT,
                    language TEXT NOT NULL DEFAULT 'en',
                    theme TEXT NOT NULL DEFAULT 'system',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    deleted INTEGER NOT NULL DEFAULT 0
                )
                """
            )
            connection.commit()

    def _row_to_user(self, row: sqlite3.Row) -> UserRecord:
        return UserRecord(
            id=row["id"],
            email=row["email"],
            name=row["name"],
            password_hash=row["password_hash"],
            avatar_url=row["avatar_url"],
            phone_number=row["phone_number"],
            language=row["language"],
            theme=row["theme"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            deleted=bool(row["deleted"]),
        )

    def get_user(self, user_id: str) -> UserRecord | None:
        with self._lock, self._connect() as connection:
            row = connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        return None if row is None else self._row_to_user(row)

    def get_by_email(self, email: str) -> UserRecord | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                "SELECT * FROM users WHERE email = ?",
                (email.strip().lower(),),
            ).fetchone()
        return None if row is None else self._row_to_user(row)

    def create_user(self, *, email: str, password: str, name: str) -> UserRecord:
        now = _utcnow()
        record = UserRecord(
            id=str(uuid.uuid4()),
            email=email.strip().lower(),
            name=name.strip(),
            password_hash=hash_password(password),
            avatar_url=None,
            phone_number=None,
            language="en",
            theme="system",
            created_at=now,
            updated_at=now,
        )
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO users (
                    id, email, name, password_hash, avatar_url, phone_number,
                    language, theme, created_at, updated_at, deleted
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                """,
                (
                    record.id,
                    record.email,
                    record.name,
                    record.password_hash,
                    record.avatar_url,
                    record.phone_number,
                    record.language,
                    record.theme,
                    record.created_at,
                    record.updated_at,
                ),
            )
            connection.commit()
        return record

    def authenticate(self, email: str, password: str) -> UserRecord | None:
        user = self.get_by_email(email)
        if user is None or user.deleted:
            return None
        if not verify_password(password, user.password_hash):
            return None
        return user

    def update_profile(self, user_id: str, fields: dict[str, Any]) -> UserRecord | None:
        allowed = {"name", "avatar_url", "phone_number", "language", "theme"}
        updates = {key: value for key, value in fields.items() if key in allowed and value is not None}
        if not updates:
            return self.get_user(user_id)
        updates["updated_at"] = _utcnow()
        assignments = ", ".join(f"{key} = ?" for key in updates)
        values = list(updates.values()) + [user_id]
        with self._lock, self._connect() as connection:
            connection.execute(f"UPDATE users SET {assignments} WHERE id = ?", values)
            connection.commit()
        return self.get_user(user_id)

    def delete_user(self, user_id: str) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                "UPDATE users SET deleted = 1, updated_at = ? WHERE id = ?",
                (_utcnow(), user_id),
            )
            connection.commit()

    def revoke_token(self, token: str) -> None:
        if token:
            self._revoked.add(token)

    def is_token_revoked(self, token: str) -> bool:
        return token in self._revoked

    def create_reset_token(self, email: str) -> str | None:
        user = self.get_by_email(email)
        if user is None or user.deleted:
            return None
        token = uuid.uuid4().hex
        self._reset_tokens[token] = user.id
        return token


@lru_cache(maxsize=1)
def get_user_store() -> UserStore:
    return UserStore(str(get_settings().database_path))


def reset_user_store() -> None:
    get_user_store.cache_clear()
