from fastapi import FastAPI, Request
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import JSONResponse

from .config import get_settings
from .db.session import reset_engine
from .middleware.metrics import MetricsMiddleware
from .middleware.security_headers import MAX_BODY_BYTES, BodySizeLimitMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .middleware.request_id import RequestIdMiddleware
from .middleware.security_headers import SecurityHeadersMiddleware
from .routers import ai, auth, billing, bookmarks, health, progress, settings as settings_router, sync, users

cfg = get_settings()

app = FastAPI(title=cfg.app_name, version=cfg.version, debug=False)

# add_middleware prepends, so the LAST one added is the OUTERMOST — i.e. this list runs
# bottom-to-top per request. The order is the fix for QB-013's second half: RequestId and
# SecurityHeaders must wrap the limiter, otherwise a 429 (or a 413) produced by a
# middleware never reaches the code that stamps identity and headers onto it.
#   RequestId → SecurityHeaders → BodySizeLimit → Metrics → RateLimit → route
app.add_middleware(RateLimitMiddleware)
app.add_middleware(MetricsMiddleware)
app.add_middleware(BodySizeLimitMiddleware, max_bytes=MAX_BODY_BYTES)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestIdMiddleware)


@app.exception_handler(Exception)
async def _unhandled_error(_request: Request, exc: Exception):
    from fastapi.exceptions import RequestValidationError

    # Do not swallow HTTP / validation errors or leak stack traces.
    if isinstance(exc, RequestValidationError):
        return JSONResponse({"detail": exc.errors()}, status_code=422)
    from .observability.metrics import note_crash

    note_crash()
    return JSONResponse({"detail": "server_error"}, status_code=500)

@app.exception_handler(StarletteHTTPException)
async def _http_error(_request: Request, exc: StarletteHTTPException):
    """One flat object per error, whatever the endpoint raised.

    FastAPI's default handler wraps `detail` in `{"detail": ...}` — which is right for a
    code string and double-nests the structured bodies this pass added (auth_required with
    a hint, login_throttled with a scope and a retry window). Any header the exception
    carries (`Retry-After`, 405 `Allow`) is preserved.
    """
    detail = getattr(exc, "detail", None)
    body = detail if isinstance(detail, dict) else {"detail": detail if detail is not None else "error"}
    headers = getattr(exc, "headers", None)
    return JSONResponse(body, status_code=exc.status_code, headers=headers or None)


app.include_router(health.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(bookmarks.router)
app.include_router(sync.router)
app.include_router(ai.router)
app.include_router(billing.router)
app.include_router(settings_router.router)
app.include_router(progress.router)


@app.on_event("startup")
def _startup():
    reset_engine()
