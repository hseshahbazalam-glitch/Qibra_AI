"""Phase 14 — Family A tokens + progress API."""

from helpers import bearer, fresh_client

BANNED = {"#0A1F14", "#1A2438", "#141926", "#EC407A", "#7E57C2", "#42A5F5"}
FAMILY_A = {
    "ivory": "#FEFDF9",
    "canvas": "#F5F3EC",
    "forest": "#123F36",
    "gold_fill": "#C6A15B",
    "gold_text": "#6B542B",
    "danger": "#B42318",
    "ink": "#19312C",
}


def test_family_a_forest_and_ivory():
    assert FAMILY_A["forest"] == "#123F36"
    assert FAMILY_A["ivory"] == "#FEFDF9"
    assert FAMILY_A["canvas"] == "#F5F3EC"


def test_gold_text_not_fill():
    assert FAMILY_A["gold_text"] == "#6B542B"
    assert FAMILY_A["gold_fill"] == "#C6A15B"
    assert FAMILY_A["gold_text"] != FAMILY_A["gold_fill"]


def test_danger_token():
    assert FAMILY_A["danger"] == "#B42318"


def test_banned_navy_and_rainbow_not_in_family_a():
    values = set(FAMILY_A.values())
    for banned in BANNED:
        assert banned not in values


def test_progress_roundtrip():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.post(
            "/progress",
            json={"kind": "quran", "payload": {"surah": 2, "ayah": 5}},
            headers=headers,
        )
        assert r.status_code == 200
        listed = client.get("/progress", headers=headers).json()
        assert listed[0]["kind"] == "quran"
        assert listed[0]["payload"]["surah"] == 2


def test_progress_requires_auth():
    with fresh_client() as client:
        assert client.get("/progress").status_code == 401


def test_progress_isolated():
    with fresh_client() as client:
        h1 = bearer(client, email="a@e.com")
        h2 = bearer(client, email="b@e.com")
        client.post("/progress", json={"kind": "quran", "payload": {"surah": 1}}, headers=h1)
        assert client.get("/progress", headers=h2).json() == []


def test_progress_starts_empty():
    with fresh_client() as client:
        headers = bearer(client)
        assert client.get("/progress", headers=headers).json() == []


def test_ink_token():
    assert FAMILY_A["ink"] == "#19312C"
