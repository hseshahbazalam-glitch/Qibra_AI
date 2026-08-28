from fastapi import APIRouter

from ..services.billing_service import BillingService

router = APIRouter(prefix="/billing", tags=["billing"])
_service = BillingService()


@router.get("/status")
def status():
    return _service.status()


@router.post("/verify")
def verify():
    return {"ok": False, "reason": "store_unconfigured", "is_premium": False}
