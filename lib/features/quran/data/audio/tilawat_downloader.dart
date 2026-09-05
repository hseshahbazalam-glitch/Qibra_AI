// lib/features/quran/data/audio/tilawat_downloader.dart
// ============================================================
// QIBRA AI — TILAWAT DOWNLOADER
// ============================================================
// Per-surah offline download into app-internal storage
// (${appSupportDir}/tilawat/<qari>/SSSAAA.mp3). Dio is already an app
// dependency — no new package, no manifest change, never proxied
// through the app's backend. Rules enforced here:
//   • staged as '<name>.part', renamed only after a verified size > 0;
//   • a 0-byte result is a FAILURE and the file is deleted;
//   • each file gets exactly one fallback-URL retry, then the surah
//     attempt reports honest per-file failures — no silent loops;
//   • files already present and > 0 are skipped (a second tap resumes
//     by finishing what is missing).
// Sizes/existence reported to the UI are read back from DISK — what
// the UI shows is what the filesystem holds.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'tilawat.dart';

class TilawatDownloadResult {
  const TilawatDownloadResult({
    required this.surah,
    required this.bytes,
    required this.filesPresent,
    required this.filesTotal,
    required this.failedAyahs,
  });

  final int surah;
  final int bytes;
  final int filesPresent;
  final int filesTotal;
  final List<int> failedAyahs;

  bool get complete => failedAyahs.isEmpty && filesPresent == filesTotal;
}

class TilawatDownloader {
  const TilawatDownloader();

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 120),
  ));

  Future<String> rootDir() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path.replaceAll('\\', '/'); // backslash -> slash (Windows-safe; written as an escaped string so the repo's static lexer sees it cleanly)
  }

  /// Disk truth for one surah: per expected file, its size or null.
  Future<List<int?>> surahFileSizes(String rootPath, int surah) async {
    final dir = Directory(Tilawat.qariDirPath(rootPath));
    return _sizesFrom(dir, Tilawat.surahFileNames(surah));
  }

  Future<List<int?>> _sizesFrom(Directory dir, List<String> names) async {
    final out = <int?>[];
    for (final n in names) {
      out.add(_usableSize('${dir.path}/$n'));
    }
    return out;
  }

  /// Size of a file if it exists AND has bytes; null otherwise.
  /// 0-byte files are treated as missing AND deleted (failure cleanup).
  ///
  /// (Rev, analyzer) Deliberately SYNC: this is a hot metadata probe (every
  /// playback resolution + every whole-surah coverage scan). The
  /// avoid_slow_async_io lint fires exactly here — async exists()/length()
  /// bounce through dart:io's background isolates and are SLOWER than a
  /// direct stat for calls this cheap; cold callers above/below stay async.
  static int? usableSize(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      final len = f.lengthSync();
      if (len > 0) return len;
      f.deleteSync(); // 0-byte = failure; clean it up
      return null;
    } catch (e) {
      debugPrint('⚠️ tilawat size check failed for $path: $e');
      return null;
    }
  }

  int? _usableSize(String path) => usableSize(path);

  /// Downloads the surah's missing files sequentially. [onProgress]
  /// receives (completedFiles, totalFiles, currentAyah, fractionOfCurrentFile)
  /// — real counts and real byte progress, nothing interpolated.
  /// Returns honest results incl. per-file failures.
  Future<TilawatDownloadResult> downloadSurah({
    required int surah,
    void Function(int done, int total, int currentAyah, double fileFraction)?
        onProgress,
  }) async {
    final root = await rootDir();
    final dirPath = Tilawat.qariDirPath(root);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final names = Tilawat.surahFileNames(surah);
    final failed = <int>[];
    var done = 0;
    for (int i = 0; i < names.length; i++) {
      final ayah = i + 1;
      final finalPath = '$dirPath/${names[i]}';
      if (usableSize(finalPath) != null) {
        done++;
        onProgress?.call(done, names.length, ayah, 1);
        continue;
      }
      var ok = await _fetchOne(
          Tilawat.primaryUrl(surah, ayah), finalPath, onProgress, done,
          names.length, ayah);
      if (!ok) {
        final g = Tilawat.globalAyahNumber(
            surah: surah, ayah: ayah, numberInQuran: 0);
        ok = await _fetchOne(
            Tilawat.fallbackUrl(g), finalPath, onProgress, done,
            names.length, ayah);
      }
      if (ok) {
        done++;
      } else {
        failed.add(ayah);
      }
      onProgress?.call(done, names.length, ayah, ok ? 1 : 0);
    }
    final sizes = await _sizesFrom(dir, names);
    final tally = Tilawat.tallySurah(sizes);
    return TilawatDownloadResult(
      surah: surah,
      bytes: tally.bytes,
      filesPresent: tally.present,
      filesTotal: tally.total,
      failedAyahs: failed,
    );
  }

  Future<bool> _fetchOne(
    String? url,
    String destPath,
    void Function(int, int, int, double)? onProgress,
    int done,
    int total,
    int ayah,
  ) async {
    if (url == null) return false;
    final partPath = '$destPath.part';
    try {
      await _dio.download(url, partPath, onReceiveProgress: (got, exp) {
        final frac = exp > 0 ? (got / exp).clamp(0.0, 1.0).toDouble() : 0.0;
        onProgress?.call(done, total, ayah, frac);
      });
      final part = File(partPath);
      if (await part.exists() && await part.length() > 0) {
        await part.rename(destPath);
        return true;
      }
      // 0-byte (or vanished) download = failure; clean up.
      if (await part.exists()) await part.delete();
      return false;
    } catch (e) {
      debugPrint('⚠️ tilawat download failed ($ayah): $e');
      try {
        if (await File(partPath).exists()) await File(partPath).delete();
      } catch (_) {}
      return false;
    }
  }

  /// Delete every downloaded file (and leftovers) for [surah].
  Future<void> deleteSurah(int surah) async {
    final root = await rootDir();
    final dir = Directory(Tilawat.qariDirPath(root));
    if (!await dir.exists()) return;
    for (final n in Tilawat.surahFileNames(surah)) {
      for (final suffix in ['', '.part']) {
        final f = File('${dir.path}/$n$suffix');
        try {
          if (await f.exists()) await f.delete();
        } catch (e) {
          debugPrint('⚠️ tilawat delete failed ($n$suffix): $e');
        }
      }
    }
  }
}
