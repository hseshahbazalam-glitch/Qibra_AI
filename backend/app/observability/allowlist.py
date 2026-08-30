"""Privacy-safe event names only. No GPS, email, tokens, receipts, scripture, prompts."""

ALLOWED_EVENTS = frozenset(
    {
        "opened_home",
        "opened_prayer",
        "opened_quran",
        "opened_more",
        "sync_ok",
        "sync_conflict",
        "sync_fail",
        "cache_hit",
        "cache_miss",
        "cache_stale",
        "notif_plan",
        "rag_local",
        "rag_no_context",
        "billing_unconfigured",
        "api_ok",
        "api_error",
        "crash_hook",
    }
)

BANNED_SUBSTR = (
    "email",
    "token",
    "gps",
    "latitude",
    "longitude",
    "receipt",
    "ayah",
    "hadith",
    "prompt",
    "password",
    "secret",
)


def is_forbidden(name: str) -> bool:
    blob = name.lower()
    return any(b in blob for b in BANNED_SUBSTR)


def is_allowed(name: str) -> bool:
    if is_forbidden(name):
        return False
    return name in ALLOWED_EVENTS
