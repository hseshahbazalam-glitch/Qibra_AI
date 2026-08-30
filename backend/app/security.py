import base64
import hashlib
import hmac
import json
import os
import time

from .config import get_settings

PBKDF_ITERATIONS = 210_000


def hash_password(password: str, salt: bytes | None = None) -> str:
    salt = salt or os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF_ITERATIONS)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        salt_hex, digest_hex = stored.split("$", 1)
    except ValueError:
        return False
    salt = bytes.fromhex(salt_hex)
    expected = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF_ITERATIONS)
    return hmac.compare_digest(expected.hex(), digest_hex)


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def create_access_token(subject: str, minutes: int | None = None) -> str:
    settings = get_settings()
    exp = int(time.time()) + 60 * (minutes or settings.access_token_minutes)
    payload = {"sub": subject, "exp": exp}
    header = _b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    body = _b64url(json.dumps(payload).encode())
    signing = f"{header}.{body}".encode()
    sig = hmac.new(settings.jwt_secret.encode(), signing, hashlib.sha256).digest()
    return f"{header}.{body}.{_b64url(sig)}"


def hash_refresh_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def new_refresh_token() -> str:
    return os.urandom(32).hex()


def decode_token(token: str) -> str | None:
    settings = get_settings()
    try:
        header, body, sig = token.split(".")
        signing = f"{header}.{body}".encode()
        expected = _b64url(hmac.new(settings.jwt_secret.encode(), signing, hashlib.sha256).digest())
        if not hmac.compare_digest(expected, sig):
            return None
        payload = json.loads(_b64url_decode(body))
        if int(payload.get("exp", 0)) < int(time.time()):
            return None
        sub = payload.get("sub")
        return str(sub) if sub else None
    except Exception:
        return None
