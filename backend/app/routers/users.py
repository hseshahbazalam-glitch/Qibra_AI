from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..db.models import User
from ..db.session import get_db
from ..deps import current_user

router = APIRouter(prefix="/users", tags=["users"])

_ALLOWED_LOCALES = {"en", "ar", "ur"}


class ProfilePatch(BaseModel):
    name: str | None = None
    preferred_locale: str | None = None
    timezone: str | None = None


def _public_user(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "is_premium": False,
        "preferred_locale": user.preferred_locale,
        "timezone": user.timezone,
    }


@router.get("/me")
def me(user: User = Depends(current_user)):
    return _public_user(user)


@router.patch("/me")
def patch_me(body: ProfilePatch, user: User = Depends(current_user), db: Session = Depends(get_db)):
    if body.name is not None:
        user.name = body.name[:120]
    if body.preferred_locale is not None:
        if body.preferred_locale not in _ALLOWED_LOCALES:
            raise HTTPException(status_code=400, detail="locale_unsupported")
        user.preferred_locale = body.preferred_locale
    if body.timezone is not None:
        user.timezone = body.timezone[:64]
    user.updated_at = datetime.now(timezone.utc)
    db.commit()
    return _public_user(user)


@router.delete("/me")
def delete_me(user: User = Depends(current_user), db: Session = Depends(get_db)):
    from ..services.auth_service import logout_all

    logout_all(db, user.id)
    user.deleted_at = datetime.now(timezone.utc)
    db.commit()
    return {"ok": True, "deleted": True}
