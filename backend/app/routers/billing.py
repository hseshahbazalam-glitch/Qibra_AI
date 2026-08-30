from fastapi import APIRouter, Request

from ..services.billing_service import BillingService

router = APIRouter(prefix="/billing", tags=["billing"])
_service = BillingService()


@router.get("/status")
def status():
    return _service.status()


@router.post("/verify")
async def verify(request: Request):
    payload: dict = {}
    try:
        data = await request.json()
        if isinstance(data, dict):
            payload = data
    except Exception:
        payload = {}
    return _service.verify_payload(payload)


@router.post("/restore")
def restore():
    return _service.restore()
