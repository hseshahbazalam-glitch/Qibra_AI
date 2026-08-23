from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..core.deps import ApiError, current_user, store_dep
from ..core.responses import envelope
from ..services.store import Store, UserRecord

router = APIRouter(prefix="/sync", tags=["sync"])


class SyncPushBody(BaseModel):
    clientRev: int = Field(ge=0)
    profile: dict[str, Any] | None = None
    bookmarks: list[dict[str, Any]] = Field(default_factory=list)


@router.get("")
def pull(
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    return envelope(store.snapshot(user.id), message="sync_pull")


@router.post("")
def push(
    body: SyncPushBody,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    server_rev = store.sync_rev.get(user.id, 0)
    if body.clientRev < server_rev:
        raise ApiError(
            "Sync conflict. Pull first.",
            409,
            data={"server": store.snapshot(user.id)},
        )
    if body.profile and "name" in body.profile:
        store.update_user(user.id, name=str(body.profile.get("name") or user.name))
    if body.bookmarks:
        store.replace_bookmarks(user.id, body.bookmarks)
    else:
        store.sync_rev[user.id] = server_rev + 1
    return envelope(store.snapshot(user.id), message="sync_push")
