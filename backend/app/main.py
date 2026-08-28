from fastapi import FastAPI

from .config import get_settings
from .db.session import reset_engine
from .middleware.rate_limit import RateLimitMiddleware
from .middleware.request_id import RequestIdMiddleware
from .middleware.security_headers import SecurityHeadersMiddleware
from .routers import ai, auth, billing, bookmarks, health, progress, settings as settings_router, sync, users

cfg = get_settings()

app = FastAPI(title=cfg.app_name, version=cfg.version)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestIdMiddleware)
app.add_middleware(RateLimitMiddleware)

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
