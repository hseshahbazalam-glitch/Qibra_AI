class StoreVerifier:
    """Play/App Store receipts are not configured."""

    configured = False

    def verify(self, receipt: str) -> bool:
        return False
