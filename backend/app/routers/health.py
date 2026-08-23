from fastapi import APIRouter

from .. import __version__
from ..core.config import get_settings
from ..core.responses import envelope

router = APIRouter(tags=["health"])


@router.get("/health")
def health():
    settings = get_settings()
    return envelope(
        {
            "status": "ok",
            "service": settings.app_name,
            "version": __version__,
            "modules": [
                "health",
                "auth",
                "users",
                "bookmarks",
                "sync",
                "ai",
                "billing",
            ],
        },
        message="healthy",
    )
