// lib/features/quran/providers/audio_provider.dart

// ============================================================
// QIBRA AI — AUDIO PROVIDER (v1.0)
// Phase: 8.4 — Quran Audio Player
// Description: Riverpod StateNotifier wrapping QuranAudioService.
//              Manages audio state, auto-next ayah, reciter
//              selection, and clean lifecycle.
//
// Key Providers:
//   audioProvider         — Main StateNotifier (QuranAudioState)
//   isAyahPlayingProvider — Check if specific ayah is playing
//   isAyahActiveProvider  — Check if specific ayah is active
//   currentReciterProvider — Currently selected reciter
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quran_models.dart';
import '../presentation/services/quran_audio_service.dart';
import 'quran_provider.dart';

// ============================================================
// SECTION 1 — AUDIO SERVICE PROVIDER (singleton)
// ============================================================

/// Single instance of QuranAudioService for entire app lifecycle
final quranAudioServiceProvider = Provider<QuranAudioService>((ref) {
  final service = QuranAudioService();

  // Dispose when provider is destroyed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// ============================================================
// SECTION 2 — AUDIO STATE NOTIFIER
// ============================================================

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  QuranAudioNotifier(this._service, this._ref)
      : super(const QuranAudioState()) {
    _init();
  }

  final QuranAudioService _service;
  final Ref _ref;

  // Current surah ayahs list (for auto-next)
  List<AyahModel> _currentSurahAyahs = [];
  int? _currentSurahNumber;

  // ── Init ─────────────────────────────────────────────────

  void _init() {
    // Wire service state changes → notifier state
    _service.onStateChanged = (audioState) {
      if (mounted) {
        state = audioState;
      }
    };

    // Wire auto-next callback
    _service.onAyahCompleted = (surahNumber, ayahNumber) {
      if (mounted) {
        _handleAyahCompleted(surahNumber, ayahNumber);
      }
    };
  }

  // ── Auto-next logic ───────────────────────────────────────

  Future<void> _handleAyahCompleted(
    int surahNumber,
    int ayahNumber,
  ) async {
    if (!state.isAutoPlayEnabled) return;

    // Load surah if not cached
    if (_currentSurahNumber != surahNumber || _currentSurahAyahs.isEmpty) {
      await _loadSurahAyahs(surahNumber);
    }

    if (_currentSurahAyahs.isEmpty) return;

    // Find current ayah index
    final currentIndex = _currentSurahAyahs.indexWhere(
      (a) => a.number == ayahNumber,
    );

    if (currentIndex == -1) return;

    // Check if there is a next ayah
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _currentSurahAyahs.length) {
      // Last ayah of surah — stop
      return;
    }

    final nextAyah = _currentSurahAyahs[nextIndex];

    // Play next ayah
    await _service.playAyah(
      surahNumber: surahNumber,
      ayahNumber: nextAyah.number,
      globalAyahNumber: nextAyah.numberInQuran,
      reciter: state.reciter,
    );
  }

  Future<void> _loadSurahAyahs(int surahNumber) async {
    try {
      final surah = await _ref.read(surahDetailProvider(surahNumber).future);
      if (surah != null && mounted) {
        _currentSurahAyahs = surah.ayahs;
        _currentSurahNumber = surahNumber;
      }
    } catch (_) {
      _currentSurahAyahs = [];
    }
  }

  // ── Public API ────────────────────────────────────────────

  /// Play a specific ayah
  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
    QuranReciter? reciter,
  }) async {
    // Cache surah ayahs for auto-next
    if (_currentSurahNumber != surahNumber) {
      _loadSurahAyahs(surahNumber); // fire and forget — caches async
    }

    await _service.playAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
      reciter: reciter ?? state.reciter,
    );
  }

  /// Play ayah directly from AyahModel
  Future<void> playAyahModel({
    required int surahNumber,
    required AyahModel ayah,
    QuranReciter? reciter,
  }) async {
    await playAyah(
      surahNumber: surahNumber,
      ayahNumber: ayah.number,
      globalAyahNumber: ayah.numberInQuran,
      reciter: reciter,
    );
  }

  /// Play entire surah from first ayah
  Future<void> playSurahFromStart(int surahNumber) async {
    await _loadSurahAyahs(surahNumber);
    if (_currentSurahAyahs.isEmpty) return;

    final firstAyah = _currentSurahAyahs.first;
    await playAyah(
      surahNumber: surahNumber,
      ayahNumber: firstAyah.number,
      globalAyahNumber: firstAyah.numberInQuran,
    );
  }

  /// Pause
  Future<void> pause() async {
    await _service.pause();
  }

  /// Resume
  Future<void> resume() async {
    await _service.resume();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
  }

  /// Stop completely
  Future<void> stop() async {
    await _service.stop();
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    await _service.seekTo(position);
  }

  /// Seek by fraction 0.0–1.0
  Future<void> seekToFraction(double fraction) async {
    await _service.seekToFraction(fraction);
  }

  /// Play previous ayah
  Future<void> playPrevious() async {
    final surah = state.surahNumber;
    final ayah = state.ayahNumber;
    if (surah == null || ayah == null) return;

    if (_currentSurahNumber != surah || _currentSurahAyahs.isEmpty) {
      await _loadSurahAyahs(surah);
    }

    final currentIndex = _currentSurahAyahs.indexWhere(
      (a) => a.number == ayah,
    );

    if (currentIndex <= 0) return;

    final prevAyah = _currentSurahAyahs[currentIndex - 1];
    await playAyah(
      surahNumber: surah,
      ayahNumber: prevAyah.number,
      globalAyahNumber: prevAyah.numberInQuran,
    );
  }

  /// Play next ayah manually
  Future<void> playNext() async {
    final surah = state.surahNumber;
    final ayah = state.ayahNumber;
    if (surah == null || ayah == null) return;

    if (_currentSurahNumber != surah || _currentSurahAyahs.isEmpty) {
      await _loadSurahAyahs(surah);
    }

    final currentIndex = _currentSurahAyahs.indexWhere(
      (a) => a.number == ayah,
    );

    if (currentIndex == -1 || currentIndex >= _currentSurahAyahs.length - 1) {
      return;
    }

    final nextAyah = _currentSurahAyahs[currentIndex + 1];
    await playAyah(
      surahNumber: surah,
      ayahNumber: nextAyah.number,
      globalAyahNumber: nextAyah.numberInQuran,
    );
  }

  /// Change reciter
  Future<void> setReciter(QuranReciter reciter) async {
    await _service.setReciter(reciter);
  }

  /// Toggle auto-play
  void toggleAutoPlay() {
    _service.setAutoPlay(!state.isAutoPlayEnabled);
  }

  /// Set repeat mode
  void setRepeatMode(PlayMode mode) {
    _service.setPlayMode(mode);
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await _service.setPlaybackSpeed(speed);
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
  }

  // ── Helpers ───────────────────────────────────────────────

  /// Check if specific ayah is playing
  bool isAyahPlaying(int surahNumber, int ayahNumber) {
    return _service.isAyahPlaying(surahNumber, ayahNumber);
  }

  /// Check if specific ayah is active (playing or paused)
  bool isAyahActive(int surahNumber, int ayahNumber) {
    return _service.isAyahActive(surahNumber, ayahNumber);
  }

  /// Has previous ayah
  bool get hasPrevious {
    final ayah = state.ayahNumber;
    if (ayah == null || _currentSurahAyahs.isEmpty) return false;
    final index = _currentSurahAyahs.indexWhere((a) => a.number == ayah);
    return index > 0;
  }

  /// Has next ayah
  bool get hasNext {
    final ayah = state.ayahNumber;
    if (ayah == null || _currentSurahAyahs.isEmpty) return false;
    final index = _currentSurahAyahs.indexWhere((a) => a.number == ayah);
    return index >= 0 && index < _currentSurahAyahs.length - 1;
  }
}

// ============================================================
// SECTION 3 — MAIN AUDIO PROVIDER
// ============================================================

/// Main audio provider — use this everywhere
final audioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>((ref) {
  final service = ref.watch(quranAudioServiceProvider);
  return QuranAudioNotifier(service, ref);
});

// ============================================================
// SECTION 4 — HELPER PROVIDERS (for targeted UI rebuilds)
// ============================================================

/// Check if a specific ayah is currently playing
/// Usage: ref.watch(isAyahPlayingProvider((surah: 1, ayah: 5)))
final isAyahPlayingProvider =
    Provider.family<bool, ({int surah, int ayah})>((ref, params) {
  final audioState = ref.watch(audioProvider);
  return audioState.isPlaying &&
      audioState.surahNumber == params.surah &&
      audioState.ayahNumber == params.ayah;
});

/// Check if a specific ayah is active (playing OR paused)
final isAyahActiveProvider =
    Provider.family<bool, ({int surah, int ayah})>((ref, params) {
  final audioState = ref.watch(audioProvider);
  return audioState.isActive &&
      audioState.surahNumber == params.surah &&
      audioState.ayahNumber == params.ayah;
});

/// Currently selected reciter
final currentReciterProvider = Provider<QuranReciter>((ref) {
  return ref.watch(audioProvider).reciter;
});

/// Current audio status only (for status-based UI)
final audioStatusProvider = Provider<QuranAudioStatus>((ref) {
  return ref.watch(audioProvider).status;
});

/// Current audio progress 0.0–1.0
final audioProgressProvider = Provider<double>((ref) {
  return ref.watch(audioProvider).progress;
});

/// Is audio currently loading/buffering
final isAudioLoadingProvider = Provider<bool>((ref) {
  return ref.watch(audioProvider).isLoading;
});

/// Is any audio playing right now
final isAnyAudioPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioProvider).isPlaying;
});

/// Auto-play enabled state
final isAutoPlayEnabledProvider = Provider<bool>((ref) {
  return ref.watch(audioProvider).isAutoPlayEnabled;
});

// ============================================================
// END OF FILE — audio_provider.dart
// ============================================================
