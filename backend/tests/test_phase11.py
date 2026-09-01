"""Phase 11 — observability consent default OFF; banned fields."""

from app.observability.local import Observability
from helpers import fresh_client


def test_consent_default_off():
    obs = Observability()
    assert obs.consent is False
    obs.record("opened_home")
    assert obs.events == []


def test_records_after_consent():
    obs = Observability(consent=True)
    obs.record("opened_home")
    assert obs.events == ["opened_home"]


def test_blocks_email():
    obs = Observability(consent=True)
    obs.record("email_leaked")
    assert obs.events == []


def test_blocks_token():
    obs = Observability(consent=True)
    obs.record("refresh_token")
    assert obs.events == []


def test_blocks_gps():
    obs = Observability(consent=True)
    obs.record("gps")
    assert obs.events == []


def test_blocks_receipt_ayah_hadith_prompt():
    obs = Observability(consent=True)
    for name in ("receipt_ok", "ayah_opened", "hadith_seen", "ai_prompt"):
        obs.record(name)
    assert obs.events == []


def test_allows_neutral_event():
    obs = Observability(consent=True)
    obs.record("opened_prayer")
    assert "opened_prayer" in obs.events


def test_analytics_flag_false():
    with fresh_client() as client:
        assert client.get("/health").json()["flags"]["analytics_production_ready"] is False


def test_no_third_party_keys_in_health():
    with fresh_client() as client:
        blob = str(client.get("/health").json()).lower()
        assert "sentry" not in blob
        assert "mixpanel" not in blob
        assert "firebase" not in blob
