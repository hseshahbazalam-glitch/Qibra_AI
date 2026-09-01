"""Transport online ≠ backend healthy."""

LOCAL_ONLY = "LOCAL_ONLY"
NETWORK_AVAILABLE = "NETWORK_AVAILABLE"
BACKEND_AVAILABLE = "BACKEND_AVAILABLE"


def plane(*, may_use_network: bool, backend_enabled: bool, backend_healthy: bool) -> str:
    if not may_use_network:
        return LOCAL_ONLY
    if not backend_enabled or not backend_healthy:
        return NETWORK_AVAILABLE
    return BACKEND_AVAILABLE


def may_use_network(reachability: str) -> bool:
    return reachability == "online"
