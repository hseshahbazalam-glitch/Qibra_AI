"""Phase 12 — conservative perf / single-flight style guard."""


def test_single_flight_guard():
    in_flight = False

    def run():
        nonlocal in_flight
        if in_flight:
            return "skipped"
        in_flight = True
        try:
            return "ran"
        finally:
            in_flight = False

    assert run() == "ran"
