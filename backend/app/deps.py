from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from .db.session import get_db
from .security import decode_token
from .services.auth_service import get_user


def bearer_subject(authorization: str | None) -> tuple[str | None, str | None]:
    """(subject, error) — the one place the Authorization header is parsed.

    `error` is the stable code: missing_token (nothing usable was sent) versus
    invalid_token (something was sent and it does not verify). Endpoints that need a
    different wording depend on this helper instead of re-reading the header, so the
    parsing rules cannot drift between them.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        return None, "missing_token"
    sub = decode_token(authorization.split(" ", 1)[1])
    if not sub:
        return None, "invalid_token"
    return sub, None


def current_user_id(authorization: str | None = Header(default=None)) -> int:
    sub, error = bearer_subject(authorization)
    if error:
        raise HTTPException(status_code=401, detail=error)
    return int(sub)


def current_user(user_id: int = Depends(current_user_id), db: Session = Depends(get_db)):
    user = get_user(db, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="user_gone")
    return user
