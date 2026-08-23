from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..core.deps import ApiError, current_user, store_dep
from ..core.responses import envelope
from ..services.store import Store, UserRecord

router = APIRouter(prefix="/bookmarks", tags=["bookmarks"])


class BookmarkBody(BaseModel):
    kind: str = Field(min_length=1, max_length=32)
    ref: str = Field(min_length=1, max_length=128)
    note: str | None = Field(default=None, max_length=500)


@router.get("")
def list_bookmarks(
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    items = [item.public() for item in store.list_bookmarks(user.id)]
    return envelope({"items": items, "count": len(items)}, message="bookmarks")


@router.post("")
def create_bookmark(
    body: BookmarkBody,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    item = store.add_bookmark(user.id, body.kind, body.ref, body.note)
    return envelope(item.public(), message="created", status_code=201)


@router.delete("/{bookmark_id}")
def delete_bookmark(
    bookmark_id: str,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    if not store.delete_bookmark(user.id, bookmark_id):
        raise ApiError("Bookmark not found.", 404)
    return envelope({"id": bookmark_id, "deleted": True}, message="deleted")
