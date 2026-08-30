from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..db.models import User
from ..db.session import get_db
from ..deps import current_user
from ..services.sync_service import merge_records

router = APIRouter(prefix="/sync", tags=["sync"])


class SyncItem(BaseModel):
    collection: str
    item_id: str
    payload: dict = {}
    updated_at: str
    deleted: bool = False


class SyncIn(BaseModel):
    items: list[SyncItem]


@router.post("")
def sync(body: SyncIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    if len(body.items) > 500:
        raise HTTPException(status_code=400, detail="sync_batch_too_large")
    merged = merge_records(db, user.id, [i.model_dump() for i in body.items])
    return {"items": merged}
