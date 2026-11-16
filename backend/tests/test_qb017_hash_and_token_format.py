"""QB-017 (scoped) — a corrupt credential fails closed as 401, the iteration count
travels inside the hash string, and access tokens carry iat + jti.

Red first: at 9aedc87 `verify_password` runs `bytes.fromhex()` OUTSIDE its try block, a
malformed `password_hash` therefore raises ValueError and the request becomes a 500; the
stored hash is `salt$digest` with no iteration count, so raising the count later is a
breaking code change; and `create_access_token` emits only `sub` + `exp`.
"""

import base64
import json
import time

import pytest
from sqlalchemy import select

from app.db import session as db_session
from app.db.models import User
from app.security import (
    PBKDF2_ITERATIONS,
    create_access_token,
    decode_token,
    hash_password,
    verify_password,
)
from helpers import fresh_client, login, register


def _set_hash(email: str, value: str) -> None:
    # through the module attribute: fresh_client() rebinds SessionLocal to the test
    # engine, and a name imported at module level would keep the pre-reset binding
    db = db_session.SessionLocal()
    try:
        row = db.scalar(select(User).where(User.email == email))
        row.password_hash = value
        db.commit()
    finally:
        db.close()


# ── malformed hash → 401, never 500 ───────────────────────────────────
@pytest.mark.parametrize(
    "stored",
    ["not-hex$zz", "$", "$$", "nopal", "pbkdf2-sha256$notanumber$00ff$00",
     "pbkdf2-sha256$99$zz$00", "salt$not-hex-either", "", "x$" + "z" * 64],
)
def test_malformed_stored_hash_never_becomes_a_500(stored):
    with fresh_client() as client:
        register(client, email="broken@e.com")
        _set_hash("broken@e.com", stored)
        r = login(client, email="broken@e.com")
        assert r.status_code == 401, (stored, r.status_code, r.text)
        assert r.json()["detail"] == "invalid_credentials"


# ── iteration count stored in the hash string ─────────────────────────
def test_hash_string_carries_the_iteration_count():
    stored = hash_password("password1")
    parts = stored.split("$")
    assert parts[0] == "pbkdf2-sha256"
    assert int(parts[1]) == PBKDF2_ITERATIONS
    assert len(parts) == 4
    assert verify_password("password1", stored)
    assert not verify_password("nope", stored)


def test_verify_honours_the_count_it_reads_not_the_current_default():
    """A future raise of PBKDF2_ITERATIONS is a data migration, not a code break:
    an old row with an old count still verifies."""
    old = hash_password("password1", iterations=60_000)
    new = hash_password("password1", iterations=PBKDF2_ITERATIONS)
    assert old != new
    assert verify_password("password1", old)
    assert verify_password("password1", new)
    assert not verify_password("wrong", old)


def test_absurd_or_downgraded_iteration_counts_fail_closed():
    for stored in (
        "pbkdf2-sha256$1$" + "00" * 16 + "$" + "00" * 32,
        "pbkdf2-sha256$0$" + "00" * 16 + "$" + "00" * 32,
        "pbkdf2-sha256$-5$" + "00" * 16 + "$" + "00" * 32,
        "pbkdf2-sha256$" + "9" * 12 + "$" + "00" * 16 + "$" + "00" * 32,
        "pbkdf2-sha256$nan$" + "00" * 16 + "$" + "00" * 32,
    ):
        assert verify_password("password1", stored) is False
    # 5 fields is not a format this code writes or reads
    assert verify_password("password1", "pbkdf2-sha256$1000$00$00$extra") is False


def test_legacy_two_field_hash_still_verifies():
    """Rows written before this pass must keep signing people in."""
    import hashlib
    import hmac
    import os

    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", b"password1", salt, PBKDF2_ITERATIONS)
    legacy = f"{salt.hex()}${digest.hex()}"
    assert verify_password("password1", legacy)
    assert not verify_password("nope", legacy)


def test_new_hash_fits_the_column_and_hides_the_password():
    stored = hash_password("correct horse battery staple !@#$%")
    assert "correct horse" not in stored
    assert len(stored) <= 255


# ── tokens: iat + jti ──────────────────────────────────────────────────
def _payload(token: str) -> dict:
    _h, body, _s = token.split(".")
    return json.loads(base64.urlsafe_b64decode(body + "=" * (-len(body) % 4)))


def _header(token: str) -> dict:
    head, _b, _s = token.split(".")
    return json.loads(base64.urlsafe_b64decode(head + "=" * (-len(head) % 4)))


def test_access_token_carries_iat_and_jti():
    token = create_access_token("42")
    payload = _payload(token)
    assert payload["sub"] == "42"
    assert isinstance(payload["iat"], int)
    assert abs(payload["iat"] - int(time.time())) <= 5
    assert isinstance(payload["jti"], str) and len(payload["jti"]) >= 16
    assert _header(token) == {"alg": "HS256", "typ": "JWT"}


def test_jti_differs_per_token_and_exp_still_governs():
    a, b = create_access_token("7"), create_access_token("7")
    assert _payload(a)["jti"] != _payload(b)["jti"]
    assert decode_token(a) == "7"
    expired = create_access_token("7", minutes=-1)
    assert decode_token(expired) is None


def test_foreign_and_unsigned_tokens_are_rejected():
    token = create_access_token("7")
    head, body, _sig = token.split(".")
    # alg=none with the signature dropped
    none_head = base64.urlsafe_b64encode(
        json.dumps({"alg": "none", "typ": "JWT"}).encode()
    ).rstrip(b"=").decode()
    assert decode_token(f"{none_head}.{body}.") is None
    # a token signed with another secret
    other = create_access_token("7")
    assert decode_token(f"{head}.{other.split('.')[1]}.{token.split('.')[2]}") is None
    assert decode_token("garbage") is None
    assert decode_token("") is None


def test_older_token_shape_without_iat_still_decodes():
    """Rollout safety: tokens already in flight when this ships keep working for their
    remaining <=15 minutes, because iat/jti are written and never required."""
    import hashlib
    import hmac

    from app.config import get_settings

    def b64(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

    body = b64(json.dumps({"sub": "9", "exp": int(time.time()) + 300}).encode())
    head = b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    sig = b64(
        hmac.new(get_settings().jwt_secret.encode(), f"{head}.{body}".encode(), hashlib.sha256).digest()
    )
    assert decode_token(f"{head}.{body}.{sig}") == "9"
