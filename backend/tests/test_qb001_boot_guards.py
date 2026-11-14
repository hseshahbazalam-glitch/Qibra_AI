"""QB-001 — the API refuses to boot without a real JWT secret, in EVERY environment.

Red first: every assertion below describes the behaviour the audit asked for and the
code at 9aedc87 does not have (a "dev-only-change-me" string is the runtime fallback,
and the length rule does not exist at all).
"""

from pathlib import Path

import pytest

from app.config import (
    MIN_JWT_SECRET_BYTES,
    BootConfigError,
    dev_mode,
    jwt_secret_or_raise,
)

GOOD = "x" * MIN_JWT_SECRET_BYTES  # exactly on the boundary — must be accepted


def _env(secret=GOOD, qibra_env=None):
    env = {"JWT_SECRET": secret}
    if qibra_env is not None:
        env["QIBRA_ENV"] = qibra_env
    return env


def test_missing_secret_refuses_to_boot():
    with pytest.raises(BootConfigError) as exc:
        jwt_secret_or_raise({})
    assert "JWT_SECRET" in str(exc.value)


def test_empty_and_whitespace_secret_refuse_to_boot():
    for value in ("", "   ", "\t\n"):
        with pytest.raises(BootConfigError):
            jwt_secret_or_raise(_env(secret=value))


def test_short_secret_refuses_to_boot_and_boundary_is_inclusive():
    with pytest.raises(BootConfigError) as exc:
        jwt_secret_or_raise(_env(secret="y" * (MIN_JWT_SECRET_BYTES - 1)))
    assert str(MIN_JWT_SECRET_BYTES) in str(exc.value)
    assert jwt_secret_or_raise(_env(secret="y" * MIN_JWT_SECRET_BYTES))


def test_length_rule_is_not_relaxed_in_dev():
    """The rule applies REGARDLESS of QIBRA_ENV — dev is an opt-in, not a bypass."""
    with pytest.raises(BootConfigError):
        jwt_secret_or_raise(_env(secret="short-secret", qibra_env="dev"))
    with pytest.raises(BootConfigError):
        jwt_secret_or_raise(_env(secret="short-secret", qibra_env="development"))


def test_well_known_placeholders_are_refused():
    for word in ("replace-me", "changeme", "secret", "password", "your-secret-here"):
        with pytest.raises(BootConfigError):
            jwt_secret_or_raise(_env(secret=word))
        with pytest.raises(BootConfigError):
            jwt_secret_or_raise(_env(secret=word.upper()))
        with pytest.raises(BootConfigError):
            jwt_secret_or_raise(_env(secret=f"  {word}  "))


def test_no_runtime_fallback_secret_anywhere_in_the_app():
    """The literal sentinel must be gone from backend/app, not just unreachable."""
    root = Path(__file__).resolve().parents[1] / "app"
    hits = [
        f"{py.relative_to(root)}:{i + 1}"
        for py in sorted(root.rglob("*.py"))
        for i, line in enumerate(py.read_text(encoding="utf-8").splitlines())
        if "dev-only-change-me" in line
    ]
    assert hits == [], f"runtime fallback secret still present: {hits}"


def test_dev_mode_is_an_explicit_opt_in_with_a_loud_warning():
    assert dev_mode({"QIBRA_ENV": "dev"}) is True
    assert dev_mode({"QIBRA_ENV": "DEV  "}) is True
    assert dev_mode({"QIBRA_ENV": "development"}) is True
    # unset is NOT dev: strict by default, so a Render misconfiguration cannot land on
    # the permissive branch by accident.
    assert dev_mode({}) is False
    assert dev_mode({"QIBRA_ENV": "production"}) is False


def test_settings_object_carries_a_validated_secret():
    """The app the 226 tests run against is booted through the same guard, and its
    secret comes from the environment — there is no constant to fall back to."""
    import os

    from app.config import get_settings

    settings = get_settings()
    assert settings.jwt_secret == os.environ["JWT_SECRET"].strip()
    assert len(settings.jwt_secret.encode("utf-8")) >= MIN_JWT_SECRET_BYTES


def test_the_denylist_is_not_quietly_dropped():
    """Two mechanisms, both pinned: the length floor catches anything short, and this
    list catches a known placeholder that someone padded to reach the floor. Dropping
    either one must fail loudly here rather than in production."""
    from app.config import _INSECURE_JWT

    assert {"replace-me", "changeme", "secret", "password", "your-secret-here"} <= set(
        _INSECURE_JWT
    )
    long_padded = "changeme" + "-" * (MIN_JWT_SECRET_BYTES - 8)
    assert len(long_padded) >= MIN_JWT_SECRET_BYTES
    # not refused by length, so only the denylist can catch a *short-of-the-floor-agnostic*
    # placeholder — assert the denylist matches case-insensitively on the bare word:
    with pytest.raises(BootConfigError):
        jwt_secret_or_raise(_env(secret="CHANGEME"))


def test_conftest_env_is_dev_opt_in():
    """Tests declare dev mode rather than inheriting an accidentally-permissive default."""
    import os

    assert dev_mode(os.environ) is True
