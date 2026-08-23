from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from fastapi.responses import JSONResponse


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def envelope(
    data: Any = None,
    *,
    message: str = "ok",
    success: bool = True,
    status_code: int = 200,
    trace_id: str | None = None,
) -> JSONResponse:
    body = {
        "success": success,
        "message": message,
        "data": data,
        "timestamp": utc_now(),
        "traceId": trace_id or uuid4().hex,
    }
    return JSONResponse(status_code=status_code, content=body)


def error_envelope(
    message: str,
    *,
    status_code: int = 400,
    data: Any = None,
) -> JSONResponse:
    return envelope(
        data,
        message=message,
        success=False,
        status_code=status_code,
    )
