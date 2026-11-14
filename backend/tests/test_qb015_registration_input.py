"""QB-015 — registration validates its input instead of storing whatever arrives.

Red first: at 9aedc87 `RegisterIn` is three bare `str` fields, so `""` is accepted as an
email, ` User@Example.COM ` is stored verbatim (and can coexist with the lowercase row),
and there is no bound on email, name or password length.
"""

from helpers import fresh_client, login, register

LONG_NAME = "n" * 200
BAD_EMAILS = ("", "   ", "not-an-email", "a@b@c.com", "sp ace@e.com", "@e.com", "a@")


def _post(client, **body):
    return client.post("/auth/register", json={"password": "password1", **body})


def test_empty_email_is_rejected_not_stored():
    with fresh_client() as client:
        for value in BAD_EMAILS:
            r = _post(client, email=value)
            assert r.status_code == 422, (value, r.status_code, r.text)


def test_email_is_trimmed_and_lowercased_on_the_way_in():
    with fresh_client() as client:
        r = _post(client, email="  User@Example.COM  ", name="Ali")
        assert r.status_code == 200, r.text
        assert r.json()["email"] == "user@example.com"
        # the stored row is the canonical form, so either spelling signs in
        assert login(client, email="user@example.com").status_code == 200
        assert login(client, email="  USER@example.com ").status_code == 200


def test_case_difference_cannot_create_a_second_account():
    with fresh_client() as client:
        assert _post(client, email="dup@e.com").status_code == 200
        again = _post(client, email="  DUP@e.com  ")
        assert again.status_code == 409
        assert again.json()["detail"] == "email_taken"


def test_email_and_name_are_length_capped():
    with fresh_client() as client:
        absurd_email = "a" * 60 + "@" + ".".join(["b" * 60] * 5 + ["com"])
        assert len(absurd_email) > 255
        assert _post(client, email=absurd_email).status_code == 422
        assert _post(client, email="cap@e.com", name=LONG_NAME).status_code == 422
        assert _post(client, email="cap2@e.com", name="n" * 120).status_code == 200
        assert _post(client, email="cap3@e.com", name="n" * 121).status_code == 422


def test_the_declared_caps_are_exactly_255_and_120():
    """Pinned on the model, because email-validator has its own (differently shaped)
    limits — the field cap is what QB-015 asked for and must be the smaller authority."""
    from pydantic.fields import FieldInfo

    from app.routers.auth import RegisterIn

    def cap(field: FieldInfo) -> int | None:
        # read the constraint, not its class name — pydantic has renamed these before
        for meta in field.metadata:
            value = getattr(meta, "max_length", None)
            if value is not None:
                return int(value)
        return None

    assert cap(RegisterIn.model_fields["email"]) == 255
    assert cap(RegisterIn.model_fields["name"]) == 120


def test_registration_never_returns_500_on_any_garbage():
    with fresh_client() as client:
        for value in ("a" * 5000, "\x00binary", "🕌@🕌.com", "x@y.z\nInjection", None, 12345, ["a"]):
            r = _post(client, email=value)
            assert r.status_code in (200, 400, 409, 422), (value, r.status_code, r.text)


def test_password_has_an_upper_bound_so_hashing_cannot_be_used_as_dos():
    from app.security import MAX_PASSWORD_CHARS

    with fresh_client() as client:
        assert (
            client.post(
                "/auth/register",
                json={"email": "long@e.com", "password": "p" * (MAX_PASSWORD_CHARS + 1)},
            ).status_code
            == 422
        )
        assert (
            client.post(
                "/auth/register",
                json={"email": "long@e.com", "password": "p" * MAX_PASSWORD_CHARS},
            ).status_code
            == 200
        )
        assert (
            login(
                client,
                email="long@e.com",
                password="p" * (MAX_PASSWORD_CHARS + 1),
            ).status_code
            == 422
        )


def test_login_normalises_without_rejecting_legacy_shapes():
    """Login trims and bounds, but does NOT apply the registration syntax rules —
    a row stored before this pass must still be able to sign in."""
    with fresh_client() as client:
        client.post(
            "/auth/register", json={"email": "legacy@e.com", "password": "password1"}
        )
        assert login(client, email="\tlegacy@e.com\n").status_code == 200
        assert login(client, email="x" * 300 + "@e.com").status_code == 422
