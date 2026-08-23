"""DUAS endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request

from app.core.responses import ApiError, success_response
from app.core.validation import clamp_limit
from app.services.dua_service import DuaService, get_dua_service

router = APIRouter(tags=["duas"])


@router.get("/duas")
def list_duas(
    request: Request,
    category: str | None = Query(default=None),
    service: DuaService = Depends(get_dua_service),
):
    return success_response(
        {
            "categories": service.list_categories(),
            "duas": service.list_duas(category),
        },
        message="Dua catalog",
        request=request,
    )


@router.get("/duas/category")
def get_category(
    request: Request,
    id: str | None = Query(default=None),
    name: str | None = Query(default=None),
    service: DuaService = Depends(get_dua_service),
):
    key = (id or name or "").strip()
    if not key:
        return success_response(
            {"categories": service.list_categories()},
            message="Dua categories",
            request=request,
        )
    found = service.get_category(key)
    if found is None:
        raise ApiError("Dua category not found", status_code=404)
    return success_response(found, message=found["nameEnglish"], request=request)


@router.get("/duas/search")
def search_duas(
    request: Request,
    q: str = Query(default=""),
    limit: int = Query(default=20),
    service: DuaService = Depends(get_dua_service),
):
    query = q.strip()
    if len(query) < 2:
        raise ApiError("Search query must be at least 2 characters")
    results = service.search(query, limit=clamp_limit(limit))
    return success_response(
        {"query": query, "count": len(results), "results": results},
        message="Dua search results",
        request=request,
    )
