"""Standard response envelope from docs/api/API_CONTRACT.md."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import Request
from fastapi.responses import JSONResponse


ENVELOPE_KEYS = ("success", "message", "data", "timestamp", "traceId")


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def new_trace_id(request: Request | None = None) -> str:
    if request is not None:
        existing = request.headers.get("x-trace-id") or request.headers.get("x-request-id")
        if existing:
            return existing
        stored = getattr(request.state, "trace_id", None)
        if stored:
            return stored
    return str(uuid.uuid4())


def envelope(
    *,
    success: bool,
    message: str,
    data: Any = None,
    trace_id: str | None = None,
) -> dict[str, Any]:
    return {
        "success": success,
        "message": message,
        "data": data,
        "timestamp": utc_timestamp(),
        "traceId": trace_id or str(uuid.uuid4()),
    }


def success_response(
    data: Any = None,
    message: str = "OK",
    status_code: int = 200,
    request: Request | None = None,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content=envelope(
            success=True,
            message=message,
            data=data,
            trace_id=new_trace_id(request),
        ),
    )


def error_response(
    message: str,
    status_code: int = 400,
    data: Any = None,
    request: Request | None = None,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content=envelope(
            success=False,
            message=message,
            data=data,
            trace_id=new_trace_id(request),
        ),
    )


class ApiError(Exception):
    def __init__(self, message: str, status_code: int = 400, data: Any = None) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.data = data
