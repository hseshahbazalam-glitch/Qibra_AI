"""QB-012 — the request-size cap measures BYTES ON THE STREAM.

Red first: `SecurityHeadersMiddleware` reads the `Content-Length` header and nothing
else. `Transfer-Encoding: chunked` carries no Content-Length, so the check is simply
skipped — and a client that *lies* about Content-Length is believed. The handler then
pulls an unbounded body into memory before pydantic ever sees it.
"""

import asyncio
import json

from app.middleware.security_headers import MAX_BODY_BYTES, BodySizeLimitMiddleware
from helpers import fresh_client, login, register


def _scope(headers=None, path="/ai/ask", method="POST"):
    return {
        "type": "http",
        "asgi": {"version": "3.0"},
        "http_version": "1.1",
        "method": method,
        "scheme": "http",
        "path": path,
        "raw_path": path.encode(),
        "query_string": b"",
        "root_path": "",
        "headers": [(k.lower().encode(), v.encode()) for k, v in (headers or {}).items()],
        "client": ("203.0.113.7", 50000),
        "server": ("testserver", 80),
        "state": {},
    }


def _drive(chunks, *, max_bytes, headers=None, path="/ai/ask", method="POST", handler=None):
    """Push `chunks` through the middleware and report what the handler saw."""
    stream = iter(list(chunks))
    outcome = {"body": b"", "reached": False, "status": None, "sent": []}

    async def receive():
        try:
            return {"type": "http.request", "body": next(stream), "more_body": True}
        except StopIteration:
            return {"type": "http.request", "body": b"", "more_body": False}

    async def app(scope, receive_, send_):
        outcome["reached"] = True
        if handler is None:
            total = b""
            while True:
                message = await receive_()
                total += message.get("body", b"")
                if not message.get("more_body", False):
                    break
            outcome["body"] = total
            status, payload = 200, b"ok"
        else:
            result = handler(scope, receive_, send_)
            if asyncio.iscoroutine(result):
                result = await result
            status, payload = result
            outcome["body"] = b""
        await send_({"type": "http.response.start", "status": status, "headers": []})
        await send_({"type": "http.response.body", "body": payload})

    async def send(message):
        outcome["sent"].append(message)

    middleware = BodySizeLimitMiddleware(app, max_bytes=max_bytes)
    asyncio.run(middleware(_scope(headers, path, method), receive, send))
    return outcome


def _app_for(handler):
    async def app(scope, receive, send):
        status, payload = await handler(scope, receive, send)
        await send({"type": "http.response.start", "status": status, "headers": []})
        await send({"type": "http.response.body", "body": payload})

    return app


def _send():
    async def send(message):
        return None

    return send


def _status(outcome):
    start = next(m for m in outcome["sent"] if m["type"] == "http.response.start")
    headers = {k.decode().lower(): v.decode() for k, v in start.get("headers", [])}
    body = b"".join(m.get("body", b"") for m in outcome["sent"] if m["type"] == "http.response.body")
    return start["status"], headers, body


def test_chunked_body_over_the_cap_is_refused_before_the_handler():
    outcome = _drive([b"x" * 256] * 20, max_bytes=1024, headers={"transfer-encoding": "chunked"})
    status, headers, body = _status(outcome)
    assert status == 413
    assert outcome["reached"] is False, "the handler must never see an oversized body"
    assert json.loads(body) == {"detail": "payload_too_large", "max_bytes": 1024}
    assert headers["content-type"].startswith("application/json")


def test_a_lying_content_length_does_not_raise_the_cap():
    """`Content-Length: 10` followed by 10 KB of body is still a 413 — the header is a
    claim, the stream is the measurement."""
    outcome = _drive([b"z" * 512] * 20, max_bytes=1024, headers={"content-length": "10"})
    assert _status(outcome)[0] == 413
    assert outcome["reached"] is False


def test_a_body_under_the_cap_is_replayed_intact():
    chunks = [b"y" * 300, b"y" * 700, b"y" * 512]
    outcome = _drive(chunks, max_bytes=4096, headers={"transfer-encoding": "chunked"})
    assert outcome["reached"] is True
    assert outcome["body"] == b"".join(chunks), "nothing truncated, nothing duplicated"
    assert _status(outcome)[0] == 200


def test_after_the_body_the_wrapper_delegates_and_never_invents_a_disconnect():
    """A replayed body must not be followed by a *fabricated* `http.disconnect`.

    starlette polls receive() to decide whether the client went away, and BaseHTTPMiddleware
    cancels the inner task when it sees one — which truncates a StreamingResponse after its
    first chunk (SSE on /ai/ask lost 3 of 4 deltas that way while this was being written).
    So: the handler gets one complete message, and everything after that comes from the
    underlying stream.
    """
    seen: list[dict] = []
    underlying = {"reads": 0}

    async def handler(scope, receive_, send_):
        for _ in range(3):
            seen.append(await receive_())
        return 200, b"ok"

    def counting_receive_factory(chunks):
        stream = iter(list(chunks))

        async def receive():
            try:
                return {"type": "http.request", "body": next(stream), "more_body": True}
            except StopIteration:
                underlying["reads"] += 1
                return {"type": "http.request", "body": b"", "more_body": False}

        return receive

    middleware = BodySizeLimitMiddleware(_app_for(handler), max_bytes=4096)
    receive = counting_receive_factory([b"a", b"b"])
    asyncio.run(middleware(_scope({"transfer-encoding": "chunked"}), receive, _send()))
    assert seen[0] == {"type": "http.request", "body": b"ab", "more_body": False}
    assert [m["type"] for m in seen[1:]] == ["http.request", "http.request"], seen
    # the body read (terminator) plus the two delegated reads
    assert underlying["reads"] == 3, underlying


def test_bodyless_requests_pass_straight_through():
    for method in ("GET", "HEAD"):
        outcome = _drive([], max_bytes=1024, path="/health", method=method)
        assert outcome["reached"] is True, method
        assert _status(outcome)[0] == 200, method


def test_the_cap_still_applies_through_the_mounted_app_over_http():
    """End-to-end: a chunked, oversized JSON body must be refused with 413 rather than
    read into the router. Today the Content-Length check is skipped (no header) and the
    body is consumed — the request lands on validation/auth instead."""
    with fresh_client() as client:
        register(client, email="size@e.com")
        auth = {"Authorization": f"Bearer {login(client, email='size@e.com').json()['access_token']}"}
        payload = json.dumps({"query": "z" * (MAX_BODY_BYTES + 4096), "corpus": []}).encode()
        chunk = 32 * 1024
        body = iter([payload[i : i + chunk] for i in range(0, len(payload), chunk)])
        r = client.post("/ai/ask", content=body, headers=dict(auth, **{"content-type": "application/json"}))
        assert r.status_code == 413, (r.status_code, r.text[:160])
        assert r.json()["detail"] == "payload_too_large"


def test_a_legitimately_large_sync_payload_still_gets_through():
    """The cap is 256 KiB; the app's own biggest routine request is a 500-item sync
    batch. A security fix that breaks it would just move the outage."""
    from datetime import datetime, timezone

    now = datetime.now(timezone.utc).isoformat()
    with fresh_client() as client:
        register(client, email="bulk@e.com")
        auth = {"Authorization": f"Bearer {login(client, email='bulk@e.com').json()['access_token']}"}
        items = [
            {
                "collection": "quran",
                "item_id": f"2:{i}",
                "payload": {"surah": 2, "ayah": i, "note": "pad" * 20},
                "updated_at": now,
                "deleted": False,
            }
            for i in range(1, 60)
        ]
        blob = json.dumps({"items": items}).encode()
        assert MAX_BODY_BYTES > len(blob) > 8000  # a real payload, not a toy one
        r = client.post(
            "/sync", content=blob, headers=dict(auth, **{"content-length": str(len(blob))})
        )
        assert r.status_code == 200, (r.status_code, r.text[:200])
