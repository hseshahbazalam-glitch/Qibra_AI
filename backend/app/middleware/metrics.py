import time

from starlette.middleware.base import BaseHTTPMiddleware

from ..observability.metrics import inc, observe_ms


class MetricsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        started = time.perf_counter()
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - started) * 1000
        observe_ms(elapsed_ms)
        inc("api_request")
        code = response.status_code
        if code >= 500:
            inc("api_5xx")
        elif code >= 400:
            inc("api_4xx")
        else:
            inc("api_ok")
        return response
