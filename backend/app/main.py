from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from . import __version__
from .core.config import get_settings
from .core.deps import ApiError
from .core.rate_limit import RateLimitMiddleware
from .core.responses import error_envelope
from .routers import ai, auth, billing, bookmarks, health, sync, users

settings = get_settings()
settings.assert_secure_production()
app = FastAPI(title="Qibra API", version=__version__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "X-Qibra-Signature", "X-Request-ID"],
)
app.add_middleware(RateLimitMiddleware)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or uuid4().hex
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        return response


app.add_middleware(SecurityHeadersMiddleware)


@app.exception_handler(ApiError)
async def api_error_handler(_: Request, exc: ApiError):
    return error_envelope(exc.message, status_code=exc.status_code, data=exc.data)


@app.exception_handler(RequestValidationError)
async def validation_handler(_: Request, exc: RequestValidationError):
    return error_envelope("Validation failed.", status_code=422, data={"errors": exc.errors()})


def _mount(prefix: str) -> None:
    app.include_router(health.router, prefix=prefix)
    app.include_router(auth.router, prefix=prefix)
    app.include_router(users.router, prefix=prefix)
    app.include_router(bookmarks.router, prefix=prefix)
    app.include_router(sync.router, prefix=prefix)
    app.include_router(ai.router, prefix=prefix)
    app.include_router(billing.router, prefix=prefix)


app.include_router(health.router)
_mount("/api/v1")
_mount("/v1")
