from fastapi import APIRouter

from ..config import get_settings
from ..observability.metrics import snapshot as metrics_snapshot

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


@router.get("/health/metrics")
def health_metrics():
    body = metrics_snapshot()
    blob = str(body).lower()
    for banned in ("email", "token", "gps", "receipt", "ayah", "hadith", "prompt"):
        if banned in blob:
            return {
                "analytics_production_ready": False,
                "consent_default": False,
                "third_party_sdks": [],
                "counters": {},
                "api": {
                    "latency_ms_sum": 0,
                    "latency_ms_count": 0,
                    "latency_ms_avg": 0,
                },
            }
    return body
