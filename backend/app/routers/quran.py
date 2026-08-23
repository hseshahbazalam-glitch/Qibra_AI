"""QURAN endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request

from app.core.responses import ApiError, success_response
from app.core.validation import clamp_limit
from app.services.quran_service import QuranService, get_quran_service

router = APIRouter(tags=["quran"])


@router.get("/quran")
def list_quran(request: Request, service: QuranService = Depends(get_quran_service)):
    surahs = service.list_surahs()
    return success_response(
        {"surahs": surahs, "totals": service.totals},
        message="Quran index",
        request=request,
    )


@router.get("/quran/search")
def search_quran(
    request: Request,
    q: str = Query(default="", min_length=0),
    limit: int = Query(default=20),
    service: QuranService = Depends(get_quran_service),
):
    query = q.strip()
    if len(query) < 2:
        raise ApiError("Search query must be at least 2 characters")
    results = service.search(query, limit=clamp_limit(limit))
    return success_response(
        {"query": query, "count": len(results), "results": results},
        message="Quran search results",
        request=request,
    )


@router.get("/quran/juz")
def list_or_get_juz(
    request: Request,
    id: int | None = Query(default=None),
    number: int | None = Query(default=None),
    service: QuranService = Depends(get_quran_service),
):
    juz_id = id or number
    if juz_id is None:
        return success_response(
            {"juz": service.list_juz()},
            message="Juz index",
            request=request,
        )
    found = service.get_juz(juz_id)
    if found is None:
        raise ApiError("Juz not found", status_code=404)
    return success_response(found, message=f"Juz {juz_id}", request=request)


@router.get("/quran/surah/{id}")
def get_surah(
    id: int,
    request: Request,
    service: QuranService = Depends(get_quran_service),
):
    found = service.get_surah(id)
    if found is None:
        raise ApiError("Surah not found", status_code=404)
    return success_response(found, message=found["name"], request=request)
