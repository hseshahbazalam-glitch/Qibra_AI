from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db.models import User, UserSetting
from ..db.session import get_db
from ..deps import current_user

router = APIRouter(prefix="/settings", tags=["settings"])


class SettingIn(BaseModel):
    key: str
    value: str


@router.get("")
def list_settings(user: User = Depends(current_user), db: Session = Depends(get_db)):
    rows = db.scalars(select(UserSetting).where(UserSetting.user_id == user.id)).all()
    return {r.key: r.value for r in rows}


@router.post("")
def put_setting(body: SettingIn, user: User = Depends(current_user), db: Session = Depends(get_db)):
    existing = db.scalar(
        select(UserSetting).where(UserSetting.user_id == user.id, UserSetting.key == body.key)
    )
    if existing:
        existing.value = body.value
    else:
        db.add(UserSetting(user_id=user.id, key=body.key, value=body.value))
    db.commit()
    return {"ok": True}
