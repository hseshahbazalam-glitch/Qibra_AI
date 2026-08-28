from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..db.models import User
from ..db.session import get_db
from ..deps import current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me")
def me(user: User = Depends(current_user)):
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "is_premium": False,
    }


@router.delete("/me")
def delete_me(user: User = Depends(current_user), db: Session = Depends(get_db)):
    user.deleted_at = datetime.now(timezone.utc)
    db.commit()
    return {"ok": True, "deleted": True}
