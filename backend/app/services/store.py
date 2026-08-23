from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from threading import Lock
from typing import Any
from uuid import uuid4


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


@dataclass
class UserRecord:
    id: str
    email: str
    password_hash: str
    name: str
    created_at: str
    updated_at: str
    deleted: bool = False

    def public(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "createdAt": self.created_at,
            "updatedAt": self.updated_at,
        }


@dataclass
class BookmarkRecord:
    id: str
    user_id: str
    kind: str
    ref: str
    note: str | None
    created_at: str

    def public(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "kind": self.kind,
            "ref": self.ref,
            "note": self.note,
            "createdAt": self.created_at,
        }


@dataclass
class BillingState:
    plan: str = "free"
    status: str = "inactive"
    checkout_id: str | None = None


@dataclass
class Store:
    users: dict[str, UserRecord] = field(default_factory=dict)
    users_by_email: dict[str, str] = field(default_factory=dict)
    bookmarks: dict[str, BookmarkRecord] = field(default_factory=dict)
    revoked_jti: set[str] = field(default_factory=set)
    billing: dict[str, BillingState] = field(default_factory=dict)
    sync_rev: dict[str, int] = field(default_factory=dict)
    lock: Lock = field(default_factory=Lock)

    def reset(self) -> None:
        with self.lock:
            self.users.clear()
            self.users_by_email.clear()
            self.bookmarks.clear()
            self.revoked_jti.clear()
            self.billing.clear()
            self.sync_rev.clear()

    def create_user(self, email: str, password_hash: str, name: str) -> UserRecord:
        email_key = email.lower().strip()
        with self.lock:
            if email_key in self.users_by_email:
                raise ValueError("Email already registered.")
            now = utc_now()
            user = UserRecord(
                id=uuid4().hex,
                email=email_key,
                password_hash=password_hash,
                name=name.strip() or "Guest",
                created_at=now,
                updated_at=now,
            )
            self.users[user.id] = user
            self.users_by_email[email_key] = user.id
            self.billing[user.id] = BillingState()
            self.sync_rev[user.id] = 0
            return user

    def get_user(self, user_id: str) -> UserRecord | None:
        user = self.users.get(user_id)
        if user is None or user.deleted:
            return None
        return user

    def get_user_by_email(self, email: str) -> UserRecord | None:
        user_id = self.users_by_email.get(email.lower().strip())
        if not user_id:
            return None
        return self.get_user(user_id)

    def update_user(self, user_id: str, *, name: str | None = None) -> UserRecord:
        user = self.get_user(user_id)
        if user is None:
            raise KeyError(user_id)
        if name is not None:
            user.name = name.strip() or user.name
        user.updated_at = utc_now()
        self.sync_rev[user_id] = self.sync_rev.get(user_id, 0) + 1
        return user

    def delete_user(self, user_id: str) -> None:
        user = self.get_user(user_id)
        if user is None:
            raise KeyError(user_id)
        user.deleted = True
        self.users_by_email.pop(user.email, None)

    def revoke(self, jti: str) -> None:
        if jti:
            self.revoked_jti.add(jti)

    def is_revoked(self, jti: str) -> bool:
        return jti in self.revoked_jti

    def add_bookmark(
        self, user_id: str, kind: str, ref: str, note: str | None
    ) -> BookmarkRecord:
        record = BookmarkRecord(
            id=uuid4().hex,
            user_id=user_id,
            kind=kind,
            ref=ref,
            note=note,
            created_at=utc_now(),
        )
        self.bookmarks[record.id] = record
        self.sync_rev[user_id] = self.sync_rev.get(user_id, 0) + 1
        return record

    def list_bookmarks(self, user_id: str) -> list[BookmarkRecord]:
        return [
            item
            for item in self.bookmarks.values()
            if item.user_id == user_id
        ]

    def delete_bookmark(self, user_id: str, bookmark_id: str) -> bool:
        item = self.bookmarks.get(bookmark_id)
        if item is None or item.user_id != user_id:
            return False
        del self.bookmarks[bookmark_id]
        self.sync_rev[user_id] = self.sync_rev.get(user_id, 0) + 1
        return True

    def replace_bookmarks(
        self, user_id: str, items: list[dict[str, Any]]
    ) -> list[BookmarkRecord]:
        for key, item in list(self.bookmarks.items()):
            if item.user_id == user_id:
                del self.bookmarks[key]
        created: list[BookmarkRecord] = []
        for raw in items:
            created.append(
                self.add_bookmark(
                    user_id,
                    str(raw.get("kind") or "other"),
                    str(raw.get("ref") or ""),
                    raw.get("note"),
                )
            )
        return created

    def snapshot(self, user_id: str) -> dict[str, Any]:
        user = self.get_user(user_id)
        return {
            "rev": self.sync_rev.get(user_id, 0),
            "profile": user.public() if user else None,
            "bookmarks": [item.public() for item in self.list_bookmarks(user_id)],
        }


_STORE = Store()


def get_store() -> Store:
    return _STORE


def reset_store() -> Store:
    _STORE.reset()
    return _STORE
