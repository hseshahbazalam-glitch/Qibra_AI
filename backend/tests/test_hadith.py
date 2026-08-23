from __future__ import annotations


def test_hadith_collections_and_book(client):
    listing = client.get("/api/v1/hadith")
    assert listing.status_code == 200
    collections = listing.json()["data"]["collections"]
    slugs = {item["id"] for item in collections}
    assert {"bukhari", "muslim"} <= slugs

    book = client.get("/api/v1/hadith/book", params={"name": "bukhari", "limit": 5})
    assert book.status_code == 200
    payload = book.json()["data"]
    assert payload["name"] == "Sahih al-Bukhari"
    assert payload["items"]
    assert payload["items"][0]["english"]


def test_hadith_search_uses_real_corpus(client):
    response = client.get("/api/v1/hadith/search", params={"q": "intentions"})
    assert response.status_code == 200
    results = response.json()["data"]["results"]
    assert results
    assert any("Bukhari" in item["reference"]["display"] for item in results)
    assert any("intention" in item["english"].lower() for item in results)
