from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..db.session import get_db
from ..services.auth_service import AuthError, login, register

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterIn(BaseModel):
    email: str
    password: str
    name: str = ""


class LoginIn(BaseModel):
    email: str
    password: str


@router.post("/register")
def register_user(body: RegisterIn, db: Session = Depends(get_db)):
    if len(body.password) < 8:
        raise HTTPException(status_code=400, detail="password_too_short")
    try:
        user = register(db, body.email, body.password, body.name)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status, detail=str(exc)) from exc
    return {"id": user.id, "email": user.email, "name": user.name}


@router.post("/login")
def login_user(body: LoginIn, db: Session = Depends(get_db)):
    try:
        user, token = login(db, body.email, body.password)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status, detail=str(exc)) from exc
    return {"access_token": token, "token_type": "bearer", "user_id": user.id}


@router.post("/logout")
def logout():
    return {"ok": True}
