import json
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import SyncRecord


def merge_records(db: Session, user_id: int, items: list[dict]) -> list[dict]:
    """Last-write-wins merge. Newer updated_at wins."""
    out = []
    for item in items:
        collection = item["collection"]
        item_id = item["item_id"]
        incoming_ts = datetime.fromisoformat(item["updated_at"].replace("Z", "+00:00"))
        existing = db.scalar(
            select(SyncRecord).where(
                SyncRecord.user_id == user_id,
                SyncRecord.collection == collection,
                SyncRecord.item_id == item_id,
            )
        )
        payload = json.dumps(item.get("payload") or {})
        deleted = bool(item.get("deleted"))
        if existing is None:
            rec = SyncRecord(
                user_id=user_id,
                collection=collection,
                item_id=item_id,
                payload=payload,
                updated_at=incoming_ts,
                deleted=deleted,
            )
            db.add(rec)
            out.append(item)
            continue
        existing_ts = existing.updated_at
        if existing_ts.tzinfo is None:
            existing_ts = existing_ts.replace(tzinfo=timezone.utc)
        if incoming_ts >= existing_ts:
            existing.payload = payload
            existing.updated_at = incoming_ts
            existing.deleted = deleted
            out.append(item)
        else:
            out.append(
                {
                    "collection": existing.collection,
                    "item_id": existing.item_id,
                    "payload": json.loads(existing.payload),
                    "updated_at": existing.updated_at.isoformat(),
                    "deleted": existing.deleted,
                }
            )
    db.commit()
    return out
