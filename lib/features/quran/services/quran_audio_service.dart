// lib/features/quran/services/quran_audio_service.dart

// ============================================================
// QIBRA AI — QURAN AUDIO SERVICE (v5.0 — Download First)
// ============================================================
// Strategy: Download → Cache → Play from local file
// No streaming = No AudioTrack conflicts on Oppo/Android 16
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================
// RECITER
// ============================================================

class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.style,
    required this.everyAyahFolder,
  });

  final String id;
  final String name;
  final String nameArabic;
  final String style;
  final String everyAyahFolder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QuranReciter && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

abstract final class QuranReciters {
  static const QuranReciter alafasy = QuranReciter(
    id: 'ar.alafasy',
    name: 'Mishary Rashid Alafasy',
    nameArabic: 'مشاري راشد العفاسي',
    style: 'Murattal',
    everyAyahFolder: 'Alafasy_128kbps',
  );

  static const QuranReciter basfar = QuranReciter(
    id: 'ar.abdullahbasfar',
    name: 'Abdullah Basfar',
    nameArabic: 'عبدالله بصفر',
    style: 'Murattal',
    everyAyahFolder: 'Abdullah_Basfar_64kbps',
  );

  static const QuranReciter sudais = QuranReciter(
    id: 'ar.abdurrahmaansudais',
    name: 'Abdul Rahman Al-Sudais',
    nameArabic: 'عبدالرحمن السديس',
    style: 'Murattal',
    everyAyahFolder: 'Abdurrahmaan_As-Sudais_64kbps',
  );

  static const QuranReciter husary = QuranReciter(
    id: 'ar.husary',
    name: 'Mahmoud Khalil Al-Husary',
    nameArabic: 'محمود خليل الحصري',
    style: 'Murattal',
    everyAyahFolder: 'Husary_128kbps',
  );

  static const List<QuranReciter> all = [alafasy, basfar, sudais, husary];
  static const QuranReciter defaultReciter = alafasy;
}

// ============================================================
// ENUMS
// ============================================================

enum PlaybackSpeed {
  slow(0.5, '0.5x', 'Very Slow'),
  slower(0.75, '0.75x', 'Slow'),
  normal(1.0, '1x', 'Normal'),
  faster(1.25, '1.25x', 'Fast'),
  fast(1.5, '1.5x', 'Faster'),
  fastest(2.0, '2x', 'Fastest');

  const PlaybackSpeed(this.value, this.label, this.description);
  final double value;
  final String label;
  final String description;

  static PlaybackSpeed fromValue(double value) {
    return PlaybackSpeed.values.firstWhere(
      (s) => s.value == value,
      orElse: () => PlaybackSpeed.normal,
    );
  }
}

enum RepeatMode {
  none(0, 'Off', 'No repeat'),
  twice(2, '2x', 'Repeat 2 times'),
  thrice(3, '3x', 'Repeat 3 times'),
  fiveTimes(5, '5x', 'Repeat 5 times'),
  tenTimes(10, '10x', 'Repeat 10 times'),
  infinite(-1, '∞', 'Repeat forever');

  const RepeatMode(this.count, this.label, this.description);
  final int count;
  final String label;
  final String description;

  bool get isEnabled => count != 0;
  bool get isInfinite => count == -1;
}

enum PlayMode {
  single('Single Ayah', 'Play one ayah and stop'),
  continuous('Continuous', 'Play next ayah automatically'),
  rangeLoop('Range Loop', 'Loop between start and end ayah'),
  fullSurah('Full Surah', 'Play entire surah'),
  fullQuran('Full Quran', 'Play entire Quran non-stop');

  const PlayMode(this.label, this.description);
  final String label;
  final String description;
}

enum SleepTimerDuration {
  off(0, 'Off'),
  fiveMin(5, '5 min'),
  tenMin(10, '10 min'),
  fifteenMin(15, '15 min'),
  thirtyMin(30, '30 min'),
  fortyFiveMin(45, '45 min'),
  oneHour(60, '1 hour'),
  twoHours(120, '2 hours'),
  endOfSurah(-1, 'End of Surah');

  const SleepTimerDuration(this.minutes, this.label);
  final int minutes;
  final String label;

  Duration get duration => Duration(minutes: minutes);
  bool get isActive => minutes > 0;
  bool get isEndOfSurah => minutes == -1;
}

enum QuranAudioStatus {
  idle,
  downloading,
  loading,
  buffering,
  playing,
  paused,
  stopped,
  completed,
  error,
}

// ============================================================
// STATE
// ============================================================

class QuranAudioState {
  const QuranAudioState({
    this.status = QuranAudioStatus.idle,
    this.surahNumber,
    this.ayahNumber,
    this.globalAyahNumber,
    this.reciter = QuranReciters.defaultReciter,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.downloadProgress = 0.0,
    this.playbackSpeed = PlaybackSpeed.normal,
    this.repeatMode = RepeatMode.none,
    this.currentRepeatCount = 0,
    this.playMode = PlayMode.continuous,
    this.sleepTimer = SleepTimerDuration.off,
    this.sleepTimerRemaining = Duration.zero,
    this.rangeStartAyah,
    this.rangeEndAyah,
    this.volume = 1.0,
    this.bitrate = 64,
  });

  final QuranAudioStatus status;
  final int? surahNumber;
  final int? ayahNumber;
  final int? globalAyahNumber;
  final QuranReciter reciter;
  final Duration position;
  final Duration duration;
  final String? error;
  final double downloadProgress;
  final PlaybackSpeed playbackSpeed;
  final RepeatMode repeatMode;
  final int currentRepeatCount;
  final PlayMode playMode;
  final SleepTimerDuration sleepTimer;
  final Duration sleepTimerRemaining;
  final int? rangeStartAyah;
  final int? rangeEndAyah;
  final double volume;
  final int bitrate;

  bool get isPlaying => status == QuranAudioStatus.playing;
  bool get isPaused => status == QuranAudioStatus.paused;
  bool get isDownloading => status == QuranAudioStatus.downloading;
  bool get isLoading =>
      status == QuranAudioStatus.loading ||
      status == QuranAudioStatus.buffering ||
      status == QuranAudioStatus.downloading;
  bool get isIdle => status == QuranAudioStatus.idle;
  bool get hasError => status == QuranAudioStatus.error;
  bool get isCompleted => status == QuranAudioStatus.completed;
  bool get isActive => surahNumber != null && ayahNumber != null;
  bool get isAutoPlayEnabled => playMode != PlayMode.single;
  bool get hasRepeat => repeatMode.isEnabled;
  bool get hasSleepTimer => sleepTimer.isActive;
  bool get hasRangeLoop =>
      playMode == PlayMode.rangeLoop &&
      rangeStartAyah != null &&
      rangeEndAyah != null;

  double get progress {
    if (duration == Duration.zero) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionFormatted => _formatDuration(position);
  String get durationFormatted => _formatDuration(duration);
  String get sleepTimerFormatted => _formatDuration(sleepTimerRemaining);

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    int? surahNumber,
    int? ayahNumber,
    int? globalAyahNumber,
    QuranReciter? reciter,
    Duration? position,
    Duration? duration,
    String? error,
    double? downloadProgress,
    PlaybackSpeed? playbackSpeed,
    RepeatMode? repeatMode,
    int? currentRepeatCount,
    PlayMode? playMode,
    SleepTimerDuration? sleepTimer,
    Duration? sleepTimerRemaining,
    int? rangeStartAyah,
    int? rangeEndAyah,
    double? volume,
    int? bitrate,
    bool clearError = false,
    bool clearAyah = false,
    bool clearRange = false,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      surahNumber: clearAyah ? null : (surahNumber ?? this.surahNumber),
      ayahNumber: clearAyah ? null : (ayahNumber ?? this.ayahNumber),
      globalAyahNumber:
          clearAyah ? null : (globalAyahNumber ?? this.globalAyahNumber),
      reciter: reciter ?? this.reciter,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      downloadProgress: downloadProgress ?? this.downloadProgress,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      repeatMode: repeatMode ?? this.repeatMode,
      currentRepeatCount: currentRepeatCount ?? this.currentRepeatCount,
      playMode: playMode ?? this.playMode,
      sleepTimer: sleepTimer ?? this.sleepTimer,
      sleepTimerRemaining: sleepTimerRemaining ?? this.sleepTimerRemaining,
      rangeStartAyah:
          clearRange ? null : (rangeStartAyah ?? this.rangeStartAyah),
      rangeEndAyah: clearRange ? null : (rangeEndAyah ?? this.rangeEndAyah),
      volume: volume ?? this.volume,
      bitrate: bitrate ?? this.bitrate,
    );
  }
}

// ============================================================
// SERVICE
// ============================================================

class QuranAudioService {
  QuranAudioService() {
    _initAudioSession();
    _createPlayer();
    _initCacheDir();
  }

  AudioPlayer? _player;
  AudioSession? _audioSession;
  final Dio _dio = Dio();
  Directory? _cacheDir;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Timer? _sleepTimerTicker;
  CancelToken? _downloadCancelToken;

  int _playRequestId = 0;

  void Function(int surahNumber, int ayahNumber)? onAyahCompleted;
  void Function(QuranAudioState state)? onStateChanged;
  void Function(int surahNumber, int ayahNumber)? onRepeatTriggered;
  void Function()? onSleepTimerExpired;

  QuranAudioState _state = const QuranAudioState();
  QuranAudioState get currentState => _state;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[QIBRA_AUDIO] $message');
    }
  }

  // ── Cache Directory ──────────────────────────────────────

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

  Future<String> _getLocalFilePath({
    required int globalAyahNumber,
    required QuranReciter reciter,
    required int bitrate,
  }) async {
    if (_cacheDir == null) await _initCacheDir();
    final fileName = '${reciter.id}_${bitrate}_$globalAyahNumber.mp3';
    return '${_cacheDir!.path}/$fileName';
  }

  Future<bool> _isFileDownloaded(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 1000; // At least 1KB
  }

  // ── Audio Session ────────────────────────────────────────

  Future<void> _initAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );
      await _audioSession!.setActive(true);
    } catch (e) {
      _log('AudioSession error: $e');
    }
  }

  // ── Player ────────────────────────────────────────────────

  void _createPlayer() {
    _player = AudioPlayer(
      userAgent: 'QIBRA-AI/1.0',
      handleInterruptions: true,
      androidApplyAudioAttributes: true,
      handleAudioSessionActivation: true,
    );
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    final player = _player;
    if (player == null) return;

    _positionSub = player.positionStream.listen((position) {
      _updateState(_state.copyWith(position: position));
    });

    _durationSub = player.durationStream.listen((duration) {
      if (duration != null) {
        _updateState(_state.copyWith(duration: duration));
      }
    });

    _playerStateSub = player.playerStateStream.listen((playerState) {
      final processingState = playerState.processingState;
      final playing = playerState.playing;

      // Don't override downloading state
      if (_state.status == QuranAudioStatus.downloading) return;

      QuranAudioStatus newStatus;
      switch (processingState) {
        case ProcessingState.idle:
          newStatus = QuranAudioStatus.idle;
          break;
        case ProcessingState.loading:
          newStatus = QuranAudioStatus.loading;
          break;
        case ProcessingState.buffering:
          newStatus = QuranAudioStatus.buffering;
          break;
        case ProcessingState.ready:
          newStatus =
              playing ? QuranAudioStatus.playing : QuranAudioStatus.paused;
          break;
        case ProcessingState.completed:
          newStatus = QuranAudioStatus.completed;
          _onPlaybackCompleted();
          break;
      }
      _updateState(_state.copyWith(status: newStatus));
    });
  }

  void _onPlaybackCompleted() {
    final surah = _state.surahNumber;
    final ayah = _state.ayahNumber;
    if (surah == null || ayah == null) return;

    if (_state.repeatMode.isEnabled) {
      final currentCount = _state.currentRepeatCount;
      final targetCount = _state.repeatMode.count;

      if (_state.repeatMode.isInfinite || currentCount < targetCount - 1) {
        _updateState(
          _state.copyWith(currentRepeatCount: currentCount + 1),
        );
        onRepeatTriggered?.call(surah, ayah);
        _replayCurrentAyah();
        return;
      } else {
        _updateState(_state.copyWith(currentRepeatCount: 0));
      }
    }

    switch (_state.playMode) {
      case PlayMode.single:
        break;
      case PlayMode.continuous:
      case PlayMode.fullSurah:
      case PlayMode.fullQuran:
        onAyahCompleted?.call(surah, ayah);
        break;
      case PlayMode.rangeLoop:
        if (_state.hasRangeLoop) {
          final end = _state.rangeEndAyah!;
          if (ayah >= end) {
            onAyahCompleted?.call(surah, _state.rangeStartAyah! - 1);
          } else {
            onAyahCompleted?.call(surah, ayah);
          }
        }
        break;
    }
  }

  Future<void> _replayCurrentAyah() async {
    try {
      await _player?.seek(Duration.zero);
      await _player?.play();
    } catch (_) {}
  }

  void _updateState(QuranAudioState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  // ── Download Logic ────────────────────────────────────────

  String _buildPrimaryUrl(
      int globalAyahNumber, QuranReciter reciter, int bitrate) {
    return 'https://cdn.islamic.network/quran/audio/$bitrate/${reciter.id}/$globalAyahNumber.mp3';
  }

  String _buildFallbackUrl(
      int surahNumber, int ayahNumber, QuranReciter reciter) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${reciter.everyAyahFolder}/$surah$ayah.mp3';
  }

  Future<bool> _downloadFile(String url, String savePath, int requestId) async {
    try {
      _downloadCancelToken?.cancel('New download started');
      _downloadCancelToken = CancelToken();

      _log('Downloading: $url');

      await _dio.download(
        url,
        savePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (requestId != _playRequestId) return;
          if (total > 0) {
            final progress = received / total;
            _updateState(_state.copyWith(downloadProgress: progress));
          }
        },
      );

      // Verify download
      if (requestId != _playRequestId) return false;
      if (!await _isFileDownloaded(savePath)) return false;

      _log('Downloaded: $savePath');
      return true;
    } catch (e) {
      _log('Download failed: $e');
      // Delete partial file
      try {
        final file = File(savePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return false;
    }
  }

  Future<bool> _playLocalFile(String filePath, int requestId) async {
    try {
      if (requestId != _playRequestId) return false;

      final player = _player;
      if (player == null) return false;

      _log('Playing local: $filePath');

      // v7.0 FIX: Full cleanup sequence for Oppo Android 16
      // Step 1: Stop current playback and wait
      try {
        await player.stop();
      } catch (_) {}

      // Step 2: Longer delay for native buffer cleanup (Oppo needs 300ms)
      await Future.delayed(const Duration(milliseconds: 300));

      if (requestId != _playRequestId) return false;

      // Step 3: Activate audio session BEFORE loading (prevents sound drop)
      try {
        await _audioSession?.setActive(true);
      } catch (_) {}

      // Step 4: Load file and WAIT for it to be ready
      await player.setFilePath(filePath);

      if (requestId != _playRequestId) return false;

      // Step 5: Small delay for player state to settle
      await Future.delayed(const Duration(milliseconds: 50));

      if (requestId != _playRequestId) return false;

      // Step 6: Apply settings before playing
      await player.setVolume(_state.volume);
      await player.setSpeed(_state.playbackSpeed.value);

      // Step 7: Now play — should be smooth
      await player.play();

      return true;
    } catch (e) {
      _log('Play error: $e');
      return false;
    }
  }
  // ============================================================
  // PUBLIC API
  // ============================================================

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
    QuranReciter? reciter,
  }) async {
    _playRequestId++;
    final requestId = _playRequestId;

    final selectedReciter = reciter ?? _state.reciter;
    final bitrate = _state.bitrate;

    _log('playAyah: $surahNumber:$ayahNumber (req $requestId)');

    _updateState(
      _state.copyWith(
        status: QuranAudioStatus.loading,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        globalAyahNumber: globalAyahNumber,
        reciter: selectedReciter,
        position: Duration.zero,
        duration: Duration.zero,
        currentRepeatCount: 0,
        downloadProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      // Get local file path
      final localPath = await _getLocalFilePath(
        globalAyahNumber: globalAyahNumber,
        reciter: selectedReciter,
        bitrate: bitrate,
      );

      if (requestId != _playRequestId) return;

      // Check if already cached
      if (await _isFileDownloaded(localPath)) {
        _log('Using cached file');
        if (await _playLocalFile(localPath, requestId)) return;
      }

      if (requestId != _playRequestId) return;

      // Not cached - download it
      _updateState(_state.copyWith(status: QuranAudioStatus.downloading));

      // Try primary URL
      final primaryUrl =
          _buildPrimaryUrl(globalAyahNumber, selectedReciter, bitrate);

      if (await _downloadFile(primaryUrl, localPath, requestId)) {
        if (requestId != _playRequestId) return;
        if (await _playLocalFile(localPath, requestId)) return;
      }

      if (requestId != _playRequestId) return;

      // Try fallback URL
      final fallbackUrl =
          _buildFallbackUrl(surahNumber, ayahNumber, selectedReciter);

      if (await _downloadFile(fallbackUrl, localPath, requestId)) {
        if (requestId != _playRequestId) return;
        if (await _playLocalFile(localPath, requestId)) return;
      }

      if (requestId != _playRequestId) return;

      _updateState(
        _state.copyWith(
          status: QuranAudioStatus.error,
          error: 'Download failed. Check internet.',
        ),
      );
    } catch (e) {
      _log('playAyah error: $e');
      if (requestId == _playRequestId) {
        _updateState(
          _state.copyWith(
            status: QuranAudioStatus.error,
            error: 'Playback failed: $e',
          ),
        );
      }
    }
  }

  Future<void> pause() async {
    try {
      final player = _player;
      if (player == null) return;
      // v7.0 FIX: Removed player.playing check (Oppo returns wrong value)
      // Always attempt pause; safe even if already paused
      await player.pause();
      _updateState(_state.copyWith(status: QuranAudioStatus.paused));
      _log('Paused');
    } catch (e) {
      _log('Pause error: $e');
    }
  }

  Future<void> resume() async {
    try {
      final player = _player;
      if (player == null) return;
      if (!player.playing) {
        await player.play();
        _updateState(_state.copyWith(status: QuranAudioStatus.playing));
        _log('Resumed');
      }
    } catch (e) {
      _log('Resume error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    try {
      final player = _player;
      if (player == null) return;

      // v7.0 FIX: Use internal state instead of player.playing (Oppo bug)
      final isCurrentlyPlaying = _state.status == QuranAudioStatus.playing;

      if (isCurrentlyPlaying) {
        await player.pause();
        _updateState(_state.copyWith(status: QuranAudioStatus.paused));
        _log('→ PAUSED');
      } else {
        await player.play();
        _updateState(_state.copyWith(status: QuranAudioStatus.playing));
        _log('→ PLAYING');
      }
    } catch (e) {
      _log('Toggle error: $e');
    }
  }

  Future<void> stop() async {
    try {
      _playRequestId++;
      _downloadCancelToken?.cancel('Stopped');
      cancelSleepTimer();
      await _player?.stop();
      _updateState(
        QuranAudioState(
          status: QuranAudioStatus.stopped,
          reciter: _state.reciter,
          playbackSpeed: _state.playbackSpeed,
          volume: _state.volume,
          bitrate: _state.bitrate,
        ),
      );
    } catch (_) {}
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player?.seek(position);
    } catch (_) {}
  }

  Future<void> seekToFraction(double fraction) async {
    if (_state.duration == Duration.zero) return;
    final target = Duration(
      milliseconds: (fraction * _state.duration.inMilliseconds).round(),
    );
    await seekTo(target);
  }

  Future<void> setPlaybackSpeed(PlaybackSpeed speed) async {
    try {
      await _player?.setSpeed(speed.value);
      _updateState(_state.copyWith(playbackSpeed: speed));
    } catch (_) {}
  }

  void setRepeatMode(RepeatMode mode) {
    _updateState(_state.copyWith(repeatMode: mode, currentRepeatCount: 0));
  }

  void setPlayMode(PlayMode mode) {
    _updateState(_state.copyWith(playMode: mode));
  }

  void setRangeLoop({required int startAyah, required int endAyah}) {
    _updateState(_state.copyWith(
      playMode: PlayMode.rangeLoop,
      rangeStartAyah: startAyah,
      rangeEndAyah: endAyah,
    ));
  }

  void clearRangeLoop() {
    _updateState(_state.copyWith(
      playMode: PlayMode.continuous,
      clearRange: true,
    ));
  }

  void setSleepTimer(SleepTimerDuration duration) {
    cancelSleepTimer();
    _updateState(_state.copyWith(
      sleepTimer: duration,
      sleepTimerRemaining: duration.duration,
    ));

    if (!duration.isActive || duration.isEndOfSurah) return;

    _sleepTimerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _state.sleepTimerRemaining - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        timer.cancel();
        _onSleepTimerExpired();
      } else {
        _updateState(_state.copyWith(sleepTimerRemaining: remaining));
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    _updateState(_state.copyWith(
      sleepTimer: SleepTimerDuration.off,
      sleepTimerRemaining: Duration.zero,
    ));
  }

  void _onSleepTimerExpired() {
    pause();
    onSleepTimerExpired?.call();
    _updateState(_state.copyWith(
      sleepTimer: SleepTimerDuration.off,
      sleepTimerRemaining: Duration.zero,
    ));
  }

  void setBitrate(int bitrate) {
    if (![32, 64, 128].contains(bitrate)) return;
    _updateState(_state.copyWith(bitrate: bitrate));
  }

  Future<void> setReciter(QuranReciter reciter) async {
    await stop();
    _updateState(_state.copyWith(reciter: reciter));
  }

  Future<void> setVolume(double volume) async {
    try {
      final clamped = volume.clamp(0.0, 1.0);
      await _player?.setVolume(clamped);
      _updateState(_state.copyWith(volume: clamped));
    } catch (_) {}
  }

  void setAutoPlay(bool enabled) {
    setPlayMode(enabled ? PlayMode.continuous : PlayMode.single);
  }

  bool isAyahActive(int surahNumber, int ayahNumber) {
    return _state.surahNumber == surahNumber && _state.ayahNumber == ayahNumber;
  }

  bool isAyahPlaying(int surahNumber, int ayahNumber) {
    return isAyahActive(surahNumber, ayahNumber) && _state.isPlaying;
  }

  /// Clear all cached audio files
  Future<int> clearCache() async {
    try {
      if (_cacheDir == null) return 0;
      int deletedCount = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }
      _log('Cleared $deletedCount files');
      return deletedCount;
    } catch (e) {
      _log('Cache clear error: $e');
      return 0;
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSize() async {
    try {
      if (_cacheDir == null) return 0;
      int totalBytes = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024); // MB
    } catch (_) {
      return 0;
    }
  }

  Future<void> dispose() async {
    onAyahCompleted = null;
    onStateChanged = null;
    onRepeatTriggered = null;
    onSleepTimerExpired = null;
    _downloadCancelToken?.cancel();
    cancelSleepTimer();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    try {
      await _audioSession?.setActive(false);
    } catch (_) {}
  }
}
