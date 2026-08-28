from fastapi import APIRouter

from ..config import get_settings

router = APIRouter()


@router.get("/health")
def health():
    s = get_settings()
    return {
        "status": "ok",
        "version": s.version,
        "flags": {
            "auth_production_ready": s.auth_production_ready,
            "content_production_ready": s.content_production_ready,
            "billing_production_ready": s.billing_production_ready,
            "analytics_production_ready": s.analytics_production_ready,
            "notifications_local_only": s.notifications_local_only,
            "precise_location_stored_on_server": s.precise_location_stored_on_server,
        },
    }
