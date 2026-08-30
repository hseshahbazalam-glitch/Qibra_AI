import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import Bookmark, User
from ..db.session import get_db
from ..deps import current_user

router = APIRouter(prefix="/bookmarks", tags=["bookmarks"])


class BookmarkIn(BaseModel):
    collection: str
    item_id: str
    payload: dict = {}


@router.get("")
def list_bookmarks(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    limit = min(max(limit, 1), 500)
    offset = max(offset, 0)
    rows = db.scalars(
        select(Bookmark).where(Bookmark.user_id == user.id).offset(offset).limit(limit)
    ).all()
    return [
        {
            "collection": r.collection,
            "item_id": r.item_id,
            "payload": json.loads(r.payload),
        }
        for r in rows
    ]


@router.post("")
def upsert_bookmark(body: BookmarkIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    existing = db.scalar(
        select(Bookmark).where(
            Bookmark.user_id == user.id,
            Bookmark.collection == body.collection,
            Bookmark.item_id == body.item_id,
        )
    )
    if existing:
        existing.payload = json.dumps(body.payload)
        existing.updated_at = datetime.now(timezone.utc)
    else:
        db.add(
            Bookmark(
                user_id=user.id,
                collection=body.collection,
                item_id=body.item_id,
                payload=json.dumps(body.payload),
            )
        )
    db.commit()
    return {"ok": True}


@router.delete("")
def delete_bookmark(collection: str, item_id: str, user: User = Depends(current_user), db: Session = Depends(get_db)):
    existing = db.scalar(
        select(Bookmark).where(
            Bookmark.user_id == user.id,
            Bookmark.collection == collection,
            Bookmark.item_id == item_id,
        )
    )
    if existing:
        db.delete(existing)
        db.commit()
    return {"ok": True}
