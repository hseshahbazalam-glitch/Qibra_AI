"""Play/App Store receipts are not configured. Never invent a pass."""

from dataclasses import dataclass


@dataclass(frozen=True)
class VerificationResult:
    verified: bool
    reason: str
    platform: str = "unknown"


class StoreVerifier:
    configured = False

    def verify(self, receipt: str) -> bool:
        return False

    def verify_purchase(self, receipt: str, platform: str = "") -> VerificationResult:
        _ = receipt  # do not log
        return VerificationResult(
            verified=False,
            reason="store_unconfigured",
            platform=platform or "unknown",
        )
