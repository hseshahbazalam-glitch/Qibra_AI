from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

MAX_BODY_BYTES = 256 * 1024


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        content_length = request.headers.get("content-length")
        if content_length:
            try:
                size = int(content_length)
            except ValueError:
                size = MAX_BODY_BYTES + 1
            if size > MAX_BODY_BYTES:
                return JSONResponse({"detail": "payload_too_large"}, status_code=413)
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        return response
