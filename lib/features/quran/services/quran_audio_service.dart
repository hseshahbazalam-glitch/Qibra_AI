// lib/features/quran/services/quran_audio_service.dart

// ============================================================
// QIBRA AI — QURAN AUDIO SERVICE (v9.0 — audioplayers engine)
// ============================================================
// NEW ENGINE: audioplayers (uses Android MediaPlayer)
// Solves: All Oppo/OnePlus AudioTrack conflicts
// Strategy: Download → Cache → Play from local file
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================
// SECTION 1 — AUDIO STATUS
// ============================================================

enum QuranAudioStatus {
  idle,
  downloading,
  loading,
  playing,
  paused,
  completed,
  error,
}

// ============================================================
// SECTION 2 — PLAY MODE
// ============================================================

enum PlayMode {
  single,
  continuous,
  repeat,
}

// ============================================================
// SECTION 3 — RECITER
// ============================================================

class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.everyAyahFolder,
    required this.bitrate,
  });

  final String id;
  final String name;
  final String nameArabic;
  final String everyAyahFolder;
  final int bitrate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QuranReciter && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

abstract final class QuranReciters {
  static const QuranReciter alafasy = QuranReciter(
    id: 'alafasy',
    name: 'Mishary Rashid Alafasy',
    nameArabic: 'مشاري راشد العفاسي',
    everyAyahFolder: 'Alafasy_128kbps',
    bitrate: 128,
  );

  static const QuranReciter sudais = QuranReciter(
    id: 'sudais',
    name: 'Abdul Rahman Al-Sudais',
    nameArabic: 'عبد الرحمن السديس',
    everyAyahFolder: 'Abdurrahmaan_As-Sudais_192kbps',
    bitrate: 192,
  );

  static const QuranReciter abdulBasit = QuranReciter(
    id: 'abdulbasit',
    name: 'Abdul Basit Abdul Samad',
    nameArabic: 'عبد الباسط عبد الصمد',
    everyAyahFolder: 'Abdul_Basit_Mujawwad_128kbps',
    bitrate: 128,
  );

  static const QuranReciter husary = QuranReciter(
    id: 'husary',
    name: 'Mahmoud Khalil Al-Husary',
    nameArabic: 'محمود خليل الحصري',
    everyAyahFolder: 'Husary_128kbps',
    bitrate: 128,
  );

  static const QuranReciter ghamdi = QuranReciter(
    id: 'ghamdi',
    name: 'Saad Al-Ghamdi',
    nameArabic: 'سعد الغامدي',
    everyAyahFolder: 'Ghamadi_40kbps',
    bitrate: 40,
  );

  static const List<QuranReciter> all = [
    alafasy,
    sudais,
    abdulBasit,
    husary,
    ghamdi,
  ];

  static const QuranReciter defaultReciter = alafasy;
}

// ============================================================
// SECTION 4 — AUDIO STATE
// ============================================================

class QuranAudioState {
  const QuranAudioState({
    this.status = QuranAudioStatus.idle,
    this.surahNumber,
    this.ayahNumber,
    this.reciter = QuranReciters.defaultReciter,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.playMode = PlayMode.continuous,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.bitrate = 128,
    this.currentRepeatCount = 0,
    this.progress = 0.0,
    this.downloadProgress = 0.0,
  });

  final QuranAudioStatus status;
  final int? surahNumber;
  final int? ayahNumber;
  final QuranReciter reciter;
  final Duration position;
  final Duration duration;
  final String? error;
  final PlayMode playMode;
  final double playbackSpeed;
  final double volume;
  final int bitrate;
  final int currentRepeatCount;
  final double progress;
  final double downloadProgress;

  String get positionFormatted => _formatDuration(position);
  String get durationFormatted => _formatDuration(duration);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isPlaying => status == QuranAudioStatus.playing;
  bool get isPaused => status == QuranAudioStatus.paused;
  bool get isDownloading => status == QuranAudioStatus.downloading;
  bool get isLoading =>
      status == QuranAudioStatus.loading ||
      status == QuranAudioStatus.downloading;
  bool get isIdle => status == QuranAudioStatus.idle;
  bool get hasError => status == QuranAudioStatus.error;
  bool get isCompleted => status == QuranAudioStatus.completed;
  bool get isActive => surahNumber != null && ayahNumber != null;
  bool get isAutoPlayEnabled => playMode == PlayMode.continuous;

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    int? surahNumber,
    int? ayahNumber,
    QuranReciter? reciter,
    Duration? position,
    Duration? duration,
    String? error,
    PlayMode? playMode,
    double? playbackSpeed,
    double? volume,
    int? bitrate,
    int? currentRepeatCount,
    double? progress,
    double? downloadProgress,
    bool clearError = false,
    bool clearAyah = false,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      surahNumber: clearAyah ? null : (surahNumber ?? this.surahNumber),
      ayahNumber: clearAyah ? null : (ayahNumber ?? this.ayahNumber),
      reciter: reciter ?? this.reciter,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      playMode: playMode ?? this.playMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      bitrate: bitrate ?? this.bitrate,
      currentRepeatCount: currentRepeatCount ?? this.currentRepeatCount,
      progress: progress ?? this.progress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

// ============================================================
// SECTION 5 — AUDIO SERVICE (audioplayers engine)
// ============================================================

class QuranAudioService {
  QuranAudioService() {
    _initPlayer();
    _initCacheDir();
  }

  // Single AudioPlayer instance — reusable, no crashes
  final AudioPlayer _player = AudioPlayer();
  Directory? _cacheDir;
  final Dio _dio = Dio();

  // Subscriptions
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _completionSub;

  // Callbacks
  void Function(QuranAudioState state)? onStateChanged;
  void Function(int surahNumber, int ayahNumber)? onAyahCompleted;

  QuranAudioState _state = const QuranAudioState();
  QuranAudioState get currentState => _state;

  int _playRequestId = 0;
  final Set<String> _prefetchInProgress = {};

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[QIBRA_AUDIO] $message');
    }
  }

  // ─── PLAYER INIT ───────────────────────────────

  void _initPlayer() {
    // Position updates
    _positionSub = _player.onPositionChanged.listen((position) {
      _updateState(
        _state.copyWith(
          position: position,
          progress: _state.duration.inMilliseconds > 0
              ? position.inMilliseconds / _state.duration.inMilliseconds
              : 0.0,
        ),
      );
    });

    // Duration updates
    _durationSub = _player.onDurationChanged.listen((duration) {
      _updateState(_state.copyWith(duration: duration));
    });

    // Player state changes
    _playerStateSub = _player.onPlayerStateChanged.listen((playerState) {
      _log('State: $playerState');
      switch (playerState) {
        case PlayerState.playing:
          _updateState(_state.copyWith(status: QuranAudioStatus.playing));
          break;
        case PlayerState.paused:
          _updateState(_state.copyWith(status: QuranAudioStatus.paused));
          break;
        case PlayerState.stopped:
          break;
        case PlayerState.completed:
          break;
        case PlayerState.disposed:
          break;
      }
    });

    // Completion event (SINGLE handler — no duplicates)
    _completionSub = _player.onPlayerComplete.listen((_) {
      _handleAyahCompleted();
    });

    _log('Player initialized');
  }

  // ─── CACHE DIRECTORY ───────────────────────────

  Future<void> _initCacheDir() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/quran_audio_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      _log('Cache dir: ${_cacheDir!.path}');
    } catch (e) {
      _log('Cache init error: $e');
    }
  }

  String _getCachedFilePath(
    int surahNumber,
    int ayahNumber,
    QuranReciter reciter,
  ) {
    if (_cacheDir == null) return '';
    final fileName = '${reciter.id}_${surahNumber}_$ayahNumber.mp3';
    return '${_cacheDir!.path}/$fileName';
  }

  bool _isCached(int surahNumber, int ayahNumber, QuranReciter reciter) {
    final path = _getCachedFilePath(surahNumber, ayahNumber, reciter);
    if (path.isEmpty) return false;
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 500;
  }

  // ─── HANDLE COMPLETION ─────────────────────────

  void _handleAyahCompleted() {
    _log('Ayah completed: ${_state.surahNumber}:${_state.ayahNumber}');
    _updateState(_state.copyWith(status: QuranAudioStatus.completed));

    final surah = _state.surahNumber;
    final ayah = _state.ayahNumber;

    if (surah != null && ayah != null && onAyahCompleted != null) {
      onAyahCompleted!(surah, ayah);
    }
  }

  // ─── DOWNLOAD FILE ─────────────────────────────

  Future<bool> _downloadFile(
    String url,
    String savePath,
    int requestId,
  ) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (requestId != _playRequestId) return;
          if (total > 0) {
            final progress = received / total;
            _updateState(_state.copyWith(downloadProgress: progress));
          }
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final file = File(savePath);
      if (await file.exists() && await file.length() > 500) {
        return true;
      }
      return false;
    } catch (e) {
      _log('Download error: $e');
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      return false;
    }
  }

  // ─── URL BUILDER ───────────────────────────────

  String _buildStreamUrl(
    int surahNumber,
    int ayahNumber,
    QuranReciter reciter,
  ) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${reciter.everyAyahFolder}/$surah$ayah.mp3';
  }

  // ─── PLAY AYAH ─────────────────────────────────

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
    QuranReciter? reciter,
  }) async {
    _playRequestId++;
    final requestId = _playRequestId;

    final selectedReciter = reciter ?? _state.reciter;

    _log('→ Play $surahNumber:$ayahNumber (${selectedReciter.name})');

    try {
      // Stop current playback first
      await _player.stop();

      // Update state
      _updateState(
        _state.copyWith(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          reciter: selectedReciter,
          position: Duration.zero,
          duration: Duration.zero,
          progress: 0.0,
          downloadProgress: 0.0,
          currentRepeatCount: 0,
          clearError: true,
        ),
      );

      // Wait for cache dir
      if (_cacheDir == null) await _initCacheDir();

      final localPath = _getCachedFilePath(
        surahNumber,
        ayahNumber,
        selectedReciter,
      );

      // Check cache
      if (_isCached(surahNumber, ayahNumber, selectedReciter)) {
        _log('Playing from cache');
        await _playFromFile(localPath, requestId);
      } else {
        // Download
        _log('Downloading...');
        _updateState(_state.copyWith(status: QuranAudioStatus.downloading));

        final url = _buildStreamUrl(surahNumber, ayahNumber, selectedReciter);

        final downloaded = await _downloadFile(url, localPath, requestId);

        if (requestId != _playRequestId) return;

        if (downloaded) {
          _log('Downloaded OK');
          await _playFromFile(localPath, requestId);
        } else {
          _updateState(
            _state.copyWith(
              status: QuranAudioStatus.error,
              error: 'Download failed. Check internet.',
            ),
          );
          return;
        }
      }

      // Pre-fetch next ayahs in background
      _prefetchNextAyahs(surahNumber, ayahNumber, selectedReciter);
    } catch (e) {
      _log('Play error: $e');
      _updateState(
        _state.copyWith(
          status: QuranAudioStatus.error,
          error: 'Audio play failed.',
        ),
      );
    }
  }

  Future<void> _playFromFile(String filePath, int requestId) async {
    try {
      if (requestId != _playRequestId) return;

      _updateState(_state.copyWith(status: QuranAudioStatus.loading));

      // Set volume
      await _player.setVolume(_state.volume);

      // Set playback rate
      await _player.setPlaybackRate(_state.playbackSpeed);

      if (requestId != _playRequestId) return;

      // Play using DeviceFileSource (native path)
      await _player.play(DeviceFileSource(filePath));

      _log('→ PLAYING');
    } catch (e) {
      _log('Play file error: $e');
      _updateState(
        _state.copyWith(
          status: QuranAudioStatus.error,
          error: 'Audio playback failed.',
        ),
      );
    }
  }

  // ─── PRE-FETCH ─────────────────────────────────

  void _prefetchNextAyahs(
    int surahNumber,
    int currentAyah,
    QuranReciter reciter,
  ) {
    for (int i = 1; i <= 3; i++) {
      final nextAyah = currentAyah + i;
      _prefetchSingleAyah(surahNumber, nextAyah, reciter);
    }
  }

  Future<void> _prefetchSingleAyah(
    int surahNumber,
    int ayahNumber,
    QuranReciter reciter,
  ) async {
    if (_isCached(surahNumber, ayahNumber, reciter)) return;

    final key = '${reciter.id}_${surahNumber}_$ayahNumber';
    if (_prefetchInProgress.contains(key)) return;
    _prefetchInProgress.add(key);

    try {
      final localPath = _getCachedFilePath(surahNumber, ayahNumber, reciter);
      final url = _buildStreamUrl(surahNumber, ayahNumber, reciter);

      await _dio.download(
        url,
        localPath,
        options: Options(
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      _log('Prefetched $surahNumber:$ayahNumber');
    } catch (e) {
      // Silent fail — not critical
    } finally {
      _prefetchInProgress.remove(key);
    }
  }

  // ─── PLAYBACK CONTROLS ─────────────────────────

  Future<void> pause() async {
    try {
      await _player.pause();
      _log('→ PAUSED');
    } catch (e) {
      _log('Pause error: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
      _log('→ RESUMED');
    } catch (e) {
      _log('Resume error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else if (_state.isPaused) {
      await resume();
    }
  }

  Future<void> stop() async {
    try {
      _playRequestId++;
      await _player.stop();
      _updateState(const QuranAudioState());
      _log('→ STOPPED');
    } catch (e) {
      _log('Stop error: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      _log('Seek error: $e');
    }
  }

  Future<void> seekToFraction(double fraction) async {
    if (_state.duration == Duration.zero) return;
    final position = Duration(
      milliseconds: (_state.duration.inMilliseconds * fraction).round(),
    );
    await seekTo(position);
  }

  // ─── SETTINGS ──────────────────────────────────

  Future<void> setReciter(QuranReciter reciter) async {
    _updateState(_state.copyWith(reciter: reciter));
    _log('Reciter: ${reciter.name}');
  }

  Future<void> setVolume(double volume) async {
    try {
      final clamped = volume.clamp(0.0, 1.0);
      await _player.setVolume(clamped);
      _updateState(_state.copyWith(volume: clamped));
    } catch (e) {
      _log('Volume error: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      final clamped = speed.clamp(0.5, 2.0);
      await _player.setPlaybackRate(clamped);
      _updateState(_state.copyWith(playbackSpeed: clamped));
    } catch (e) {
      _log('Speed error: $e');
    }
  }

  void setAutoPlay(bool enabled) {
    _updateState(
      _state.copyWith(
        playMode: enabled ? PlayMode.continuous : PlayMode.single,
      ),
    );
    _log('Auto-play: $enabled');
  }

  void setPlayMode(PlayMode mode) {
    _updateState(_state.copyWith(playMode: mode));
  }

  // ─── HELPERS ───────────────────────────────────

  bool isAyahPlaying(int surahNumber, int ayahNumber) {
    return _state.isPlaying &&
        _state.surahNumber == surahNumber &&
        _state.ayahNumber == ayahNumber;
  }

  bool isAyahActive(int surahNumber, int ayahNumber) {
    return _state.isActive &&
        _state.surahNumber == surahNumber &&
        _state.ayahNumber == ayahNumber;
  }

  // ─── CACHE MANAGEMENT ──────────────────────────

  Future<double> getCacheSizeMB() async {
    if (_cacheDir == null || !await _cacheDir!.exists()) return 0.0;

    try {
      int totalBytes = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _log('Cache cleared');
      }
    } catch (e) {
      _log('Clear cache error: $e');
    }
  }

  // ─── STATE MANAGEMENT ──────────────────────────

  void _updateState(QuranAudioState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  // ─── DISPOSE ───────────────────────────────────

  Future<void> dispose() async {
    try {
      _playRequestId++;
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      await _playerStateSub?.cancel();
      await _completionSub?.cancel();
      await _player.dispose();
      _log('Service disposed');
    } catch (e) {
      _log('Dispose error: $e');
    }
  }
}
