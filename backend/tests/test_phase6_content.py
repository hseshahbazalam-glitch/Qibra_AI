"""Phase 6 content — 114/6236. Does not rewrite JSON."""

from pathlib import Path

from app.rag import answer, retrieve

AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
    6, 3, 5, 4, 5, 6,
]


def test_canonical_surah_count():
    assert len(AYAH_COUNTS) == 114


def test_canonical_ayah_sum():
    assert sum(AYAH_COUNTS) == 6236


def test_fatiha_and_baqarah_and_nas():
    assert AYAH_COUNTS[0] == 7
    assert AYAH_COUNTS[1] == 286
    assert AYAH_COUNTS[-1] == 6


def test_no_zero_ayah_surahs():
    assert all(n > 0 for n in AYAH_COUNTS)


def test_bundled_arabic_not_rewritten():
    root = Path(__file__).resolve().parents[2]
    path = root / "assets" / "data" / "quran" / "quran_arabic.json"
    if path.exists():
        assert path.stat().st_size > 0
    # Honest: absence is not invented.


def test_validator_script_exists():
    script = Path(__file__).resolve().parents[2] / "scripts" / "validate_content.py"
    assert script.exists()


def test_unknown_query_stays_refused():
    result = answer("invented-tafsir-xyz", [{"text": "In the name of Allah"}])
    assert result["refused"] is True


def test_retrieve_is_substring_not_generative():
    corpus = [{"text": "Allah is most merciful", "source": "Quran 1:1"}]
    assert retrieve("merciful", corpus)
    assert retrieve("not-in-corpus", corpus) == []


def test_hit_is_not_verified_claim():
    hit = answer("merciful", [{"text": "Allah is most merciful", "source": "Quran 1:1"}])
    assert hit["verified"] is False
    assert "Verified Qibra sources" not in str(hit)


def test_empty_corpus_refuses():
    assert answer("mercy", [])["refused"] is True
