"""AI endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Request

from app.core.responses import success_response
from app.services.ai_service import AiService, get_ai_service

router = APIRouter(tags=["ai"])


@router.post("/ai/chat")
def ai_chat(
    payload: dict[str, Any],
    request: Request,
    service: AiService = Depends(get_ai_service),
):
    return success_response(service.chat(payload or {}), message="AI chat", request=request)


@router.post("/ai/ayah")
def ai_ayah(
    payload: dict[str, Any],
    request: Request,
    service: AiService = Depends(get_ai_service),
):
    return success_response(service.explain_ayah(payload or {}), message="AI ayah", request=request)


@router.post("/ai/hadith")
def ai_hadith(
    payload: dict[str, Any],
    request: Request,
    service: AiService = Depends(get_ai_service),
):
    return success_response(
        service.explain_hadith(payload or {}),
        message="AI hadith",
        request=request,
    )


@router.post("/ai/dua")
def ai_dua(
    payload: dict[str, Any],
    request: Request,
    service: AiService = Depends(get_ai_service),
):
    return success_response(service.explain_dua(payload or {}), message="AI dua", request=request)
