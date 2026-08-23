from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..core.deps import current_user, store_dep
from ..core.responses import envelope
from ..services.store import Store, UserRecord

router = APIRouter(tags=["users"])


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=80)


@router.get("/users/me")
def me(user: UserRecord = Depends(current_user)):
    return envelope(user.public(), message="profile")


@router.put("/users/me")
def update_me(
    body: ProfileUpdate,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    updated = store.update_user(user.id, name=body.name)
    return envelope(updated.public(), message="updated")


@router.get("/profile")
def profile(user: UserRecord = Depends(current_user)):
    return envelope(user.public(), message="profile")


@router.put("/profile")
def update_profile(
    body: ProfileUpdate,
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    updated = store.update_user(user.id, name=body.name)
    return envelope(updated.public(), message="updated")


@router.delete("/profile")
def delete_profile(
    user: UserRecord = Depends(current_user),
    store: Store = Depends(store_dep),
):
    store.delete_user(user.id)
    return envelope({"id": user.id, "deleted": True}, message="deleted")
