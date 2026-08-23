"""TAFSIR endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request

from app.core.responses import ApiError, success_response
from app.core.validation import clamp_limit
from app.services.tafsir_service import TafsirService, get_tafsir_service

router = APIRouter(tags=["tafsir"])


@router.get("/tafsir")
def get_tafsir(
    request: Request,
    surah: int | None = Query(default=None),
    ayah: int | None = Query(default=None),
    service: TafsirService = Depends(get_tafsir_service),
):
    if surah is None and ayah is None:
        return success_response(service.sources(), message="Tafsir sources", request=request)
    if surah is None or ayah is None:
        raise ApiError("Both surah and ayah are required")
    return success_response(
        service.lookup(surah, ayah),
        message="Tafsir lookup",
        request=request,
    )


@router.get("/tafsir/search")
def search_tafsir(
    request: Request,
    q: str = Query(default=""),
    limit: int = Query(default=20),
    service: TafsirService = Depends(get_tafsir_service),
):
    query = q.strip()
    if len(query) < 2:
        raise ApiError("Search query must be at least 2 characters")
    return success_response(
        service.search(query, limit=clamp_limit(limit)),
        message="Tafsir search",
        request=request,
    )
