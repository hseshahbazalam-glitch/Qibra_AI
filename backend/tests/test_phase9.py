from tests.conftest import auth_header, register


def test_ai_does_not_invent_when_unretrieved(client):
    token = register(client).json()["data"]["accessToken"]
    response = client.post(
        "/api/v1/ai/chat",
        json={"message": "Give me a new fatwa about crypto mining"},
        headers=auth_header(token),
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["honest"] is True
    assert data["answer"] is None
    assert data["reason"] == "no_retrieval"
    assert "will not invent" in data["message"]


def test_ai_ayah_and_hadith_are_retrieval_only(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    ayah = client.post("/api/v1/ai/ayah", json={"ref": "2:255"}, headers=headers)
    hadith = client.post("/api/v1/ai/hadith", json={"ref": "bukhari:1"}, headers=headers)
    dua = client.post("/api/v1/ai/dua", json={"question": ""}, headers=headers)
    assert ayah.json()["data"]["kind"] == "ayah"
    assert hadith.json()["data"]["kind"] == "hadith"
    assert dua.json()["data"]["reason"] == "empty_prompt"
    assert ayah.json()["data"]["answer"] is None
