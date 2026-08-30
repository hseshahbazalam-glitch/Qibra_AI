"""Idempotent sync-queue rules mirroring the Flutter SyncQueue."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class SyncOp:
    id: str
    collection: str
    type: str
    payload: dict
    updated_at: datetime
    status: str = "pending"
    attempt_count: int = 0
    error_code: Optional[str] = None
    next_retry_at: Optional[datetime] = None

    def to_json(self) -> dict:
        return {
            "id": self.id,
            "collection": self.collection,
            "type": self.type,
            "payload": self.payload,
            "updated_at": self.updated_at.isoformat(),
            "status": self.status,
            "attempt_count": self.attempt_count,
            "error_code": self.error_code,
            "next_retry_at": self.next_retry_at.isoformat() if self.next_retry_at else None,
        }

    @classmethod
    def from_json(cls, row: dict) -> "SyncOp":
        nxt = row.get("next_retry_at")
        return cls(
            id=str(row.get("id") or ""),
            collection=str(row.get("collection") or ""),
            type=str(row.get("type") or "upsert"),
            payload=dict(row.get("payload") or {}),
            updated_at=datetime.fromisoformat(row["updated_at"])
            if row.get("updated_at")
            else datetime.fromtimestamp(0),
            status=str(row.get("status") or "pending"),
            attempt_count=int(row.get("attempt_count") or 0),
            error_code=row.get("error_code"),
            next_retry_at=datetime.fromisoformat(nxt) if nxt else None,
        )


class SyncQueue:
    def __init__(self) -> None:
        self._ops: list[SyncOp] = []

    @property
    def pending(self) -> list[SyncOp]:
        return [o for o in self._ops if o.status == "pending"]

    def enqueue(self, op: SyncOp) -> None:
        self._ops = [o for o in self._ops if not (o.collection == op.collection and o.id == op.id)]
        op.status = "pending"
        op.next_retry_at = None
        self._ops.append(op)

    def ack(self, id: str, collection: str) -> None:
        self._ops = [o for o in self._ops if not (o.id == id and o.collection == collection)]

    def mark_failed(self, id: str, collection: str, error: str, next_retry_at: Optional[datetime] = None) -> None:
        for op in self._ops:
            if op.id == id and op.collection == collection:
                op.status = "failed"
                op.attempt_count += 1
                op.error_code = error
                op.next_retry_at = next_retry_at

    def snapshot(self) -> list[dict]:
        return [o.to_json() for o in self._ops]

    def restore(self, rows: list[dict]) -> None:
        self._ops = [SyncOp.from_json(r) for r in rows]
