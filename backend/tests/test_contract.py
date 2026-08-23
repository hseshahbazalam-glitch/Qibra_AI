"""Every path in docs/api/API_CONTRACT.md must exist and use the standard envelope."""

from __future__ import annotations

CONTRACT_PATHS = [
    ("POST", "/api/v1/auth/login"),
    ("POST", "/api/v1/auth/register"),
    ("POST", "/api/v1/auth/logout"),
    ("POST", "/api/v1/auth/forgot-password"),
    ("GET", "/api/v1/quran"),
    ("GET", "/api/v1/quran/surah/{id}"),
    ("GET", "/api/v1/quran/search"),
    ("GET", "/api/v1/quran/juz"),
    ("GET", "/api/v1/hadith"),
    ("GET", "/api/v1/hadith/search"),
    ("GET", "/api/v1/hadith/book"),
    ("GET", "/api/v1/tafsir"),
    ("GET", "/api/v1/tafsir/search"),
    ("GET", "/api/v1/duas"),
    ("GET", "/api/v1/duas/category"),
    ("GET", "/api/v1/duas/search"),
    ("POST", "/api/v1/ai/chat"),
    ("POST", "/api/v1/ai/ayah"),
    ("POST", "/api/v1/ai/hadith"),
    ("POST", "/api/v1/ai/dua"),
    ("GET", "/api/v1/profile"),
    ("PUT", "/api/v1/profile"),
    ("DELETE", "/api/v1/profile"),
]

ENVELOPE = {"success", "message", "data", "timestamp", "traceId"}


def test_contract_paths_are_registered(client):
    documented = {(method, path) for method, path in CONTRACT_PATHS}
    registered = set()
    for route in client.app.routes:
        path = getattr(route, "path", "")
        methods = getattr(route, "methods", set()) or set()
        for method in methods:
            registered.add((method, path))
    missing = documented - registered
    assert not missing, f"Contract paths missing: {sorted(missing)}"


def test_health_and_root_use_envelope(client):
    for path in ("/", "/health"):
        response = client.get(path)
        assert response.status_code == 200
        payload = response.json()
        assert ENVELOPE <= set(payload)
        assert payload["success"] is True


def test_unknown_route_uses_envelope(client):
    response = client.get("/api/v1/does-not-exist")
    assert response.status_code == 404
    payload = response.json()
    assert ENVELOPE <= set(payload)
    assert payload["success"] is False
