from base64 import b64decode, b64encode
from datetime import datetime, timedelta, timezone
from hashlib import pbkdf2_hmac, sha256
from hmac import compare_digest
from secrets import token_bytes
from uuid import uuid4

from jose import JWTError, jwt

from .config import get_settings

_PBKDF2_ITERATIONS = 310_000


def _legacy_hash(password: str) -> str:
    secret = get_settings().secret_key
    return sha256(f"{secret}:{password}".encode("utf-8")).hexdigest()


def hash_password(password: str) -> str:
    """Return a versioned, salted PBKDF2 hash; never log passwords or hashes."""
    salt = token_bytes(16)
    digest = pbkdf2_hmac("sha256", password.encode("utf-8"), salt, _PBKDF2_ITERATIONS)
    return "pbkdf2_sha256${}${}${}".format(
        _PBKDF2_ITERATIONS,
        b64encode(salt).decode("ascii"),
        b64encode(digest).decode("ascii"),
    )


def verify_password(password: str, hashed: str) -> bool:
    # Existing Phase 15 in-memory records may use the old digest. Verifying it
    # preserves login compatibility; all newly registered accounts use PBKDF2.
    if not hashed.startswith("pbkdf2_sha256$"):
        return compare_digest(_legacy_hash(password), hashed)
    try:
        _, iterations, salt, expected = hashed.split("$", 3)
        actual = pbkdf2_hmac(
            "sha256", password.encode("utf-8"), b64decode(salt), int(iterations)
        )
        return compare_digest(actual, b64decode(expected))
    except (ValueError, TypeError):
        return False


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
