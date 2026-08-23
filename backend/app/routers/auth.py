from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr, Field

from ..core.deps import ApiError, current_user, store_dep
from ..core.responses import envelope
from ..core.security import create_access_token, hash_password, verify_password
from ..services.store import Store, UserRecord

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterBody(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(default="", max_length=80)


class LoginBody(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class ForgotBody(BaseModel):
    email: EmailStr


@router.post("/register")
def register(body: RegisterBody, store: Store = Depends(store_dep)):
    try:
        user = store.create_user(
            email=str(body.email),
            password_hash=hash_password(body.password),
            name=body.name,
        )
    except ValueError as exc:
        raise ApiError(str(exc), 409) from exc
    token = create_access_token(user.id)
    return envelope(
        {"user": user.public(), "accessToken": token, "tokenType": "bearer"},
        message="registered",
        status_code=201,
    )


@router.post("/login")
def login(body: LoginBody, store: Store = Depends(store_dep)):
    user = store.get_user_by_email(str(body.email))
    if user is None or not verify_password(body.password, user.password_hash):
        raise ApiError("Invalid email or password.", 401)
    token = create_access_token(user.id)
    return envelope(
        {"user": user.public(), "accessToken": token, "tokenType": "bearer"},
        message="logged_in",
    )


@router.post("/logout")
def logout(
    request: Request,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    store.revoke(getattr(request.state, "token_jti", ""))
    return envelope({"userId": user.id}, message="logged_out")


@router.post("/forgot-password")
def forgot_password(body: ForgotBody):
    return envelope(
        {"email": str(body.email).lower()},
        message="If that account exists, a reset path will be sent. No email is sent from this build.",
    )
