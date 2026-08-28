"""Phase 9 — offline / unknown is not online conceptually."""


def test_unknown_is_not_online():
    unknown = "unknown"
    assert unknown != "online"
    may_use_network = unknown == "online"
    assert may_use_network is False
