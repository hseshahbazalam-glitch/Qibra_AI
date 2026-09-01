"""Redact secrets and PII from log-like strings. Never keep the original."""

from __future__ import annotations

import re

_EMAIL = re.compile(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", re.I)
_BEARER = re.compile(r"bearer\s+\S+", re.I)
_JWT = re.compile(r"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}")
_LATLNG = re.compile(r"\b(?:lat|lng|lon|latitude|longitude)\s*[:=]\s*-?\d+(?:\.\d+)?", re.I)


def redact(text: str) -> str:
    if not text:
        return ""
    out = _EMAIL.sub("[redacted-email]", text)
    out = _BEARER.sub("bearer [redacted]", out)
    out = _JWT.sub("[redacted-jwt]", out)
    out = _LATLNG.sub("[redacted-geo]", out)
    return out
