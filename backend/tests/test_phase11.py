from tests.conftest import auth_header, register


def test_checkout_stays_unpaid_without_webhook(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    checkout = client.post(
        "/api/v1/billing/checkout",
        json={"planId": "qibra_plus"},
        headers=headers,
    )
    assert checkout.status_code == 200
    assert checkout.json()["data"]["paid"] is False
    assert checkout.json()["data"]["status"] == "pending"
    status = client.get("/api/v1/billing/status", headers=headers)
    assert status.json()["data"]["paid"] is False


def test_webhook_requires_signature(client):
    token = register(client).json()["data"]["accessToken"]
    user_id = client.get("/api/v1/users/me", headers=auth_header(token)).json()["data"]["id"]
    checkout = client.post(
        "/api/v1/billing/checkout",
        json={"planId": "qibra_plus"},
        headers=auth_header(token),
    ).json()["data"]
    rejected = client.post(
        "/api/v1/billing/webhook",
        json={
            "checkoutId": checkout["checkoutId"],
            "userId": user_id,
            "status": "paid",
        },
    )
    assert rejected.status_code == 401
    accepted = client.post(
        "/api/v1/billing/webhook",
        json={
            "checkoutId": checkout["checkoutId"],
            "userId": user_id,
            "status": "paid",
        },
        headers={"X-Qibra-Signature": "dev-webhook-secret"},
    )
    assert accepted.status_code == 200
    assert accepted.json()["data"]["applied"] is True
    status = client.get("/api/v1/billing/status", headers=auth_header(token))
    assert status.json()["data"]["paid"] is True
