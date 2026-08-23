from tests.conftest import auth_header, register


def test_content_endpoint_does_not_invent_unretrieved_text(client):
    token = register(client).json()["data"]["accessToken"]
    response = client.post(
        "/api/v1/ai/ayah",
        json={"ref": "999:999", "question": ""},
        headers=auth_header(token),
    )
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["answer"] is None
    assert data["honest"] is True
