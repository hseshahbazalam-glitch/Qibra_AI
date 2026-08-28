"""Phase 4 — auth + hashed passwords + user record."""

from helpers import bearer, fresh_client, login, register
from app.security import create_access_token, decode_token, hash_password, verify_password


def test_password_is_hashed_not_plaintext():
    stored = hash_password("password1")
    assert "password1" not in stored
    assert "$" in stored
    assert verify_password("password1", stored)
    assert not verify_password("nope", stored)


def test_hash_uses_unique_salt():
    a = hash_password("password1")
    b = hash_password("password1")
    assert a != b


def test_register_login_me():
    with fresh_client() as client:
        r = register(client)
        assert r.status_code == 200
        assert r.json()["email"] == "user@example.com"
        token = login(client).json()["access_token"]
        me = client.get("/users/me", headers={"Authorization": f"Bearer {token}"})
        assert me.status_code == 200
        assert me.json()["email"] == "user@example.com"
        assert me.json()["is_premium"] is False


def test_register_rejects_short_password():
    with fresh_client() as client:
        r = register(client, password="short")
        assert r.status_code == 400
        assert r.json()["detail"] == "password_too_short"


def test_duplicate_email_conflict():
    with fresh_client() as client:
        assert register(client).status_code == 200
        again = register(client)
        assert again.status_code == 409


def test_login_rejects_bad_password():
    with fresh_client() as client:
        register(client)
        bad = login(client, password="wrongpass")
        assert bad.status_code == 401


def test_login_unknown_email():
    with fresh_client() as client:
        r = login(client, email="missing@example.com")
        assert r.status_code == 401


def test_email_is_normalized_lowercase():
    with fresh_client() as client:
        register(client, email="User@Example.COM")
        token = login(client, email="user@example.com").json()["access_token"]
        me = client.get("/users/me", headers={"Authorization": f"Bearer {token}"})
        assert me.json()["email"] == "user@example.com"


def test_me_requires_bearer():
    with fresh_client() as client:
        assert client.get("/users/me").status_code == 401
        assert client.get("/users/me", headers={"Authorization": "Bearer nope"}).status_code == 401


def test_jwt_roundtrip_and_garbage():
    token = create_access_token("42")
    assert decode_token(token) == "42"
    assert decode_token("not-a-jwt") is None
    assert decode_token("") is None


def test_me_never_trusts_premium_from_client():
    with fresh_client() as client:
        headers = bearer(client)
        me = client.get("/users/me", headers=headers).json()
        assert me["is_premium"] is False
