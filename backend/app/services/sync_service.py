import json
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import SyncOperation, SyncRecord


def merge_records(db: Session, user_id: int, items: list[dict]) -> tuple[list[dict], list[dict]]:
    """Last-write-wins merge with per-item status. One bad item does not abort the batch."""
    out: list[dict] = []
    results: list[dict] = []

    existing_map: dict[tuple[str, str], SyncRecord] = {
        (r.collection, r.item_id): r
        for r in db.scalars(select(SyncRecord).where(SyncRecord.user_id == user_id)).all()
    }
    batch_op_ids = [
        str(item.get("operation_id") or "")[:64]
        for item in items
        if str(item.get("operation_id") or "")
    ]
    seen_ops: set[str] = set()
    if batch_op_ids:
        seen_ops = {
            r.operation_id
            for r in db.scalars(
                select(SyncOperation).where(
                    SyncOperation.user_id == user_id,
                    SyncOperation.operation_id.in_(batch_op_ids),
                )
            ).all()
        }

    for item in items:
        try:
            collection = str(item.get("collection") or "")
            item_id = str(item.get("item_id") or "")
            if not collection or not item_id:
                results.append(
                    {"item_id": item_id, "status": "rejected", "reason": "missing_id"}
                )
                continue
            op_id = str(item.get("operation_id") or "")
            if op_id:
                op_id = op_id[:64]
            if op_id and op_id in seen_ops:
                results.append({"item_id": item_id, "status": "accepted", "reason": "idempotent"})
                existing = existing_map.get((collection, item_id))
                if existing:
                    out.append(
                        {
                            "collection": existing.collection,
                            "item_id": existing.item_id,
                            "payload": json.loads(existing.payload),
                            "updated_at": existing.updated_at.isoformat(),
                            "deleted": existing.deleted,
                        }
                    )
                continue
            incoming_ts = datetime.fromisoformat(str(item["updated_at"]).replace("Z", "+00:00"))
            existing = existing_map.get((collection, item_id))
            payload = json.dumps(item.get("payload") or {})
            deleted = bool(item.get("deleted"))
            status = "accepted"
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
                existing_map[(collection, item_id)] = rec
                out.append(item)
            else:
                existing_ts = existing.updated_at
                if existing_ts.tzinfo is None:
                    existing_ts = existing_ts.replace(tzinfo=timezone.utc)
                if incoming_ts >= existing_ts:
                    existing.payload = payload
                    existing.updated_at = incoming_ts
                    existing.deleted = deleted
                    out.append(item)
                else:
                    status = "conflicted"
                    out.append(
                        {
                            "collection": existing.collection,
                            "item_id": existing.item_id,
                            "payload": json.loads(existing.payload),
                            "updated_at": existing.updated_at.isoformat(),
                            "deleted": existing.deleted,
                        }
                    )
            if op_id:
                db.add(SyncOperation(user_id=user_id, operation_id=op_id))
                seen_ops.add(op_id)
            results.append({"item_id": item_id, "status": status})
        except Exception:
            results.append(
                {
                    "item_id": str(item.get("item_id") or ""),
                    "status": "retryable",
                    "reason": "sync_error",
                }
            )
    db.commit()
    from ..observability.metrics import inc

    for row in results:
        status = row.get("status")
        if status == "conflicted":
            inc("sync_conflict")
        elif status == "accepted":
            inc("sync_ok")
        elif status == "retryable":
            inc("sync_fail")
    return out, results
