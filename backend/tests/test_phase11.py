"""Phase 11 — observability consent default OFF."""

from app.observability.local import Observability


def test_consent_default_off():
    obs = Observability()
    assert obs.consent is False
    obs.record("opened_home")
    assert obs.events == []
    obs.consent = True
    obs.record("opened_home")
    assert obs.events == ["opened_home"]
    obs.record("email_leaked")
    assert "email_leaked" not in obs.events
