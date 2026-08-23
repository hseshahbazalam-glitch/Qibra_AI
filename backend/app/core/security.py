from datetime import datetime, timedelta, timezone
from hashlib import sha256
from hmac import compare_digest
from uuid import uuid4

from jose import JWTError, jwt

from .config import get_settings


def hash_password(password: str) -> str:
    secret = get_settings().secret_key
    return sha256(f"{secret}:{password}".encode("utf-8")).hexdigest()


def verify_password(password: str, hashed: str) -> bool:
    return compare_digest(hash_password(password), hashed)


def create_access_token(user_id: str) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "jti": uuid4().hex,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.token_minutes)).timestamp()),
    }
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")


def decode_access_token(token: str) -> dict | None:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    except JWTError:
        return None
