from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..db.models import User
from ..db.session import get_db
from ..deps import current_user
from ..services.auth_service import (
    AuthError,
    list_sessions,
    login,
    logout_all,
    register,
    revoke_refresh,
    revoke_session,
    rotate_refresh,
)

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterIn(BaseModel):
    email: str
    password: str
    name: str = ""


class LoginIn(BaseModel):
    email: str
    password: str
    device_id: str = ""
    platform: str = ""
    app_version: str = ""


class RefreshIn(BaseModel):
    refresh_token: str


def _auth_error(exc: AuthError) -> HTTPException:
    return HTTPException(status_code=exc.status, detail=str(exc))


@router.post("/register")
def register_user(body: RegisterIn, db: Session = Depends(get_db)):
    if len(body.password) < 8:
        raise HTTPException(status_code=400, detail="password_too_short")
    try:
        user = register(db, body.email, body.password, body.name)
    except AuthError as exc:
        raise _auth_error(exc) from exc
    return {"id": user.id, "email": user.email, "name": user.name}


@router.post("/login")
def login_user(body: LoginIn, db: Session = Depends(get_db)):
    try:
        user, access, refresh = login(
            db,
            body.email,
            body.password,
            device_id=body.device_id,
            platform=body.platform,
            app_version=body.app_version,
        )
    except AuthError as exc:
        raise _auth_error(exc) from exc
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "user_id": user.id,
    }


@router.post("/refresh")
def refresh_tokens(body: RefreshIn, db: Session = Depends(get_db)):
    try:
        user, access, refresh = rotate_refresh(db, body.refresh_token)
    except AuthError as exc:
        raise _auth_error(exc) from exc
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "user_id": user.id,
    }


@router.post("/logout")
async def logout(request: Request, db: Session = Depends(get_db)):
    token = None
    try:
        ctype = request.headers.get("content-type", "")
        if "application/json" in ctype:
            data = await request.json()
            if isinstance(data, dict):
                token = data.get("refresh_token")
    except Exception:
        token = None
    if token:
        revoke_refresh(db, str(token))
    return {"ok": True}


@router.post("/logout-all")
def logout_all_sessions(user: User = Depends(current_user), db: Session = Depends(get_db)):
    logout_all(db, user.id)
    return {"ok": True}


@router.get("/me")
def auth_me(user: User = Depends(current_user)):
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "is_premium": False,
        "preferred_locale": user.preferred_locale,
        "timezone": user.timezone,
    }


@router.get("/sessions")
def sessions(user: User = Depends(current_user), db: Session = Depends(get_db)):
    rows = list_sessions(db, user.id)
    return [
        {
            "id": s.id,
            "device_id": s.device_id,
            "platform": s.platform,
            "app_version": s.app_version,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "last_seen_at": s.last_seen_at.isoformat() if s.last_seen_at else None,
            "revoked": s.revoked_at is not None,
        }
        for s in rows
    ]


@router.delete("/sessions/{session_id}")
def delete_session(
    session_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)
):
    ok = revoke_session(db, user.id, session_id)
    if not ok:
        raise HTTPException(status_code=404, detail="not_found")
    return {"ok": True}
