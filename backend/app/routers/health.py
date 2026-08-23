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
            "modules": ["health", "auth", "users", "bookmarks", "sync", "ai", "billing"],
            # These stay false until a separately proved production subsystem exists.
            "auth_production_ready": False,
            "content_production_ready": False,
            "billing_production_ready": False,
            "analytics_production_ready": False,
            "notifications_local_only": True,
            "precise_location_stored_on_server": False,
        },
        message="healthy",
    )
