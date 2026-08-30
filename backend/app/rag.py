"""Retrieval-only RAG. No passage = refuse. Never claim verified sources."""


def retrieval_mode(passages: list, *, remote: bool = False) -> str:
    if not passages:
        return "NO_CONTEXT"
    return "REMOTE_RETRIEVAL" if remote else "LOCAL_RETRIEVAL"


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


def production_corpus(corpus: list[dict]) -> list[dict]:
    """Only VERIFIED rows may enter production RAG. UNKNOWN stays out."""
    out = []
    for item in corpus:
        status = str(item.get("verification_status") or item.get("status") or "")
        if status == "VERIFIED":
            out.append(item)
    return out


def _provenance(passage: dict) -> dict:
    return {
        "source_id": passage.get("source_id"),
        "source_name": passage.get("source_name") or passage.get("source"),
        "collection": passage.get("collection"),
        "edition": passage.get("edition"),
        "translator": passage.get("translator"),
        "license": passage.get("license"),
        "license_url": passage.get("license_url"),
        "copyright_status": passage.get("copyright_status"),
        "attribution_required": passage.get("attribution_required"),
        "verified_at": passage.get("verified_at"),
        "verification_status": passage.get("verification_status")
        or passage.get("status")
        or "UNKNOWN",
        "reference": passage.get("reference") or passage.get("source"),
    }


def answer(query: str, corpus: list[dict]) -> dict:
    passages = retrieve(query, corpus)
    if not passages:
        return {
            "refused": True,
            "reason": "no_retrieved_passage",
            "answer": None,
        }
    citations = []
    provenance = []
    for passage in passages:
        source = passage.get("source")
        if isinstance(source, str) and source.strip():
            citations.append(source.strip())
        provenance.append(_provenance(passage))
    return {
        "refused": False,
        "answer": passages[0]["text"],
        "citations": citations,
        "verified": False,
        "provenance": provenance,
        "production_rag_eligible": False,
    }


def answer_production(query: str, corpus: list[dict]) -> dict:
    return answer(query, production_corpus(corpus))
