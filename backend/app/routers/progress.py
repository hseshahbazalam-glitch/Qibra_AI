from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import Progress, User
from ..db.session import get_db
from ..deps import current_user
import json

router = APIRouter(prefix="/progress", tags=["progress"])


class ProgressIn(BaseModel):
    kind: str
    payload: dict = {}


@router.get("")
def list_progress(user: User = Depends(current_user), db: Session = Depends(get_db)):
    rows = db.scalars(select(Progress).where(Progress.user_id == user.id)).all()
    return [{"kind": r.kind, "payload": json.loads(r.payload)} for r in rows]


@router.post("")
def put_progress(body: ProgressIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    existing = db.scalar(
        select(Progress).where(Progress.user_id == user.id, Progress.kind == body.kind)
    )
    now = datetime.now(timezone.utc)
    if existing:
        existing.payload = json.dumps(body.payload)
        existing.updated_at = now
    else:
        db.add(
            Progress(
                user_id=user.id,
                kind=body.kind,
                payload=json.dumps(body.payload),
                updated_at=now,
            )
        )
    db.commit()
    return {"ok": True}
