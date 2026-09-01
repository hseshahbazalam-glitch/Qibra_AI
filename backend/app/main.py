from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .config import get_settings
from .db.session import reset_engine
from .middleware.metrics import MetricsMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .middleware.request_id import RequestIdMiddleware
from .middleware.security_headers import SecurityHeadersMiddleware
from .routers import ai, auth, billing, bookmarks, health, progress, settings as settings_router, sync, users

cfg = get_settings()

app = FastAPI(title=cfg.app_name, version=cfg.version, debug=False)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestIdMiddleware)
app.add_middleware(RateLimitMiddleware)
app.add_middleware(MetricsMiddleware)


@app.exception_handler(Exception)
async def _unhandled_error(_request: Request, exc: Exception):
    from fastapi.exceptions import RequestValidationError
    from starlette.exceptions import HTTPException as StarletteHTTPException

    # Do not swallow HTTP / validation errors or leak stack traces.
    if isinstance(exc, StarletteHTTPException):
        return JSONResponse({"detail": exc.detail}, status_code=exc.status_code)
    if isinstance(exc, RequestValidationError):
        return JSONResponse({"detail": exc.errors()}, status_code=422)
    from .observability.metrics import note_crash

    note_crash()
    return JSONResponse({"detail": "server_error"}, status_code=500)

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
