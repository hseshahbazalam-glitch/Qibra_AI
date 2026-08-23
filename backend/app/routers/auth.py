"""AUTH endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field

from app.core.deps import current_token
from app.core.responses import ApiError, success_response
from app.core.security import create_access_token
from app.core.validation import require_email, require_name, require_password
from app.services.user_store import UserStore, get_user_store

router = APIRouter(tags=["auth"])


class LoginBody(BaseModel):
    email: str
    password: str


class RegisterBody(BaseModel):
    email: str
    password: str
    name: str = Field(min_length=1)


class ForgotPasswordBody(BaseModel):
    email: str


@router.post("/auth/login")
def login(body: LoginBody, request: Request, store: UserStore = Depends(get_user_store)):
    email = require_email(body.email)
    password = require_password(body.password)
    user = store.authenticate(email, password)
    if user is None:
        raise ApiError("Invalid email or password", status_code=401)
    token = create_access_token(user.id, extra={"email": user.email})
    return success_response(
        {
            "user": user.public_dict(),
            "token": token,
            "access_token": token,
            "token_type": "bearer",
        },
        message="Signed in",
        request=request,
    )


@router.post("/auth/register")
def register(body: RegisterBody, request: Request, store: UserStore = Depends(get_user_store)):
    email = require_email(body.email)
    password = require_password(body.password)
    name = require_name(body.name)
    if store.get_by_email(email) is not None:
        raise ApiError("An account with this email already exists", status_code=409)
    user = store.create_user(email=email, password=password, name=name)
    token = create_access_token(user.id, extra={"email": user.email})
    return success_response(
        {
            "user": user.public_dict(),
            "token": token,
            "access_token": token,
            "token_type": "bearer",
        },
        message="Account created",
        status_code=201,
        request=request,
    )


@router.post("/auth/logout")
def logout(
    request: Request,
    token: str | None = Depends(current_token),
    store: UserStore = Depends(get_user_store),
):
    if token:
        store.revoke_token(token)
    return success_response({"logged_out": True}, message="Signed out", request=request)


@router.post("/auth/forgot-password")
def forgot_password(
    body: ForgotPasswordBody,
    request: Request,
    store: UserStore = Depends(get_user_store),
):
    email = require_email(body.email)
    store.create_reset_token(email)
    return success_response(
        {"accepted": True},
        message="If an account exists for that email, a reset link will be sent.",
        request=request,
    )
