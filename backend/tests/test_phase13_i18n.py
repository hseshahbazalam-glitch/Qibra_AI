"""Phase 13 — locale/a11y contracts. No gen-l10n."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_pubspec_has_no_gen_l10n():
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    assert "generate: true" not in text
    assert "flutter_localizations:" in text


def test_app_strings_does_not_wrap_quran_source():
    text = (ROOT / "lib/core/l10n/app_strings.dart").read_text(encoding="utf-8")
    assert "navQuran" in text
    assert "quran_arabic" not in text
    assert "gen-l10n" in text.lower() or "Do not enable gen-l10n" in text


def test_locales_three():
    text = (ROOT / "lib/core/l10n/app_locales.dart").read_text(encoding="utf-8")
    assert "Locale('en')" in text
    assert "Locale('ar')" in text
    assert "Locale('ur')" in text


def test_min_tap_still_48():
    text = (ROOT / "lib/core/a11y/app_a11y.dart").read_text(encoding="utf-8")
    assert "minTapTarget = 48" in text
