from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from .db.session import get_db
from .security import decode_token
from .services.auth_service import get_user


def current_user_id(authorization: str | None = Header(default=None)) -> int:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="missing_token")
    token = authorization.split(" ", 1)[1]
    sub = decode_token(token)
    if not sub:
        raise HTTPException(status_code=401, detail="invalid_token")
    return int(sub)


def current_user(user_id: int = Depends(current_user_id), db: Session = Depends(get_db)):
    user = get_user(db, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="user_gone")
    return user
