"""Response headers (QB-013's "a 429 must look like every other response" depends on
these being applied OUTSIDE the limiter) and the request-size gate.

The size gate is split in two on purpose:

* `SecurityHeadersMiddleware` still refuses an oversized `Content-Length` up front, so a
  5 MB upload is answered without reading a byte of it;
* `BodySizeLimitMiddleware` MEASURES the stream (QB-012). A Content-Length is a claim and
  `Transfer-Encoding: chunked` makes no claim at all, so without a streamed count both
  are bypassable — one by lying, one by staying silent.
"""

import json

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

MAX_BODY_BYTES = 256 * 1024

_SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Cache-Control": "no-store",
}

# Only these can carry a body, so only these are worth reading a stream for.
_BODY_METHODS = frozenset({"POST", "PUT", "PATCH", "DELETE"})


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        content_length = request.headers.get("content-length")
        if content_length:
            try:
                size = int(content_length)
            except ValueError:
                size = MAX_BODY_BYTES + 1
            if size > MAX_BODY_BYTES:
                return self._json(
                    413,
                    {"detail": "payload_too_large", "max_bytes": MAX_BODY_BYTES},
                )
        response = await call_next(request)
        for header, value in _SECURITY_HEADERS.items():
            response.headers[header] = value
        return response

    @staticmethod
    def _json(status: int, body: dict) -> JSONResponse:
        response = JSONResponse(body, status_code=status)
        for header, value in _SECURITY_HEADERS.items():
            response.headers[header] = value
        return response


class BodySizeLimitMiddleware:
    """Count bytes on the streamed body and refuse anything over the cap BEFORE the
    handler sees it (QB-012).

    Plain ASGI, not BaseHTTPMiddleware: replacing the receive channel is the whole job,
    and a base-class middleware cannot rebind the `receive` its inner app was handed.
    The body is buffered only for requests that claim one (a Content-Length or a
    transfer-encoding), and the cap is what bounds that buffer.
    """

    def __init__(self, app, max_bytes: int = MAX_BODY_BYTES) -> None:
        self.app = app
        self.max_bytes = int(max_bytes)

    async def __call__(self, scope, receive, send) -> None:
        if scope["type"] != "http" or scope.get("method") not in _BODY_METHODS:
            await self.app(scope, receive, send)
            return

        headers = {
            key.decode("latin-1").lower(): value.decode("latin-1")
            for key, value in scope.get("headers", [])
        }
        declared = headers.get("content-length")
        if declared:
            try:
                over = int(declared) > self.max_bytes
            except ValueError:
                over = True
            if over:
                await self._reject(scope, send)
                return
        elif "transfer-encoding" not in headers:
            # No length claimed and no chunked framing: nothing to read.
            await self.app(scope, receive, send)
            return

        chunks: list[bytes] = []
        total = 0
        overflow = False
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                break
            body = message.get("body", b"")
            total += len(body)
            if total > self.max_bytes:
                overflow = True
                break
            if body:
                chunks.append(body)
            if not message.get("more_body", False):
                break

        if overflow:
            await self._reject(scope, send)
            return

        data = b"".join(chunks)

        async def replay() -> dict:
            """One complete body message, then straight through to the real stream.

            The second part matters: starlette polls `receive()` (with a 0.1 s window) to
            decide whether the client went away, and a middleware that *invents* an
            `http.disconnect` here cancels a streaming response mid-flight — SSE stopped
            after the first delta while this was being written. Delegating is both the
            honest answer and the one that keeps /ai/ask?stream=true alive.
            """
            if not replay.delivered:  # type: ignore[attr-defined]
                replay.delivered = True  # type: ignore[attr-defined]
                return {"type": "http.request", "body": data, "more_body": False}
            return await receive()

        replay.delivered = False  # type: ignore[attr-defined]
        await self.app(scope, replay, send)

    async def _reject(self, scope, send) -> None:
        body = json.dumps({"detail": "payload_too_large", "max_bytes": self.max_bytes}).encode()
        await send(
            {
                "type": "http.response.start",
                "status": 413,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"content-length", str(len(body)).encode()),
                ],
            }
        )
        await send({"type": "http.response.body", "body": body})
