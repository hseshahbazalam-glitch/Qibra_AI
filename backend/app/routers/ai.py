from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..core.deps import current_user
from ..core.responses import envelope
from ..services import ai_service
from ..services.store import UserRecord

router = APIRouter(prefix="/ai", tags=["ai"])


class ChatBody(BaseModel):
    message: str = Field(default="", max_length=2000)


class RefBody(BaseModel):
    ref: str = Field(default="", max_length=128)
    question: str = Field(default="", max_length=2000)


@router.post("/chat")
def chat(body: ChatBody, user: UserRecord = Depends(current_user)):
    return envelope(ai_service.answer(body.message, kind="chat"), message="ai")


@router.post("/ayah")
def ayah(body: RefBody, user: UserRecord = Depends(current_user)):
    prompt = body.question or body.ref
    return envelope(ai_service.answer(prompt, kind="ayah"), message="ai")


@router.post("/hadith")
def hadith(body: RefBody, user: UserRecord = Depends(current_user)):
    prompt = body.question or body.ref
    return envelope(ai_service.answer(prompt, kind="hadith"), message="ai")


@router.post("/dua")
def dua(body: RefBody, user: UserRecord = Depends(current_user)):
    prompt = body.question or body.ref
    return envelope(ai_service.answer(prompt, kind="dua"), message="ai")
