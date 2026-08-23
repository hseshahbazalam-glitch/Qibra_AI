"""Qibra AI FastAPI application.

Implements docs/api/API_CONTRACT.md on /api/v1 without changing that file.
Flutter AppApi currently talks to /v1; the same contract router is also mounted
there so the existing client can connect later without a contract rewrite.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app import __version__
from app.core.config import get_settings
from app.core.deps import require_user
from app.core.responses import ApiError, error_response, new_trace_id, success_response
from app.routers import ai, auth, duas, hadith, profile, quran, tafsir
from app.routers.profile import ProfileUpdateBody, delete_profile, get_profile, update_profile
from app.services.user_store import UserRecord, UserStore, get_user_store

CONTRACT_PREFIX = "/api/v1"
FLUTTER_PREFIX = "/v1"


def create_app() -> FastAPI:
    settings = get_settings()
    application = FastAPI(
        title="Qibra AI API",
        version=__version__,
        description="FastAPI backend for the existing Qibra AI Flutter app.",
        docs_url="/docs",
        redoc_url="/redoc",
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=settings.cors_origin_list != ["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @application.middleware("http")
    async def attach_trace_id(request: Request, call_next):
        request.state.trace_id = new_trace_id(request)
        response = await call_next(request)
        response.headers["X-Trace-Id"] = request.state.trace_id
        return response

    @application.exception_handler(ApiError)
    async def api_error_handler(request: Request, exc: ApiError):
        return error_response(
            exc.message,
            status_code=exc.status_code,
            data=exc.data,
            request=request,
        )

    @application.exception_handler(RequestValidationError)
    async def validation_handler(request: Request, exc: RequestValidationError):
        return error_response(
            "Invalid request",
            status_code=422,
            data={"errors": exc.errors()},
            request=request,
        )

    @application.exception_handler(StarletteHTTPException)
    async def http_handler(request: Request, exc: StarletteHTTPException):
        if isinstance(exc.detail, dict) and all(
            key in exc.detail for key in ("success", "message", "traceId")
        ):
            from fastapi.responses import JSONResponse

            return JSONResponse(status_code=exc.status_code, content=exc.detail)
        return error_response(str(exc.detail), status_code=exc.status_code, request=request)

    contract_router = APIRouter()
    contract_router.include_router(auth.router)
    contract_router.include_router(quran.router)
    contract_router.include_router(hadith.router)
    contract_router.include_router(tafsir.router)
    contract_router.include_router(duas.router)
    contract_router.include_router(ai.router)
    contract_router.include_router(profile.router)

    # Flutter AppApi uses /user/profile while the published contract uses /profile.
    flutter_aliases = APIRouter(tags=["profile-compat"])

    @flutter_aliases.get("/user/profile")
    def flutter_get_profile(request: Request, user: UserRecord = Depends(require_user)):
        return get_profile(request, user)

    @flutter_aliases.put("/user/profile")
    def flutter_put_profile(
        body: ProfileUpdateBody,
        request: Request,
        user: UserRecord = Depends(require_user),
        store: UserStore = Depends(get_user_store),
    ):
        return update_profile(body, request, user, store)

    @flutter_aliases.delete("/user/profile")
    def flutter_delete_profile(
        request: Request,
        user: UserRecord = Depends(require_user),
        store: UserStore = Depends(get_user_store),
    ):
        return delete_profile(request, user, store)

    application.include_router(contract_router, prefix=CONTRACT_PREFIX)
    application.include_router(contract_router, prefix=FLUTTER_PREFIX)
    application.include_router(flutter_aliases, prefix=FLUTTER_PREFIX)

    @application.get("/health")
    def health(request: Request):
        return success_response(
            {"status": "ok", "version": __version__, "contract": CONTRACT_PREFIX},
            message="Healthy",
            request=request,
        )

    @application.get("/")
    def root(request: Request):
        return success_response(
            {
                "name": "Qibra AI API",
                "version": __version__,
                "contract": CONTRACT_PREFIX,
                "docs": "/docs",
            },
            message="Qibra AI backend",
            request=request,
        )

    return application


app = create_app()
