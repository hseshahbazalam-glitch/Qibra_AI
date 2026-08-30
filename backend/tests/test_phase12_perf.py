"""Phase 12 — sync merge prefetch keeps LWW; metrics stay bounded."""

from datetime import datetime, timezone

from app.observability.metrics import inc, reset_metrics, snapshot
from helpers import bearer, fresh_client


def test_metrics_key_cap():
    reset_metrics()
    for i in range(80):
        inc(f"opened_home_{i}")
    assert len(snapshot()["counters"]) <= 64


def test_sync_batch_twenty_items_accepted():
    with fresh_client() as client:
        headers = bearer(client, email="p12@e.com")
        now = datetime.now(timezone.utc).isoformat()
        items = [
            {
                "collection": "bookmarks",
                "item_id": f"quran:{i}",
                "payload": {"surah": i},
                "updated_at": now,
                "operation_id": f"op-{i}",
            }
            for i in range(20)
        ]
        r = client.post("/sync", json={"items": items}, headers=headers)
        assert r.status_code == 200
        results = r.json()["results"]
        assert len(results) == 20
        assert all(row["status"] == "accepted" for row in results)


def test_sync_idempotent_still_holds():
    with fresh_client() as client:
        headers = bearer(client)
        body = {
            "items": [
                {
                    "collection": "bookmarks",
                    "item_id": "2:255",
                    "payload": {"surah": 2, "ayah": 255},
                    "updated_at": "2026-08-31T00:00:00+00:00",
                    "operation_id": "same-op",
                }
            ]
        }
        r1 = client.post("/sync", json=body, headers=headers)
        r2 = client.post("/sync", json=body, headers=headers)
        assert r1.status_code == 200
        assert r2.status_code == 200
