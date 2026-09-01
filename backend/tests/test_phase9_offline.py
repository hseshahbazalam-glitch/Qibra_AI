"""Phase 9 — cache freshness, retry, queue, RAG mode, service plane."""

from datetime import datetime, timedelta

from app.offline.cache import EXPIRED, FRESH, MISSING, STALE, CacheEntry, MemoryCache, classify, lookup
from app.offline.queue import SyncOp, SyncQueue
from app.offline.retry import backoff_ms, should_retry
from app.offline.service_plane import BACKEND_AVAILABLE, LOCAL_ONLY, NETWORK_AVAILABLE, may_use_network, plane
from app.rag import answer, retrieval_mode


NOW = datetime(2026, 8, 30, 12, 0, 0)


def test_cache_hit_miss_stale_expired():
    cache = MemoryCache()
    assert classify(None, NOW) == MISSING
    entry = CacheEntry(
        key="k",
        value="v1",
        stored_at=NOW,
        ttl=timedelta(minutes=10),
        stale_after=timedelta(minutes=5),
    )
    cache.write(entry)
    assert lookup(cache, "k", NOW)[0] == FRESH
    assert lookup(cache, "k", NOW + timedelta(minutes=6))[0] == STALE
    freshness, kept = lookup(cache, "k", NOW + timedelta(minutes=11))
    assert freshness == EXPIRED
    assert kept is not None and kept.value == "v1"


def test_offline_read_and_invalidation():
    cache = MemoryCache()
    cache.write(CacheEntry(key="p", value="times", stored_at=NOW, ttl=timedelta(hours=1)))
    _, kept = lookup(cache, "p", NOW + timedelta(hours=3))
    assert kept is not None
    cache.invalidate("p")
    assert lookup(cache, "p", NOW)[0] == MISSING


def test_retry_backoff_and_permanent_failure():
    assert should_retry(timeout=True) is True
    assert should_retry(network_failure=True) is True
    assert should_retry(http_status=503) is True
    assert should_retry(http_status=401) is False
    assert should_retry(http_status=422) is False
    assert backoff_ms(0) < backoff_ms(3)


def test_queue_idempotent_persist_restart():
    q = SyncQueue()
    op = SyncOp(
        id="2:255",
        collection="bookmarks",
        type="upsert",
        payload={"surah": 2, "ayah": 255},
        updated_at=NOW,
    )
    q.enqueue(op)
    q.enqueue(SyncOp(id="2:255", collection="bookmarks", type="upsert", payload={"surah": 2, "ayah": 255}, updated_at=NOW))
    assert len(q.pending) == 1
    snap = q.snapshot()
    q2 = SyncQueue()
    q2.restore(snap)
    assert q2.pending[0].id == "2:255"
    assert "token" not in str(snap)


def test_service_plane_unknown_not_online():
    assert may_use_network("unknown") is False
    assert may_use_network("offline") is False
    assert may_use_network("reconnecting") is False
    assert plane(may_use_network=False, backend_enabled=False, backend_healthy=False) == LOCAL_ONLY
    assert plane(may_use_network=True, backend_enabled=False, backend_healthy=False) == NETWORK_AVAILABLE
    assert plane(may_use_network=True, backend_enabled=True, backend_healthy=True) == BACKEND_AVAILABLE


def test_rag_no_context_local_and_honest_refuse():
    assert retrieval_mode([]) == "NO_CONTEXT"
    assert retrieval_mode([{"text": "x"}]) == "LOCAL_RETRIEVAL"
    assert retrieval_mode([{"text": "x"}], remote=True) == "REMOTE_RETRIEVAL"
    refused = answer("zzzz-no-hit", [{"text": "mercy in a verse", "source": "local"}])
    assert refused["refused"] is True
    assert refused["reason"] == "no_retrieved_passage"
