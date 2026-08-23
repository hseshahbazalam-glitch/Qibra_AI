from fastapi import APIRouter, Depends, Header
from pydantic import BaseModel, Field

from ..core.config import get_settings
from ..core.deps import ApiError, current_user, store_dep
from ..core.responses import envelope
from ..services.store import BillingState, Store, UserRecord

router = APIRouter(prefix="/billing", tags=["billing"])

PLANS = [
    {
        "id": "free",
        "name": "Free",
        "price": 0,
        "currency": "USD",
        "interval": "month",
    },
    {
        "id": "qibra_plus",
        "name": "Qibra Plus",
        "price": 499,
        "currency": "USD",
        "interval": "month",
        "cents": True,
    },
]


class CheckoutBody(BaseModel):
    planId: str = Field(min_length=1, max_length=32)


class WebhookBody(BaseModel):
    checkoutId: str
    userId: str
    status: str


@router.get("/plans")
def plans():
    return envelope({"plans": PLANS}, message="plans")


@router.post("/checkout")
def checkout(
    body: CheckoutBody,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    plan = next((item for item in PLANS if item["id"] == body.planId), None)
    if plan is None:
        raise ApiError("Unknown plan.", 404)
    if plan["id"] == "free":
        state = store.billing.setdefault(user.id, BillingState())
        state.plan = "free"
        state.status = "active"
        return envelope(
            {"plan": "free", "status": "active", "checkoutId": None},
            message="free_plan",
        )
    state = store.billing.setdefault(user.id, BillingState())
    state.plan = plan["id"]
    state.status = "pending"
    state.checkout_id = f"chk_{user.id[:8]}_{plan['id']}"
    return envelope(
        {
            "plan": state.plan,
            "status": state.status,
            "checkoutId": state.checkout_id,
            "paid": False,
        },
        message="checkout_pending",
    )


@router.get("/status")
def status(
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    state = store.billing.setdefault(user.id, BillingState())
    return envelope(
        {
            "plan": state.plan,
            "status": state.status,
            "checkoutId": state.checkout_id,
            "paid": state.status == "active" and state.plan != "free",
        },
        message="billing_status",
    )


@router.post("/webhook")
def webhook(
    body: WebhookBody,
    store: Store = Depends(store_dep),
    x_qibra_signature: str | None = Header(default=None),
):
    settings = get_settings()
    if x_qibra_signature != settings.billing_webhook_secret:
        raise ApiError("Invalid webhook signature.", 401)
    user = store.get_user(body.userId)
    if user is None:
        raise ApiError("Unknown user.", 404)
    state = store.billing.setdefault(user.id, BillingState())
    if state.checkout_id != body.checkoutId:
        raise ApiError("Checkout mismatch.", 409)
    if body.status != "paid":
        return envelope({"applied": False, "status": state.status}, message="ignored")
    state.status = "active"
    return envelope(
        {"applied": True, "plan": state.plan, "status": state.status},
        message="paid",
    )
