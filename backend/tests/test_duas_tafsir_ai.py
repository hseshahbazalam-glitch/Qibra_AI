from __future__ import annotations


def test_duas_catalog_and_search(client):
    listing = client.get("/api/v1/duas")
    assert listing.status_code == 200
    data = listing.json()["data"]
    assert data["categories"]
    assert data["duas"]

    category = client.get("/api/v1/duas/category", params={"id": "morning_evening"})
    assert category.status_code == 200
    assert category.json()["data"]["duas"]

    search = client.get("/api/v1/duas/search", params={"q": "istighfar"})
    assert search.status_code == 200
    assert search.json()["data"]["results"]


def test_tafsir_does_not_fabricate_commentary(client):
    sources = client.get("/api/v1/tafsir")
    assert sources.status_code == 200
    assert sources.json()["data"]["available"] is False

    lookup = client.get("/api/v1/tafsir", params={"surah": 1, "ayah": 1})
    assert lookup.status_code == 200
    body = lookup.json()["data"]
    assert body["available"] is False
    assert body["content"] is None
    assert body["ayah"]["arabic"]
    assert body["label"] == "translation"

    search = client.get("/api/v1/tafsir/search", params={"q": "opening"})
    assert search.status_code == 200
    assert search.json()["data"]["available"] is False
    assert all(item["kind"] == "translation" for item in search.json()["data"]["matches"])


def test_ai_uses_verified_sources_only(client):
    chat = client.post("/api/v1/ai/chat", json={"message": "intention"})
    assert chat.status_code == 200
    reply = chat.json()["data"]
    assert reply["sources"]
    assert "verified" in reply["reply"].lower() or "Bukhari" in reply["reply"] or "Quran" in reply["reply"]

    empty = client.post("/api/v1/ai/chat", json={"message": "xyzzy-no-match-qibra"})
    assert empty.status_code == 200
    assert "couldn't find a verified source" in empty.json()["data"]["reply"]

    ayah = client.post("/api/v1/ai/ayah", json={"surah": 1, "ayah": 1})
    assert ayah.status_code == 200
    assert "Quran 1:1" in ayah.json()["data"]["reply"]

    hadith = client.post("/api/v1/ai/hadith", json={"collection": "bukhari", "number": "1"})
    assert hadith.status_code == 200
    assert "Bukhari" in hadith.json()["data"]["reply"]

    dua = client.post("/api/v1/ai/dua", json={"query": "istighfar"})
    assert dua.status_code == 200
    assert dua.json()["data"]["sources"]
