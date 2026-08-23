def test_billing_plans_are_public(client):
    response = client.get("/api/v1/billing/plans")
    assert response.status_code == 200
    plans = response.json()["data"]["plans"]
    ids = {item["id"] for item in plans}
    assert "free" in ids
    assert "qibra_plus" in ids
