"""Password hashing and access tokens.

Hand-rolled on purpose (stdlib only, no library migration this pass): PBKDF2-HMAC-SHA256
for passwords, an HMAC-SHA256 signed JWT-shaped token for access. What the QB-cluster
pass changed:

* the iteration count now TRAVELS INSIDE the hash string, so raising it later is a data
  migration and not a code break — verify honours what it reads (QB-017);
* a corrupt stored hash is a failed login (401), never a server error (500);
* access tokens carry ``iat`` and ``jti``.
"""

import base64
import hashlib
import hmac
import json
import os
import time
import uuid

from .config import get_settings

PBKDF2_ITERATIONS = 210_000
PBKDF2_ALGORITHM = "pbkdf2-sha256"
# A stored count outside this band is refused rather than honoured. The UPPER bound is
# the defensive one: an attacker who can write password_hash could otherwise turn every
# login into a CPU bomb with iterations=10**12. The lower bound only excludes degenerate
# values (0, negative, 1) — it is deliberately far below today's count, because historical
# rows must keep verifying. That is the entire point of storing the count.
PBKDF2_ITERATIONS_MIN = 1_000
PBKDF2_ITERATIONS_MAX = 5_000_000
# Upper bound on the password we are willing to stretch. PBKDF2 cost is linear in the
# input, so an unbounded field is a free CPU amplifier on the login path.
MAX_PASSWORD_CHARS = 1024
_SALT_BYTES = 16
_LEGACY_FIELDS = 2  # "salt$digest", written before the count was stored


def hash_password(password: str, salt: bytes | None = None, *, iterations: int | None = None) -> str:
    iterations = iterations or PBKDF2_ITERATIONS
    salt = salt or os.urandom(_SALT_BYTES)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt, iterations
    )
    return f"{PBKDF2_ALGORITHM}${iterations}${salt.hex()}${digest.hex()}"


def _split_stored(stored: str) -> tuple[int, bytes, str]:
    """(iterations, salt, expected_digest_hex) — raises on anything malformed."""
    parts = str(stored).split("$")
    if len(parts) == _LEGACY_FIELDS:
        salt_hex, digest_hex = parts
        iterations = PBKDF2_ITERATIONS
    elif len(parts) == 4 and parts[0] == PBKDF2_ALGORITHM:
        iterations = int(parts[1])
        salt_hex, digest_hex = parts[2], parts[3]
    else:
        raise ValueError("unrecognised password hash format")
    if not PBKDF2_ITERATIONS_MIN <= iterations <= PBKDF2_ITERATIONS_MAX:
        raise ValueError("password hash iteration count outside the allowed band")
    salt = bytes.fromhex(salt_hex)
    if len(salt) != _SALT_BYTES:
        raise ValueError("password hash salt has the wrong length")
    if not digest_hex:
        raise ValueError("password hash is missing its digest")
    return iterations, salt, digest_hex


def verify_password(password: str, stored: str) -> bool:
    """Fail closed. A damaged or hostile row must read as "wrong password" (401),
    never as a 500 — so EVERY parse step, bytes.fromhex included, is inside the try."""
    try:
        iterations, salt, digest_hex = _split_stored(stored)
        expected = hashlib.pbkdf2_hmac(
            "sha256", password.encode("utf-8"), salt, iterations
        )
        return hmac.compare_digest(expected.hex(), digest_hex)
    except Exception:
        return False


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def create_access_token(subject: str, minutes: int | None = None) -> str:
    settings = get_settings()
    now = int(time.time())
    exp = now + 60 * (minutes or settings.access_token_minutes)
    payload = {
        "sub": subject,
        "exp": exp,
        "iat": now,
        "jti": uuid.uuid4().hex,
    }
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
        # The header is checked, not ignored: a token that claims a different
        # algorithm is refused even though the signature below would not verify.
        claims = json.loads(_b64url_decode(header))
        if not isinstance(claims, dict):
            return None
        if claims.get("alg") != "HS256" or claims.get("typ") != "JWT":
            return None
        signing = f"{header}.{body}".encode()
        expected = _b64url(
            hmac.new(settings.jwt_secret.encode(), signing, hashlib.sha256).digest()
        )
        if not hmac.compare_digest(expected, sig):
            return None
        payload = json.loads(_b64url_decode(body))
        if not isinstance(payload, dict):
            return None
        if int(payload.get("exp", 0)) < int(time.time()):
            return None
        # iat / jti are written by create_access_token and deliberately NOT required
        # here: tokens already in flight when this ships stay valid for their remaining
        # <=15 minutes, which is the whole point of a short-lived access token.
        sub = payload.get("sub")
        return str(sub) if sub else None
    except Exception:
        return None
