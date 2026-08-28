from .entitlement import Entitlement
from .store_verify import StoreVerifier


class BillingService:
    def __init__(self) -> None:
        self.verifier = StoreVerifier()

    def status(self) -> dict:
        return {
            "store": "unconfigured",
            "billing_production_ready": False,
            "is_premium": False,
        }

    def entitlement_from_json(self, payload: dict) -> Entitlement:
        # Never trust client JSON.
        return Entitlement(is_premium=False, source="unconfigured")
