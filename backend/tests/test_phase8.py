"""Phase 8 — notifications local only; no precise GPS on server."""

from helpers import fresh_client
from app.config import Settings
from app.observability.local import Observability


def test_notifications_local_only_flag():
    with fresh_client() as client:
        flags = client.get("/health").json()["flags"]
        assert flags["notifications_local_only"] is True


def test_precise_location_flag_false():
    with fresh_client() as client:
        flags = client.get("/health").json()["flags"]
        assert flags["precise_location_stored_on_server"] is False


def test_health_body_has_no_gps():
    with fresh_client() as client:
        body = client.get("/health").json()
        blob = str(body).lower()
        assert "gps" not in blob
        assert "latitude" not in blob
        assert "longitude" not in blob


def test_settings_defaults():
    s = Settings()
    assert s.notifications_local_only is True
    assert s.precise_location_stored_on_server is False


def test_observability_does_not_record_gps_even_with_consent():
    obs = Observability(consent=True)
    obs.record("gps_fix")
    assert obs.events == []


def test_observability_default_consent_off():
    obs = Observability()
    obs.record("prayer_opened")
    assert obs.events == []


def test_cache_control_no_store():
    with fresh_client() as client:
        assert client.get("/health").headers["Cache-Control"] == "no-store"


def test_no_exact_alarm_contract_note():
    # Client dropped USE_EXACT_ALARM; server does not schedule device alarms.
    with fresh_client() as client:
        assert "alarm" not in client.get("/health").json()


def test_request_id_present():
    with fresh_client() as client:
        assert client.get("/health").headers.get("X-Request-Id")
