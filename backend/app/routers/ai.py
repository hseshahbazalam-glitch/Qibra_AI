from fastapi import APIRouter
from pydantic import BaseModel, Field, field_validator

from ..rag import answer

router = APIRouter(prefix="/ai", tags=["ai"])

_MAX_CORPUS_ITEMS = 32


class AskIn(BaseModel):
    query: str
    corpus: list[dict] = Field(default_factory=list)

    @field_validator("corpus")
    @classmethod
    def _cap_corpus(cls, value: list[dict]) -> list[dict]:
        if len(value) > _MAX_CORPUS_ITEMS:
            raise ValueError("corpus_too_large")
        return value


@router.post("/ask")
def ask(body: AskIn):
    # Unauthenticated on purpose (test_ask_does_not_require_auth).
    # Do not log query, corpus, prompts, Quran, or Hadith text.
    return answer(body.query, body.corpus)
