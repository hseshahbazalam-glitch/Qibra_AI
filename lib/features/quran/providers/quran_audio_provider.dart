// lib/features/quran/providers/quran_audio_provider.dart
// ============================================================
// QIBRA AI — QURAN AUDIO PROVIDER (app-wide, SINGLE player)
// ============================================================
// Exactly one just_audio instance for the whole app — every surface
// (options sheet, reader cards, mini bar) reflects this same state.
// Phases: idle / loading / playing / paused / failed. Position and
// duration come ONLY from the player's real streams — while the
// player has not reported a duration, none is shown (no invented
// totals). Auto-advance walks the real ayah queue and stops at the
// end of the surah. Source ladder (local file → primary URL →
// fallback URL once → honest failure) is the pure Tilawat.advance
// logic unit-tested in isolation; the provider just executes it.
// Focus: setHandleInterruptions(true) — just_audio's default session
// handling pauses for phone calls; no manifest edits.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/audio/tilawat.dart';
import '../data/audio/tilawat_downloader.dart';

enum QuranAudioPhase { idle, loading, playing, paused, failed }

/// One queueable ayah. [global] is the app's own global ayah number
/// (numberInQuran from bundled data, QuranMeta prefix-sum as fallback).
@immutable
class PlayableAyah {
  const PlayableAyah({
    required this.surah,
    required this.ayah,
    required this.global,
  });

  final int surah;
  final int ayah;
  final int global;
}

@immutable
class QuranAudioState {
  const QuranAudioState({
    this.phase = QuranAudioPhase.idle,
    this.surahNumber,
    this.surahName,
    this.ayahNumber,
    this.position = Duration.zero,
    this.duration,
    this.buffering = false,
    this.error,
    this.queueIndex = 0,
    this.queueLength = 0,
  });

  final QuranAudioPhase phase;
  final int? surahNumber;
  final String? surahName;
  final int? ayahNumber;
  final Duration position;

  /// null until the player really knows it — the UI must not invent one.
  final Duration? duration;
  final bool buffering;
  final String? error;
  final int queueIndex;
  final int queueLength;

  bool get active => phase != QuranAudioPhase.idle;
  bool get isPlaying => phase == QuranAudioPhase.playing;
  double? get progress {
    final d = duration;
    if (d == null || d.inMilliseconds <= 0) return null;
    return (position.inMilliseconds / d.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  bool isCurrent(int surah, int ayah) =>
      active && surahNumber == surah && ayahNumber == ayah;

  QuranAudioState copyWith({
    QuranAudioPhase? phase,
    int? surahNumber,
    String? surahName,
    int? ayahNumber,
    Duration? position,
    Duration? duration,
    bool? buffering,
    String? error,
    int? queueIndex,
    int? queueLength,
    bool clearError = false,
    bool clearDuration = false,
  }) {
    return QuranAudioState(
      phase: phase ?? this.phase,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      position: position ?? this.position,
      duration: clearDuration ? null : (duration ?? this.duration),
      buffering: buffering ?? this.buffering,
      error: clearError ? null : (error ?? this.error),
      queueIndex: queueIndex ?? this.queueIndex,
      queueLength: queueLength ?? this.queueLength,
    );
  }
}

class QuranAudioController extends Notifier<QuranAudioState> {
  late final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  List<PlayableAyah> _queue = const [];
  bool _resolving = false;

  @override
  QuranAudioState build() {
    _player = AudioPlayer();
    unawaited(_player.setHandleInterruptions(true));

    _subs.add(_player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        // Real end of this track — advance the queue (or stop).
        if (!_resolving) unawaited(_onFinished());
        return;
      }
      if (_resolving) return;
      _applyPlayerState();
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (state.phase == QuranAudioPhase.idle) return;
      state = state.copyWith(position: p);
    }));
    _subs.add(_player.durationStream.listen((d) {
      state = state.copyWith(duration: d, clearDuration: d == null);
    }));

    ref.onDispose(() async {
      for (final s in _subs) {
        await s.cancel();
      }
      _subs.clear();
      await _player.dispose();
    });
    return const QuranAudioState();
  }

  /// Play a single ayah (ayah options sheet).
  Future<void> playAyah({
    required int surahNumber,
    required String surahName,
    required PlayableAyah ayah,
  }) {
    return startQueue(
      surahNumber: surahNumber,
      surahName: surahName,
      queue: [ayah],
      startIndex: 0,
    );
  }

  /// Replace the queue and play from [startIndex], auto-advancing to
  /// the end of the surah (queue is built from the real ayah list).
  Future<void> startQueue({
    required int surahNumber,
    required String surahName,
    required List<PlayableAyah> queue,
    required int startIndex,
  }) async {
    if (queue.isEmpty) return;
    final idx = startIndex.clamp(0, queue.length - 1).toInt();
    _queue = List.unmodifiable(queue);
    state = QuranAudioState(
      phase: QuranAudioPhase.loading,
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: _queue[idx].ayah,
      buffering: true,
      queueIndex: idx,
      queueLength: _queue.length,
    );
    await _resolveAndPlay(idx);
  }

  /// Toggle play/pause when [surah]:[ayah] is the current track;
  /// otherwise start it. Never a no-op: every press does something real.
  Future<void> toggleAyah({
    required int surahNumber,
    required String surahName,
    required PlayableAyah ayah,
    required List<PlayableAyah> surahQueue,
    required int startIndex,
  }) async {
    if (state.isCurrent(surahNumber, ayah.ayah) &&
        (state.phase == QuranAudioPhase.playing ||
            state.phase == QuranAudioPhase.paused ||
            state.phase == QuranAudioPhase.loading ||
            state.phase == QuranAudioPhase.failed)) {
      await toggle();
      return;
    }
    await startQueue(
      surahNumber: surahNumber,
      surahName: surahName,
      queue: surahQueue,
      startIndex: startIndex,
    );
  }

  Future<void> toggle() async {
    if (state.phase == QuranAudioPhase.failed) {
      await retry();
      return;
    }
    if (!state.active) return;
    if (state.isPlaying) {
      await _player.pause();
      state = state.copyWith(phase: QuranAudioPhase.paused);
    } else {
      unawaited(_player.play());
    }
  }

  /// Explicit user retry of the current queue item (the only retry —
  /// there is no automatic loop).
  Future<void> retry() async {
    if (state.queueLength == 0) return;
    state = state.copyWith(
        phase: QuranAudioPhase.loading,
        buffering: true,
        clearError: true);
    await _resolveAndPlay(state.queueIndex);
  }

  Future<void> stop() async {
    // Reset state BEFORE stopping: the player emits an idle event from
    // stop() itself — with state already idle, the stream handler skips
    // it instead of misreporting a failure.
    _queue = const [];
    state = const QuranAudioState();
    await _player.stop();
  }

  /// Map the player's CURRENT real state into the UI state. Called from
  /// the stream listener AND right after resolution finishes (events
  /// that arrived while `_resolving` were skipped, and
  /// playerStateStream only fires on change — without this, the phase
  /// could stay 'loading' after the track actually started).
  void _applyPlayerState() {
    final ps = _player.playerState;
    final st = ps.processingState;
    if (st == ProcessingState.idle) {
      // Idle while a track was expected: surface an honest failed
      // state (no silent re-arm loops).
      if (state.phase != QuranAudioPhase.idle &&
          state.phase != QuranAudioPhase.failed) {
        state = state.copyWith(
          phase: QuranAudioPhase.failed,
          buffering: false,
          error: Tilawat.offlineFailureMessage,
        );
      }
      return;
    }
    if (st == ProcessingState.loading || st == ProcessingState.buffering) {
      state = state.copyWith(
          phase: QuranAudioPhase.loading, buffering: true);
      return;
    }
    if (st == ProcessingState.completed) return; // queue handles this
    state = state.copyWith(
      phase: ps.playing ? QuranAudioPhase.playing : QuranAudioPhase.paused,
      buffering: false,
    );
  }

  Future<void> _onFinished() async {
    final next = Tilawat.nextQueueIndex(state.queueIndex, _queue.length);
    if (next == null) {
      // End of surah — the queue just runs out. Honest idle, no loop.
      await stop();
      return;
    }
    state = state.copyWith(
      queueIndex: next,
      ayahNumber: _queue[next].ayah,
      position: Duration.zero,
      clearDuration: true,
    );
    await _resolveAndPlay(next);
  }

  /// local (if a usable downloaded file exists) → primary URL →
  /// fallback URL once → failed. Exactly the documented ladder.
  Future<void> _resolveAndPlay(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final a = _queue[index];
    _resolving = true;
    try {
      var loaded = false;
      try {
        final root = await const TilawatDownloader().rootDir();
        final size = await TilawatDownloader.usableSize(
            Tilawat.filePath(root, a.surah, a.ayah));
        if (size != null) {
          await _player
              .setFilePath(Tilawat.filePath(root, a.surah, a.ayah));
          loaded = true;
        }
      } catch (e) {
        debugPrint('⚠️ tilawat local load failed: $e');
      }
      if (!loaded) {
        loaded = await _trySetUrl(Tilawat.primaryUrl(a.surah, a.ayah));
      }
      if (!loaded) {
        loaded = await _trySetUrl(Tilawat.fallbackUrl(a.global));
      }
      if (!loaded) {
        state = state.copyWith(
          phase: QuranAudioPhase.failed,
          buffering: false,
          error: Tilawat.offlineFailureMessage,
        );
        return;
      }
      state = state.copyWith(clearError: true, buffering: true);
      // play()'s Future completes when the track pauses/ends — never
      // await it here; states arrive through the player's streams.
      unawaited(_player.play().catchError((Object e) {
        debugPrint('⚠️ tilawat playback error: $e');
        state = state.copyWith(
          phase: QuranAudioPhase.failed,
          buffering: false,
          error: Tilawat.offlineFailureMessage,
        );
      }));
    } catch (e) {
      debugPrint('⚠️ tilawat play failed: $e');
      state = state.copyWith(
        phase: QuranAudioPhase.failed,
        buffering: false,
        error: Tilawat.offlineFailureMessage,
      );
    } finally {
      _resolving = false;
      // Re-apply the player's actual state so nothing is left pinned
      // to 'loading' by events skipped during resolution.
      _applyPlayerState();
    }
  }

  Future<bool> _trySetUrl(String? url) async {
    if (url == null) return false;
    try {
      await _player.setUrl(url);
      return true;
    } catch (e) {
      debugPrint('⚠️ tilawat source failed: $e');
      return false;
    }
  }
}

final quranAudioProvider =
    NotifierProvider<QuranAudioController, QuranAudioState>(
  QuranAudioController.new,
);
