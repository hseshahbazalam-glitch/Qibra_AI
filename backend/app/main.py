from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from . import __version__
from .core.deps import ApiError
from .core.responses import error_envelope
from .routers import ai, auth, billing, bookmarks, health, sync, users

app = FastAPI(title="Qibra API", version=__version__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(ApiError)
async def api_error_handler(_: Request, exc: ApiError):
    return error_envelope(exc.message, status_code=exc.status_code, data=exc.data)


@app.exception_handler(RequestValidationError)
async def validation_handler(_: Request, exc: RequestValidationError):
    return error_envelope(
        "Validation failed.",
        status_code=422,
        data={"errors": exc.errors()},
    )


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
