from datetime import datetime, timezone

from .entitlement import Entitlement, NONE, derive
from .store_verify import StoreVerifier


class BillingService:
    def __init__(self) -> None:
        self.verifier = StoreVerifier()

    def status(self) -> dict:
        return {
            "store": "unconfigured",
            "billing_production_ready": False,
            "is_premium": False,
            "state": NONE,
            "restore_available": False,
            "server_validated": False,
        }

    def entitlement_from_json(self, payload: dict) -> Entitlement:
        _ = payload
        return Entitlement(is_premium=False, source="unconfigured")

    def verify_payload(self, payload: dict | None, *, now: datetime | None = None) -> dict:
        payload = payload if isinstance(payload, dict) else {}
        receipt = str(payload.get("receipt") or payload.get("purchase_token") or "")
        platform = str(payload.get("platform") or "")
        result = self.verifier.verify_purchase(receipt, platform)
        ent = derive(
            verified=result.verified,
            now=now or datetime.now(timezone.utc),
            source="store_unconfigured",
            store="unconfigured",
        )
        return {
            "ok": False,
            "reason": result.reason,
            "is_premium": ent.is_premium,
            "state": ent.state,
            "server_validated": ent.server_validated,
        }

    def restore(self) -> dict:
        return {
            "ok": False,
            "reason": "store_unconfigured",
            "purchases": [],
            "is_premium": False,
            "state": NONE,
        }
