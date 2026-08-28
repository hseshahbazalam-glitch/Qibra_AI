"""Retrieval-only RAG. No passage = refuse. Never claim verified sources."""


def retrieve(query: str, corpus: list[dict]) -> list[dict]:
    q = query.lower().strip()
    if not q:
        return []
    hits = []
    for item in corpus:
        text = str(item.get("text", "")).lower()
        if q in text:
            hits.append(item)
    return hits


def answer(query: str, corpus: list[dict]) -> dict:
    passages = retrieve(query, corpus)
    if not passages:
        return {
            "refused": True,
            "reason": "no_retrieved_passage",
            "answer": None,
        }
    return {
        "refused": False,
        "answer": passages[0]["text"],
        "citations": [p.get("source") for p in passages],
        "verified": False,
    }
