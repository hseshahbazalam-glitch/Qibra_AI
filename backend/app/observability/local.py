"""Local-only observability. Consent default OFF. No third-party SDKs."""

from dataclasses import dataclass, field

from .allowlist import is_allowed, is_forbidden


@dataclass
class Observability:
    consent: bool = False
    events: list[str] = field(default_factory=list)

    def record(self, name: str) -> None:
        if not self.consent:
            return
        if is_forbidden(name) or not is_allowed(name):
            return
        self.events.append(name)
        if len(self.events) > 50:
            self.events.pop(0)


observability = Observability()
