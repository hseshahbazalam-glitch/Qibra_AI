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

  /// Read the real disk state for [surah].
  Future<void> checkSurah(int surah) async {
    state = {...state, surah: const SurahAudioStatus(checking: true)};
    try {
      final root = await _dl.rootDir();
      final sizes = await _dl.surahFileSizes(root, surah);
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
    await _dl.deleteSurah(surah);
    await checkSurah(surah);
  }
}

final quranDownloadProvider =
    NotifierProvider<QuranDownloadController, Map<int, SurahAudioStatus>>(
  QuranDownloadController.new,
);
