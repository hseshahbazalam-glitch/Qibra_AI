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
    this.aborted = false,
  });

  final int surah;
  final int bytes;
  final int filesPresent;
  final int filesTotal;
  final List<int> failedAyahs;

  /// True when the run was cancelled mid-flight (download-all): the
  /// per-file tallies below stay REAL (files on disk when the user hit
  /// cancel), only 'complete' can never be claimed.
  final bool aborted;

  bool get complete =>
      !aborted && failedAyahs.isEmpty && filesPresent == filesTotal;
}

/// One qari directory on disk (storage manager row). Numbers are sums
/// of REAL file lengths — 0-byte files count as absent, never as size.
typedef TilawatQariUsage = ({
  String dirName,
  String displayName,
  int bytes,
  int files,
});

class TilawatStorageReport {
  const TilawatStorageReport({required this.totalBytes, required this.perQari});

  final int totalBytes;
  final List<TilawatQariUsage> perQari;

  /// Pure tally from injected per-directory results — the storage UI
  /// total is defined as EXACTLY this sum (unit-tested without a disk).
  static int sumBytes(Iterable<TilawatQariUsage> rows) {
    var n = 0;
    for (final r in rows) {
      n += r.bytes;
    }
    return n;
  }
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
  Future<List<int?>> surahFileSizes(String rootPath, int surah,
      {TilawatQari? qari}) async {
    final dir = Directory(Tilawat.qariDirPath(rootPath, qari: qari));
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
  /// [qari] selects the download directory + URL set (defaults to the
  /// primary Alafasy — callers thread the user's pick through).
  /// [cancelled] is polled before EACH file: a mid-run cancel stops
  /// cleanly there and the result is reported with aborted=true.
  Future<TilawatDownloadResult> downloadSurah({
    required int surah,
    TilawatQari? qari,
    bool Function()? cancelled,
    void Function(int done, int total, int currentAyah, double fileFraction)?
        onProgress,
  }) async {
    final root = await rootDir();
    final dirPath = Tilawat.qariDirPath(root, qari: qari);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final names = Tilawat.surahFileNames(surah);
    final failed = <int>[];
    var done = 0;
    var aborted = false;
    for (int i = 0; i < names.length; i++) {
      if (cancelled != null && cancelled()) {
        // Break happens BEFORE any .part is opened for this index — no
        // partial-file strays; a later attempt simply tops up what is
        // still missing.
        aborted = true;
        break;
      }
      final ayah = i + 1;
      final finalPath = '$dirPath/${names[i]}';
      if (usableSize(finalPath) != null) {
        done++;
        onProgress?.call(done, names.length, ayah, 1);
        continue;
      }
      var ok = await _fetchOne(
          Tilawat.primaryUrl(surah, ayah, qari: qari), finalPath, onProgress,
          done, names.length, ayah);
      if (!ok) {
        final g = Tilawat.globalAyahNumber(
            surah: surah, ayah: ayah, numberInQuran: 0);
        ok = await _fetchOne(
            Tilawat.fallbackUrl(g, qari: qari), finalPath, onProgress, done,
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
      aborted: aborted,
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

  /// Real-disk storage view for the WHOLE tilawat cache: every sub-
  /// directory of '<root>/tilawat' contributes its own tally (catalog
  /// qaris by id; any leftover directory keeps its raw name — the
  /// report lists what is on disk, not what the catalog promises).
  /// SYNC enumeration (same reasoning as usableSize: a stat-cheap
  /// metadata sweep; the file count is bounded by 114·5·2 by design).
  TilawatStorageReport storageReportSync(String rootPath) {
    final base = Directory('$rootPath/tilawat');
    final rows = <TilawatQariUsage>[];
    if (!base.existsSync()) {
      return const TilawatStorageReport(totalBytes: 0, perQari: []);
    }
    for (final e in base.listSync()) {
      if (e is! Directory) continue;
      var bytes = 0, files = 0;
      for (final f in e.listSync(recursive: true)) {
        if (f is! File) continue;
        try {
          final len = f.lengthSync();
          if (len > 0) {
            bytes += len; // 0-byte strays count as NOTHING, never size
            files++;
          }
        } catch (_) {}
      }
      final name = e.path.split('/').last;
      TilawatQari? known;
      for (final q in Tilawat.qaris) {
        if (q.id == name) known = q;
      }
      rows.add((
        dirName: name,
        displayName: known?.displayName ?? name,
        bytes: bytes,
        files: files,
      ));
    }
    rows.sort((a, b) => a.dirName.compareTo(b.dirName));
    return TilawatStorageReport(
      totalBytes: TilawatStorageReport.sumBytes(rows),
      perQari: rows,
    );
  }

  /// Async wrapper used by providers/UI (disk enumeration is sync
  /// inside, same honesty, one await boundary).
  Future<TilawatStorageReport> storageReport() async {
    final root = await rootDir();
    return storageReportSync(root);
  }

  /// Delete EVERY tilawat file of EVERY qari (and .part leftovers).
  /// Best-effort per file with debug logging — returns the count of
  /// files actually removed so the UI can confirm with real numbers.
  Future<int> deleteEverything() async {
    final root = await rootDir();
    final base = Directory('$root/tilawat');
    if (!base.existsSync()) return 0;
    var removed = 0;
    for (final e in base.listSync()) {
      if (e is! Directory) continue;
      for (final f in e.listSync(recursive: true)) {
        if (f is! File) continue;
        try {
          f.deleteSync();
          removed++;
        } catch (err) {
          debugPrint('⚠️ tilawat delete failed (${f.path}): $err');
        }
      }
    }
    return removed;
  }

  /// Delete every downloaded file (and leftovers) for [surah].
  Future<void> deleteSurah(int surah, {TilawatQari? qari}) async {
    final root = await rootDir();
    final dir = Directory(Tilawat.qariDirPath(root, qari: qari));
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
