"""PROFILE endpoints from docs/api/API_CONTRACT.md."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field

from app.core.deps import require_user
from app.core.responses import ApiError, success_response
from app.core.validation import require_name
from app.services.user_store import UserRecord, UserStore, get_user_store

router = APIRouter(tags=["profile"])


class ProfileUpdateBody(BaseModel):
    name: str | None = Field(default=None, max_length=50)
    avatar_url: str | None = None
    phone_number: str | None = None
    language: str | None = None
    theme: str | None = None


@router.get("/profile")
def get_profile(request: Request, user: UserRecord = Depends(require_user)):
    return success_response(user.public_dict(), message="Profile loaded", request=request)


@router.put("/profile")
def update_profile(
    body: ProfileUpdateBody,
    request: Request,
    user: UserRecord = Depends(require_user),
    store: UserStore = Depends(get_user_store),
):
    fields = body.model_dump(exclude_unset=True)
    if "name" in fields and fields["name"] is not None:
        fields["name"] = require_name(fields["name"])
    if fields.get("language") not in {None, "en", "ar", "ur"}:
        raise ApiError("Unsupported language")
    if fields.get("theme") not in {None, "dark", "light", "system"}:
        raise ApiError("Unsupported theme")
    updated = store.update_profile(user.id, fields)
    if updated is None:
        raise ApiError("Account not found", status_code=404)
    return success_response(updated.public_dict(), message="Profile updated", request=request)


@router.delete("/profile")
def delete_profile(
    request: Request,
    user: UserRecord = Depends(require_user),
    store: UserStore = Depends(get_user_store),
):
    store.delete_user(user.id)
    return success_response({"deleted": True, "id": user.id}, message="Profile deleted", request=request)
