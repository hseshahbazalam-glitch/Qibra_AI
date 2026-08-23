from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from ..services.store import Store, UserRecord, get_store
from .security import decode_access_token


class ApiError(Exception):
    def __init__(self, message: str, status_code: int = 400, data=None):
        self.message = message
        self.status_code = status_code
        self.data = data
        super().__init__(message)


bearer = HTTPBearer(auto_error=False)


def store_dep() -> Store:
    return get_store()


def current_user(
    request: Request,
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    store: Store = Depends(store_dep),
) -> UserRecord:
    token = creds.credentials if creds else None
    if not token:
        raise ApiError("Authentication required.", 401)
    payload = decode_access_token(token)
    if not payload:
        raise ApiError("Invalid or expired token.", 401)
    if store.is_revoked(str(payload.get("jti", ""))):
        raise ApiError("Session expired.", 401)
    user = store.get_user(str(payload.get("sub", "")))
    if user is None:
        raise ApiError("User not found.", 401)
    request.state.token_jti = payload.get("jti")
    return user
