// lib/features/quran/data/audio/tilawat.dart
// ============================================================
// QIBRA AI — TILAWAT (Quran recitation) PURE LOGIC
// ============================================================
// One qari (Mishary Rashid Alafasy), structured so future qaris are
// additive: register another TilawatQari and the whole chain (URLs,
// local paths, downloader, player) follows. NO audio files are ever
// bundled or committed — streaming + optional runtime downloads to
// app-internal storage only (the G15 static gate enforces this).
//
// Sources (verified reachable from the sandbox proxy at build time;
// curl itself is TLS-blocked there — device remains the authority):
//   primary  everyayah.com recitation archive (non-commercial web
//            distribution), file per ayah: SSSAAA.mp3
//   fallback cdn.islamic.network, file per GLOBAL ayah number 1..6236
//
// Global ayah numbers come from the app's OWN bundled data
// (AyahModel.numberInQuran), with a prefix-sum fallback computed from
// QuranMeta — the app's authoritative 114-surah ayah-count table. No
// duplicated hardcoded counts here.

import '../repository/quran_meta.dart';

/// A recitation qari. Adding P2 qaris = new constants of this class.
class TilawatQari {
  const TilawatQari({
    required this.id,
    required this.everyAyahDir,
    required this.islamicNetworkEdition,
    required this.displayName,
  });

  /// Stable identifier — used as the download subdirectory name.
  final String id;

  /// Directory name under everyayah.com/data/.
  final String everyAyahDir;

  /// Edition slug on cdn.islamic.network.
  final String islamicNetworkEdition;

  /// Display name for UI.
  final String displayName;
}

class Tilawat {
  const Tilawat._();

  static const TilawatQari alafasy = TilawatQari(
    id: 'ar.alafasy',
    everyAyahDir: 'Alafasy_128kbps',
    islamicNetworkEdition: 'ar.alafasy',
    displayName: 'Mishary Rashid Alafasy',
  );

  /// The single qari this build streams from. Future qaris: extend
  /// the list, keep index 0 primary.
  static const List<TilawatQari> qaris = [alafasy];
  static TilawatQari get current => qaris[0];

  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;

  /// Honest failure copy — shown verbatim when both sources fail.
  static const String offlineFailureMessage =
      'Recitation needs internet or a download';

  // ─── validation ─────────────────────────────────────────────

  /// Valid (surah, ayah) within the app's own metadata table.
  static bool validAyahRef(int surah, int ayah) {
    if (surah < 1 || surah > totalSurahs || ayah < 1) return false;
    return ayah <= _ayahCount(surah);
  }

  static int _ayahCount(int surah) => QuranMeta.ayahCount(surah);

  // ─── URL builders (pure; null on out-of-range input) ────────

  /// https://everyayah.com/data/<dir>/SSSAAA.mp3
  static String? primaryUrl(int surah, int ayah, {TilawatQari? qari}) {
    if (!validAyahRef(surah, ayah)) return null;
    final q = qari ?? current;
    return 'https://everyayah.com/data/${q.everyAyahDir}/'
        '${_p3(surah)}${_p3(ayah)}.mp3';
  }

  /// https://cdn.islamic.network/quran/audio/128/<edition>/<global>.mp3
  static String? fallbackUrl(int globalAyahNumber, {TilawatQari? qari}) {
    if (globalAyahNumber < 1 || globalAyahNumber > totalAyahs) return null;
    final q = qari ?? current;
    return 'https://cdn.islamic.network/quran/audio/128/'
        '${q.islamicNetworkEdition}/$globalAyahNumber.mp3';
  }

  /// Global ayah number (1..6236) from the app's own data: prefers the
  /// bundled AyahModel.numberInQuran; falls back to a prefix sum of
  /// QuranMeta per-surah counts + in-surah index. Never guessed.
  static int globalAyahNumber({
    required int surah,
    required int ayah,
    required int numberInQuran,
  }) {
    if (numberInQuran >= 1 && numberInQuran <= totalAyahs) {
      return numberInQuran;
    }
    if (surah < 1 || surah > totalSurahs || ayah < 1) return 0;
    var g = 0;
    for (int s = 1; s < surah; s++) {
      g += _ayahCount(s);
    }
    return g + ayah;
  }

  static String _p3(int n) => n.toString().padLeft(3, '0');

  /// m:ss player clock label. Used only with values the player has
  /// actually reported — callers must not pass invented durations.
  static String clockLabel(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final m = safe.inMinutes;
    final s = safe.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ─── local file layout ──────────────────────────────────────

  /// Root directory for a qari's downloads under the app-support dir.
  static String qariDirPath(String appSupportDir, {TilawatQari? qari}) =>
      '$appSupportDir/tilawat/${(qari ?? current).id}';

  /// '<dir>/<SSSAAA>.mp3' — pure string logic; existence is checked
  /// against the real filesystem by the caller.
  static String fileName(int surah, int ayah) =>
      '${_p3(surah)}${_p3(ayah)}.mp3';

  static String filePath(String appSupportDir, int surah, int ayah,
          {TilawatQari? qari}) =>
      '${qariDirPath(appSupportDir, qari: qari)}/${fileName(surah, ayah)}';

  /// Every file name a full surah download needs (per QuranMeta count).
  static List<String> surahFileNames(int surah) {
    if (surah < 1 || surah > totalSurahs) return const [];
    final count = _ayahCount(surah);
    return List<String>.generate(count, (i) => fileName(surah, i + 1));
  }

  /// Sum of positive file sizes; 0-byte or missing files contribute 0
  /// and mark the set INCOMPLETE (0-byte = failure, per the download
  /// rules — never treated as a good file).
  /// [sizes] is aligned to [expected]: null entry = missing/failed.
  static ({int bytes, int present, int total}) tallySurah(
      List<int?> sizes) {
    var bytes = 0, present = 0;
    for (final s in sizes) {
      if (s != null && s > 0) {
        bytes += s;
        present++;
      }
    }
    return (bytes: bytes, present: present, total: sizes.length);
  }

  // ─── queue advance ──────────────────────────────────────────

  /// Next index in the auto-advance queue, or null at the end of the
  /// surah (queue built from the real ayah list — it just runs out).
  static int? nextQueueIndex(int current, int length) {
    if (current < 0 || current + 1 >= length) return null;
    return current + 1;
  }

  // ─── attempt ladder (source selection) ──────────────────────

  /// Where the player looks for audio, in order. The ladder is pure so
  /// the "local → primary → fallback once → honest failure" rule is
  /// unit-tested independently of any plugin.
  static TilawatAttempt advance(TilawatAttempt a, {required bool ok}) {
    if (ok) return a; // a working source is kept; no churn
    switch (a) {
      case TilawatAttempt.local:
        return TilawatAttempt.primary;
      case TilawatAttempt.primary:
        return TilawatAttempt.fallback;
      case TilawatAttempt.fallback:
      case TilawatAttempt.failed:
        return TilawatAttempt.failed; // no silent retry loop
    }
  }
}

enum TilawatAttempt { local, primary, fallback, failed }
