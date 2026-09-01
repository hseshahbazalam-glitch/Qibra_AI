"""Phase 6 — live JSON integrity + license honesty. Does not rewrite assets."""

from app.config import Settings
from app.content.integrity import (
    EXPECTED_AYAHS,
    EXPECTED_SURAHS,
    hadith_dir,
    load_manifest,
    quran_dir,
    repo_root,
    scan_hadith,
    validate_arabic,
    validate_cloud_translation,
    validate_manifest,
    validate_tanzil_translation,
)
from app.rag import answer, answer_production, production_corpus, retrieve


def test_arabic_114_6236_ordered_no_empty_no_dups():
    report = validate_arabic()
    assert report["surahs"] == EXPECTED_SURAHS
    assert report["ayahs"] == EXPECTED_AYAHS
    assert report["empty_text"] == 0
    assert report["duplicate_global_numbers"] == 0
    assert report["ordering_ok"] is True
    assert report["ok"] is True
    assert report["edition"]["identifier"] == "quran-uthmani"


def test_arabic_bom_on_first_ayah_is_recorded_not_rewritten():
    report = validate_arabic()
    assert report["bom_ayahs"] == 1


def test_english_asad_6236_requires_permission_not_verified():
    report = validate_cloud_translation(quran_dir() / "translation_en.json")
    assert report["ok"] is True
    assert report["edition"]["identifier"] == "en.asad"
    assert report["edition"]["englishName"] == "Muhammad Asad"


def test_urdu_row_counts_and_tahir_empty_not_filled():
    files = sorted(quran_dir().glob("translation_ur_*.json"))
    assert len(files) == 6
    tahir = None
    for path in files:
        report = validate_tanzil_translation(path)
        assert report["rows"] == EXPECTED_AYAHS
        assert report["duplicate_pairs"] == 0
        assert report["surahs"] == EXPECTED_SURAHS
        if "tahirulqadri" in path.name:
            tahir = report
        else:
            assert report["empty_text"] == 0
    assert tahir is not None
    assert tahir["empty_text"] == 217


def test_tafsir_asset_bundled_with_pinned_provenance():
    # Retired guard (content pass 2026-09-02, owner-approved): the abridged
    # English Ibn Kathir dataset IS bundled now — but only with pinned
    # upstream provenance and a non-VERIFIED license posture.
    root = repo_root()
    asset = root / "assets" / "data" / "tafsir" / "ibn_kathir_en.json"
    assert asset.exists()
    import json as _json

    data = _json.loads(asset.read_text(encoding="utf-8"))
    meta = data["metadata"]
    assert meta["license"] == "UNKNOWN"
    assert meta["upstream_repo"] == "https://github.com/spa5k/tafsir_api"
    assert len(meta["upstream_commit"]) == 40
    assert meta["credit"] == "Tafsir Ibn Kathir (abridged, Eng. tr.)"
    assert len(data["surahs"]) == 114



def test_hadith_no_duplicate_ids_all_files_present():
    # Content pass (2026-09-02) backfilled tirmidhi/urdu.json from the same
    # dataset family; the old expectation that it be MISSING is retired.
    rows = scan_hadith()
    assert len(rows) == 21
    missing = [r for r in rows if not r["exists"]]
    assert missing == []
    for row in rows:
        if not row["exists"]:
            continue
        assert row["duplicate_ids"] == 0
        assert row["records"] > 0
        assert row["ok"] is True


def test_hadith_dir_layout():
    root = hadith_dir()
    assert (root / "bukhari" / "english.json").exists()
    assert (root / "tirmidhi" / "urdu.json").exists()  # backfilled in content pass


def test_manifest_never_verified_without_license_file():
    manifest = load_manifest()
    check = validate_manifest(manifest)
    assert check["ok"] is True
    assert check["has_verified"] is False
    assert check["verified_without_license"] == []
    statuses = {row["status"] for row in manifest["sources"]}
    assert "VERIFIED" not in statuses
    asad = next(r for r in manifest["sources"] if r["id"] == "quran_en_asad")
    assert asad["status"] == "REQUIRES_PERMISSION"
    tafsir = next(r for r in manifest["sources"] if r["id"] == "tafsir_ibn_kathir")
    # Content pass bundled the abridged English dataset verbatim (owner-
    # approved 2026-09-02). Status moves DO_NOT_DISTRIBUTE -> REQUIRES_PERMISSION:
    # still NOT VERIFIED — translation rights are undocumented; a license file
    # in-repo is the only path to VERIFIED (note #1 above stays enforced).
    assert tafsir["status"] == "REQUIRES_PERMISSION"


def test_content_production_ready_stays_false():
    assert Settings().content_production_ready is False


def test_production_rag_excludes_unverified():
    corpus = [
        {
            "text": "Allah is most merciful",
            "source": "Quran 1:1",
            "verification_status": "UNKNOWN",
            "collection": "quran",
        }
    ]
    assert production_corpus(corpus) == []
    refused = answer_production("merciful", corpus)
    assert refused["refused"] is True
    local = answer("merciful", corpus)
    assert local["verified"] is False
    assert local["production_rag_eligible"] is False
    assert local["provenance"][0]["verification_status"] == "UNKNOWN"
    assert retrieve("not-in-corpus", corpus) == []
