// lib/features/quran/providers/quran_download_provider.dart
// ============================================================
// QIBRA AI — TILAWAT DOWNLOAD PROVIDER (P2 audio stage)
// ============================================================
// Per-surah download status shown in the reader. Every number here
// comes from the real filesystem or the real Dio progress callback:
//   • present/total from disk stats of the surah's expected files
//     (QuranMeta ayah counts — the app's own metadata),
//   • bytes summed from disk (never estimated),
//   • per-file byte fraction from onReceiveProgress.
// States: unknown → notDownloaded / partial / downloaded(size) /
// downloading(done/total · fraction) / failed(n). A 0-byte file is
// failure, cleaned up by the downloader — never shown as "downloaded".

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/tilawat.dart';
import '../data/audio/tilawat_downloader.dart';
import 'reading_preferences_provider.dart';

@immutable
class SurahAudioStatus {
  const SurahAudioStatus({
    this.checking = true,
    this.downloading = false,
    this.done = 0,
    this.total = 0,
    this.fileFraction,
    this.bytes = 0,
    this.failed = 0,
  });

  final bool checking;
  final bool downloading;

  /// Files on disk with size > 0 (or, while downloading, completed so far).
  final int done;
  final int total;

  /// Byte progress of the file currently downloading (0..1), null idle.
  final double? fileFraction;
  final int bytes;

  /// Files that failed in the last attempt (honest, not retried silently).
  final int failed;

  bool get noneOnDisk => !downloading && !checking && done == 0;
  bool get partial => !downloading && !checking && done > 0 && done < total;
  bool get downloaded =>
      !downloading && !checking && total > 0 && done == total;

  String get label {
    if (checking) return 'Checking…';
    if (downloading) {
      final pct = fileFraction != null
          ? ' · ${(fileFraction! * 100).round()}%'
          : '';
      return 'Downloading $done/$total$pct';
    }
    if (downloaded) return 'Downloaded · ${bytesLabel(bytes)}';
    if (partial) return 'Partly saved ($done/$total)';
    return 'Not downloaded';
  }

  static String bytesLabel(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class QuranDownloadController extends Notifier<Map<int, SurahAudioStatus>> {
  final TilawatDownloader _dl = const TilawatDownloader();

  @override
  Map<int, SurahAudioStatus> build() => const {};

  SurahAudioStatus statusFor(int surah) =>
      state[surah] ?? const SurahAudioStatus();

  /// Per-surah status is scoped to the SELECTED qari (Pass Q1): a
  /// download for Al-Husary must not report Minshawi's files. The map
  /// keeps per-surah keys — a qari switch re-checks (the reader calls
  /// checkSurah again on select; honest, cheap).
  TilawatQari get _selectedQari =>
      Tilawat.byId(ref.read(readingPreferencesProvider).qariId);

  /// Read the real disk state for [surah].
  Future<void> checkSurah(int surah) async {
    state = {...state, surah: const SurahAudioStatus(checking: true)};
    try {
      final root = await _dl.rootDir();
      final sizes =
          await _dl.surahFileSizes(root, surah, qari: _selectedQari);
      final tally = Tilawat.tallySurah(sizes);
      state = {
        ...state,
        surah: SurahAudioStatus(
          checking: false,
          done: tally.present,
          total: tally.total,
          bytes: tally.bytes,
        ),
      };
    } catch (_) {
      // Storage unreadable: honest "not downloaded" with nothing claimed.
      state = {...state, surah: const SurahAudioStatus(checking: false)};
    }
  }

  Future<void> startDownload(int surah) async {
    if (statusFor(surah).downloading) return; // one live attempt per surah
    final total = Tilawat.surahFileNames(surah).length;
    if (total == 0) return;
    state = {
      ...state,
      surah: SurahAudioStatus(checking: false, downloading: true, total: total),
    };
    try {
      final res = await _dl.downloadSurah(
        surah: surah,
        qari: _selectedQari,
        onProgress: (done, tot, ayah, frac) {
          state = {
            ...state,
            surah: SurahAudioStatus(
              checking: false,
              downloading: true,
              done: done,
              total: tot,
              fileFraction: frac,
            ),
          };
        },
      );
      state = {
        ...state,
        surah: SurahAudioStatus(
          checking: false,
          done: res.filesPresent,
          total: res.filesTotal,
          bytes: res.bytes,
          failed: res.failedAyahs.length,
        ),
      };
    } catch (e) {
      debugPrint('⚠️ tilawat download crashed: $e');
      state = {
        ...state,
        surah: SurahAudioStatus(
            checking: false, done: state[surah]?.done ?? 0, total: total),
      };
    }
  }

  Future<void> deleteDownload(int surah) async {
    await _dl.deleteSurah(surah, qari: _selectedQari);
    await checkSurah(surah);
  }

  /// Reciter-picker badge math: real presence (n/total files on disk)
  /// for [surah] across EVERY catalog qari, straight from the filesystem
  /// — no cache, no estimates; 'Downloadable' is simply present < total.
  Future<Map<String, ({int present, int total})>>
      presenceForSurahAcrossQaris(int surah) async {
    final out = <String, ({int present, int total})>{};
    try {
      final root = await _dl.rootDir();
      for (final q in Tilawat.qaris) {
        final sizes = await _dl.surahFileSizes(root, surah, qari: q);
        final t = Tilawat.tallySurah(sizes);
        out[q.id] = (present: t.present, total: t.total);
      }
    } catch (e) {
      debugPrint('⚠️ tilawat presence scan failed: $e');
    }
    return out;
  }
}

final quranDownloadProvider =
    NotifierProvider<QuranDownloadController, Map<int, SurahAudioStatus>>(
  QuranDownloadController.new,
);

// ─── Pass Q1: download-all (sequential, cancellable) ─────────────────────

@immutable
class DownloadAllState {
  const DownloadAllState({
    this.running = false,
    this.finished = false,
    this.cancelRequested = false,
    this.cancelled = false,
    this.filesDone = 0,
    this.filesTotal = 0,
    this.surahsDone = 0,
    this.surahsFailed = 0,
    this.bytes = 0,
  });

  final bool running;
  final bool finished;
  final bool cancelRequested;

  /// True when a run ENDED because the user cancelled (finished+stopped,
  /// not an automatic restart — the next start() resumes by topping up).
  final bool cancelled;
  final int filesDone;

  /// Real table sum (Tilawat.filesForAllSurahs — 6236 while the app's
  /// per-surah metadata sums to it), not an estimate.
  final int filesTotal;
  final int surahsDone;
  final int surahsFailed;
  final int bytes;

  DownloadAllState copyWith({
    bool? running,
    bool? finished,
    bool? cancelRequested,
    bool? cancelled,
    int? filesDone,
    int? filesTotal,
    int? surahsDone,
    int? surahsFailed,
    int? bytes,
  }) {
    return DownloadAllState(
      running: running ?? this.running,
      finished: finished ?? this.finished,
      cancelRequested: cancelRequested ?? this.cancelRequested,
      cancelled: cancelled ?? this.cancelled,
      filesDone: filesDone ?? this.filesDone,
      filesTotal: filesTotal ?? this.filesTotal,
      surahsDone: surahsDone ?? this.surahsDone,
      surahsFailed: surahsFailed ?? this.surahsFailed,
      bytes: bytes ?? this.bytes,
    );
  }
}

class QuranDownloadAllController extends Notifier<DownloadAllState> {
  final TilawatDownloader _dl = const TilawatDownloader();
  bool _cancel = false;

  @override
  DownloadAllState build() => const DownloadAllState();

  /// One sequential pass over ALL 114 surahs for the selected qari —
  /// explicitly NO parallel floods (the downloader is already
  /// per-file sequential; this adds per-surah sequencing). Progress is
  /// aggregated from the real per-surah results via Tilawat.tallyAll.
  Future<void> start() async {
    if (state.running) return; // one live 'all' — like one per surah
    final qari =
        Tilawat.byId(ref.read(readingPreferencesProvider).qariId);
    _cancel = false;
    state = DownloadAllState(
      running: true,
      filesTotal: Tilawat.filesForAllSurahs(),
    );
    final results =
        <({int present, int total, int bytes, List<int> failed})>[];
    for (int s = 1; s <= Tilawat.totalSurahs; s++) {
      if (_cancel) {
        state = state.copyWith(running: false, cancelled: true, finished: true);
        return;
      }
      final r = await _dl.downloadSurah(
        surah: s,
        qari: qari,
        cancelled: () => _cancel,
      );
      results.add((
        present: r.filesPresent,
        total: r.filesTotal,
        bytes: r.bytes,
        failed: r.failedAyahs,
      ));
      final agg = Tilawat.tallyAll(results);
      state = state.copyWith(
        filesDone: agg.filesDone,
        bytes: agg.bytes,
        surahsDone: agg.surahsDone,
        surahsFailed: agg.surahsFailed,
      );
      if (r.aborted) {
        state = state.copyWith(running: false, cancelled: true, finished: true);
        return;
      }
    }
    state = state.copyWith(running: false, finished: true);
  }

  /// Honest cancel: flips the flag checked before every file — the run
  /// ends after its current file, never mid-byte.
  void cancel() {
    if (!state.running) return;
    _cancel = true;
    state = state.copyWith(cancelRequested: true);
  }
}

final quranDownloadAllProvider =
    NotifierProvider<QuranDownloadAllController, DownloadAllState>(
  QuranDownloadAllController.new,
);

// ─── Pass Q1: storage manager (real filesystem only) ─────────────────────

class QuranStorageController extends Notifier<TilawatStorageReport?> {
  final TilawatDownloader _dl = const TilawatDownloader();

  @override
  TilawatStorageReport? build() => null;

  Future<void> refresh() async {
    try {
      state = await _dl.storageReport();
    } catch (e) {
      debugPrint('⚠️ tilawat storage scan failed: $e');
      state = null; // unreadable disk = nothing claimed, never 0-as-fact
    }
  }

  /// Delete all caches, then re-scan — the UI afterwards shows the NEW
  /// real state, not an assumed empty one.
  Future<void> deleteEverything() async {
    try {
      final removed = await _dl.deleteEverything();
      debugPrint('tilawat: removed $removed files (all qaris)');
    } catch (e) {
      debugPrint('⚠️ tilawat delete-all failed: $e');
    }
    await refresh();
  }
}

final quranStorageProvider =
    NotifierProvider<QuranStorageController, TilawatStorageReport?>(
  QuranStorageController.new,
);
