"""Conservative retry classifier. Permanent 4xx is not retried."""


def should_retry(*, http_status: int | None = None, timeout: bool = False, network_failure: bool = False) -> bool:
    if timeout or network_failure:
        return True
    if http_status is None:
        return False
    if 500 <= http_status <= 599:
        return True
    if http_status == 429:
        return True
    return False


def backoff_ms(attempt: int, *, max_ms: int = 30000, jitter_ms: int = 0) -> int:
    base = 250 * (1 << max(0, min(attempt, 6)))
    return min(max(base + jitter_ms, 250), max_ms)
