"""Shared input checks aligned with the Flutter AppValidation constants."""

from __future__ import annotations

import re

from app.core.responses import ApiError

EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
NAME_RE = re.compile(r"^[a-zA-Z\u0600-\u06FF\s\-']{2,50}$")


def require_email(email: str | None) -> str:
    value = (email or "").strip()
    if not value:
        raise ApiError("Email is required")
    if len(value) > 100 or not EMAIL_RE.match(value):
        raise ApiError("Please enter a valid email address")
    return value.lower()


def require_password(password: str | None) -> str:
    value = password or ""
    if len(value) < 8:
        raise ApiError("Password must be at least 8 characters")
    if len(value) > 32:
        raise ApiError("Password is too long")
    return value


def require_name(name: str | None) -> str:
    value = (name or "").strip()
    if len(value) < 2:
        raise ApiError("Name must be at least 2 characters")
    if len(value) > 50 or not NAME_RE.match(value):
        raise ApiError("Name must be 2-50 characters (letters only)")
    return value


def clamp_limit(value: int | None, default: int = 20, maximum: int = 50) -> int:
    if value is None:
        return default
    return max(1, min(int(value), maximum))


def clamp_page(value: int | None) -> int:
    if value is None or value < 1:
        return 1
    return int(value)
