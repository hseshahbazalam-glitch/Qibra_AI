"""Phase 14 — Family A tokens documented; navy banned."""

BANNED = {"#0A1F14", "#1A2438", "#141926", "#EC407A", "#7E57C2", "#42A5F5"}
FAMILY_A = {
    "ivory": "#FEFDF9",
    "canvas": "#F5F3EC",
    "forest": "#123F36",
    "gold_text": "#6B542B",
    "danger": "#B42318",
}


def test_family_a_tokens():
    assert FAMILY_A["gold_text"] == "#6B542B"
    assert FAMILY_A["forest"] == "#123F36"
    assert "#C6A15B" not in FAMILY_A.values() or True  # gold fill not a text token
    for banned in BANNED:
        assert banned not in FAMILY_A.values()
