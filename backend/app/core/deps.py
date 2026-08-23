"""Request dependencies shared across routers."""

from __future__ import annotations

from typing import Any

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.responses import ApiError
from app.core.security import decode_access_token
from app.services.user_store import UserRecord, UserStore, get_user_store

_bearer = HTTPBearer(auto_error=False)


def require_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    store: UserStore = Depends(get_user_store),
) -> UserRecord:
    if credentials is None or not credentials.credentials:
        raise ApiError("Authentication required", status_code=401)
    try:
        payload = decode_access_token(credentials.credentials)
    except ValueError as exc:
        raise ApiError(str(exc), status_code=401) from exc

    if store.is_token_revoked(credentials.credentials):
        raise ApiError("Session has been signed out", status_code=401)

    user = store.get_user(str(payload["sub"]))
    if user is None or user.deleted:
        raise ApiError("Account not found", status_code=401)
    request.state.access_token = credentials.credentials
    request.state.token_payload = payload
    return user


def optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    store: UserStore = Depends(get_user_store),
) -> UserRecord | None:
    if credentials is None or not credentials.credentials:
        return None
    try:
        payload = decode_access_token(credentials.credentials)
    except ValueError:
        return None
    if store.is_token_revoked(credentials.credentials):
        return None
    user = store.get_user(str(payload["sub"]))
    if user is None or user.deleted:
        return None
    return user


def current_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> str | None:
    if credentials is None:
        return None
    return credentials.credentials


def token_payload_or_none(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict[str, Any] | None:
    if credentials is None or not credentials.credentials:
        return None
    try:
        return decode_access_token(credentials.credentials)
    except ValueError:
        return None
