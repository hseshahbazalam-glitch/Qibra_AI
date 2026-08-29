from fastapi import APIRouter
from pydantic import BaseModel

from ..rag import answer

router = APIRouter(prefix="/ai", tags=["ai"])


class AskIn(BaseModel):
    query: str
    corpus: list[dict] = []


@router.post("/ask")
def ask(body: AskIn):
    # Do not log query, corpus, prompts, Quran, or Hadith text.
    return answer(body.query, body.corpus)
