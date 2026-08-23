"""Retrieval-only AI. Does not invent Quran, Hadith, or fatwa text."""

from typing import Any

KNOWN_TOPICS = {
    "prayer": "Prayer times and Qibla live on-device. This backend does not calculate them.",
    "qibla": "Qibla direction is computed on the device from the user's location.",
    "bookmark": "Bookmarks can be saved through /bookmarks and synced through /sync.",
    "billing": "Billing plans are listed at /billing/plans. Checkout stays unpaid until a signed webhook arrives.",
}


def answer(prompt: str, *, kind: str = "chat") -> dict[str, Any]:
    text = (prompt or "").strip()
    if not text:
        return {
            "kind": kind,
            "answer": None,
            "citations": [],
            "honest": True,
            "reason": "empty_prompt",
            "message": "No question was provided.",
        }

    lowered = text.lower()
    matches = [
        {"topic": topic, "note": note}
        for topic, note in KNOWN_TOPICS.items()
        if topic in lowered
    ]
    if not matches:
        return {
            "kind": kind,
            "answer": None,
            "citations": [],
            "honest": True,
            "reason": "no_retrieval",
            "message": (
                "No retrieved source is available for this question. "
                "Qibra will not invent Quran, Hadith, or a fatwa."
            ),
        }

    return {
        "kind": kind,
        "answer": matches[0]["note"],
        "citations": [{"source": "backend-index", "topic": m["topic"]} for m in matches],
        "honest": True,
        "reason": "retrieved",
        "message": "Answer limited to retrieved backend notes.",
    }
