from datetime import datetime


def last_write_wins(a_updated: datetime, b_updated: datetime) -> str:
    if a_updated >= b_updated:
        return "a"
    return "b"


def bookmark_set_merge(local_ids: list[str], remote_ids: list[str], deleted_ids: list[str] | None = None) -> list[str]:
    """Set-union minus tombstones. Does not invent item ids."""
    deleted = set(deleted_ids or [])
    merged = {i for i in local_ids + remote_ids if i and i not in deleted}
    return sorted(merged)
