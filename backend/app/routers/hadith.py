"""HADITH endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request

from app.core.responses import ApiError, success_response
from app.core.validation import clamp_limit, clamp_page
from app.services.hadith_service import HadithService, get_hadith_service

router = APIRouter(tags=["hadith"])


@router.get("/hadith")
def list_hadith(
    request: Request,
    collection: str | None = Query(default=None),
    page: int = Query(default=1),
    limit: int = Query(default=20),
    service: HadithService = Depends(get_hadith_service),
):
    resolved = service.resolve_collection(collection) if collection else None
    if collection and resolved is None:
        raise ApiError("Unknown hadith collection", status_code=404)
    if resolved:
        payload = service.list_hadiths(
            collection=resolved,
            page=clamp_page(page),
            limit=clamp_limit(limit),
        )
        return success_response(payload, message="Hadith list", request=request)
    return success_response(
        {"collections": service.list_collections()},
        message="Hadith collections",
        request=request,
    )


@router.get("/hadith/search")
def search_hadith(
    request: Request,
    q: str = Query(default=""),
    collection: str | None = Query(default=None),
    limit: int = Query(default=20),
    service: HadithService = Depends(get_hadith_service),
):
    query = q.strip()
    if len(query) < 2:
        raise ApiError("Search query must be at least 2 characters")
    resolved = service.resolve_collection(collection) if collection else "bukhari"
    if collection and service.resolve_collection(collection) is None:
        raise ApiError("Unknown hadith collection", status_code=404)
    results = service.search(query, limit=clamp_limit(limit), collection=resolved)
    return success_response(
        {"query": query, "count": len(results), "results": results},
        message="Hadith search results",
        request=request,
    )


@router.get("/hadith/book")
def get_book(
    request: Request,
    name: str | None = Query(default=None),
    collection: str | None = Query(default=None),
    page: int = Query(default=1),
    limit: int = Query(default=20),
    service: HadithService = Depends(get_hadith_service),
):
    book_name = name or collection
    if not book_name:
        raise ApiError("Provide a book name")
    found = service.get_book(book_name, page=clamp_page(page), limit=clamp_limit(limit))
    if found is None:
        raise ApiError("Hadith book not found", status_code=404)
    return success_response(found, message=found["name"], request=request)
