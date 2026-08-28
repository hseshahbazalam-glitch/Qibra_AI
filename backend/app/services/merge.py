from datetime import datetime


def last_write_wins(a_updated: datetime, b_updated: datetime) -> str:
    if a_updated >= b_updated:
        return "a"
    return "b"
