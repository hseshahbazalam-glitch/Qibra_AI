from dataclasses import dataclass


@dataclass(frozen=True)
class Entitlement:
    is_premium: bool
    source: str
