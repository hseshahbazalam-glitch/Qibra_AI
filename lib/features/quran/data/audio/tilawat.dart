// lib/features/quran/data/audio/tilawat.dart
// ============================================================
// QIBRA AI — TILAWAT (Quran recitation) PURE LOGIC
// ============================================================
// Five registered qaris (Pass Q1), structured additively: registering
// another TilawatQari makes the whole chain (URLs, local paths,
// downloader, player, picker) follow. NO audio files are ever
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

/// Hifz repeat modes (Pass Q1). Explicit user state only — the player
/// never re-arms on its own; every loop is a consequence of one of
/// these three values chosen in the UI.
enum QuranRepeatMode { off, ayah, range }

/// Range-picking stages for the tap-a-start-then-tap-an-end flow.
enum QuranRangePick { none, start, end }

/// What the repeat machine decided after an ayah finished playing.
enum TilawatRepeatAction { replay, advance, jump, stop }

class Tilawat {
  const Tilawat._();

  static const TilawatQari alafasy = TilawatQari(
    id: 'ar.alafasy',
    everyAyahDir: 'Alafasy_128kbps',
    islamicNetworkEdition: 'ar.alafasy',
    displayName: 'Mishary Rashid Alafasy',
  );

  // Pass Q1 (2026-09-11): four more qaris. VERIFICATION — everyayah
  // directory names are taken verbatim from the site's own recitations
  // index (everyayah.com, fetched 2026-09-11: the reciter dropdown
  // lists 'Abdul_Basit_Murattal_192kbps', 'Husary_128kbps',
  // 'Minshawy_Murattal_128kbps', 'Abdurrahmaan_As-Sudais_192kbps'
  // alongside 'Alafasy_128kbps'); cdn.islamic.network edition slugs are
  // taken from the live alquran.cloud audio-editions API (fetched the
  // same day: ar.abdulbasitmurattal, ar.husary, ar.minshawi,
  // ar.abdurrahmaansudais all present). Abdul Basit ships the MURATTAL
  // edition for consistency with the other verse-by-verse streams
  // (the CDN also carries a mujawwad edition; not used here).

  static const TilawatQari abdulBasitMurattal = TilawatQari(
    id: 'ar.abdulbasitmurattal',
    everyAyahDir: 'Abdul_Basit_Murattal_192kbps',
    islamicNetworkEdition: 'ar.abdulbasitmurattal',
    displayName: 'Abdul Basit Abdus-Samad',
  );

  static const TilawatQari minshawi = TilawatQari(
    id: 'ar.minshawi',
    everyAyahDir: 'Minshawy_Murattal_128kbps',
    islamicNetworkEdition: 'ar.minshawi',
    displayName: 'Mohamed Siddiq El-Minshawi',
  );

  static const TilawatQari husary = TilawatQari(
    id: 'ar.husary',
    everyAyahDir: 'Husary_128kbps',
    islamicNetworkEdition: 'ar.husary',
    displayName: 'Mahmoud Khalil Al-Husary',
  );

  static const TilawatQari sudais = TilawatQari(
    id: 'ar.abdurrahmaansudais',
    everyAyahDir: 'Abdurrahmaan_As-Sudais_192kbps',
    islamicNetworkEdition: 'ar.abdurrahmaansudais',
    displayName: 'Abdurrahman As-Sudais',
  );

  /// Registered qaris. Index 0 is the primary/default (Alafasy) — the
  /// honest fallback for unknown ids and the pre-picker default.
  static const List<TilawatQari> qaris = [
    alafasy,
    abdulBasitMurattal,
    minshawi,
    husary,
    sudais,
  ];
  static TilawatQari get current => qaris[0];

  /// Stable id of the default qari (prefs/notifications layers reference
  /// this without importing the list).
  static const String defaultQariId = 'ar.alafasy';

  /// Resolve a persisted qari id. Unknown ids fall back to the primary
  /// Alafasy entry — never a crash, never a guessed slug (the picker can
  /// only write catalog ids; the fallback covers stale prefs/versions).
  static TilawatQari byId(String id) {
    for (final q in qaris) {
      if (q.id == id) return q;
    }
    return current;
  }

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

  /// Prev index mirror for the mini-player's ⏮ button: null before the
  /// first item. Semantics mirror the forward edge deliberately: the
  /// queue just runs out there (honest stop), so running out backwards
  /// behaves the same — prev on the first ayah STOPS instead of wrapping.
  static int? previousQueueIndex(int current, int length) {
    if (current <= 0 || current >= length) return null;
    return current - 1;
  }

  // ─── hifz: repeat machine (pure; unit-tested without any audio) ──

  /// Hard honesty cap for ayah-repeat: the UI offers 1/3/5 and
  /// '×20 (max)' — NO uncapped ∞ mode exists, so a mis-tap can never
  /// produce the silent endless loop the player comments forbid.
  static const int maxAyahRepeats = 20;
  static const List<int> repeatCountChoices = [1, 3, 5, 20];

  static int clampRepeatCount(int n) =>
      n < 1 ? 1 : (n > maxAyahRepeats ? maxAyahRepeats : n);

  /// Playback speeds this build supports (UI chips ↔ just_audio
  /// setSpeed; anything else is rejected at the setter, not clamped).
  static const List<double> knownSpeeds = [0.75, 1.0, 1.25, 1.5];
  static bool isKnownSpeed(double v) => knownSpeeds.contains(v);

  /// Decision taken when the ayah at the current queue index just
  /// finished. [timesDone] counts completions of THIS ayah already.
  /// Range bounds are ayah numbers (0 = unset); reversed bounds are
  /// normalized here, never rejected (the tap flow picks them in any
  /// order). An unset/one-ayah range on a finished last ayah still
  /// jumps — that is the explicit loop the user asked for.
  static ({TilawatRepeatAction action, int targetAyah}) repeatDecision({
    required QuranRepeatMode mode,
    required int timesDone,
    required int timesTarget,
    required int currentAyah,
    required int rangeStart,
    required int rangeEnd,
    required bool hasNext,
  }) {
    switch (mode) {
      case QuranRepeatMode.off:
        return (
          action: hasNext ? TilawatRepeatAction.advance : TilawatRepeatAction.stop,
          targetAyah: 0,
        );
      case QuranRepeatMode.ayah:
        if (timesDone < clampRepeatCount(timesTarget)) {
          return (action: TilawatRepeatAction.replay, targetAyah: currentAyah);
        }
        return (
          action: hasNext ? TilawatRepeatAction.advance : TilawatRepeatAction.stop,
          targetAyah: 0,
        );
      case QuranRepeatMode.range:
        if (rangeStart <= 0 || rangeEnd <= 0) {
          // Range mode without a picked range must NOT invent bounds —
          // behaves like off until the user taps start and end.
          return (
            action: hasNext ? TilawatRepeatAction.advance : TilawatRepeatAction.stop,
            targetAyah: 0,
          );
        }
        final lo = rangeStart < rangeEnd ? rangeStart : rangeEnd;
        final hi = rangeStart < rangeEnd ? rangeEnd : rangeStart;
        if (currentAyah >= hi) {
          return (action: TilawatRepeatAction.jump, targetAyah: lo);
        }
        return hasNext
            ? (action: TilawatRepeatAction.advance, targetAyah: 0)
            : (action: TilawatRepeatAction.jump, targetAyah: lo);
    }
  }

  // ─── download-all + storage math (pure) ─────────────────────

  /// Real file count a full-Quran download spans: the sum of the app's
  /// OWN per-surah ayah table (never the constant, so a metadata fix
  /// propagates; equals totalAyahs while the table is 6236).
  static int filesForAllSurahs() {
    var n = 0;
    for (int s = 1; s <= totalSurahs; s++) {
      n += _ayahCount(s);
    }
    return n;
  }

  /// Aggregation over one-per-surah results of a 'download all' run.
  /// A surah counts DONE only when every expected file is present and
  /// nothing failed for it; bytes/present/total are summed verbatim.
  static ({
    int surahsDone,
    int surahsFailed,
    int filesDone,
    int filesTotal,
    int bytes,
  }) tallyAll(
      List<({int present, int total, int bytes, List<int> failed})> perSurah) {
    var surahsDone = 0, surahsFailed = 0, filesDone = 0, filesTotal = 0, bytes = 0;
    for (final r in perSurah) {
      filesDone += r.present;
      filesTotal += r.total;
      bytes += r.bytes;
      if (r.failed.isEmpty && r.total > 0 && r.present == r.total) {
        surahsDone++;
      } else {
        surahsFailed++;
      }
    }
    return (
      surahsDone: surahsDone,
      surahsFailed: surahsFailed,
      filesDone: filesDone,
      filesTotal: filesTotal,
      bytes: bytes,
    );
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
