from __future__ import annotations


def test_quran_index_has_114_surahs(client):
    response = client.get("/api/v1/quran")
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["totals"]["surahs"] == 114
    assert data["totals"]["ayahs"] == 6236
    assert len(data["surahs"]) == 114
    assert data["surahs"][0]["name"]


def test_quran_surah_and_search(client):
    surah = client.get("/api/v1/quran/surah/1")
    assert surah.status_code == 200
    payload = surah.json()["data"]
    assert payload["number"] == 1
    assert payload["ayah_count"] == 7
    assert payload["ayahs"][0]["arabic"]

    missing = client.get("/api/v1/quran/surah/999")
    assert missing.status_code == 404

    search = client.get("/api/v1/quran/search", params={"q": "slumber"})
    assert search.status_code == 200
    results = search.json()["data"]["results"]
    assert results
    assert any(item["reference"] == "Quran 2:255" for item in results)


def test_quran_juz(client):
    index = client.get("/api/v1/quran/juz")
    assert index.status_code == 200
    assert len(index.json()["data"]["juz"]) == 30

    juz = client.get("/api/v1/quran/juz", params={"id": 1})
    assert juz.status_code == 200
    body = juz.json()["data"]
    assert body["id"] == 1
    assert body["ayah_count"] > 0
    assert body["ayahs"][0]["surah_id"] == 1
