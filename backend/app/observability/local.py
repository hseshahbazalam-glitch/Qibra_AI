"""Local-only observability. Consent default OFF. No third-party SDKs."""

from dataclasses import dataclass, field


@dataclass
class Observability:
    consent: bool = False
    events: list[str] = field(default_factory=list)

    def record(self, name: str) -> None:
        if not self.consent:
            return
        banned = ("email", "token", "gps", "receipt", "ayah", "hadith", "prompt")
        blob = name.lower()
        if any(b in blob for b in banned):
            return
        self.events.append(name)


observability = Observability()
