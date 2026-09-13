// lib/features/quran/providers/quran_audio_provider.dart
// ============================================================
// QIBRA AI — QURAN AUDIO PROVIDER (app-wide, SINGLE player)
// ============================================================
// Exactly one just_audio instance for the whole app — every surface
// (options sheet, reader cards, mini bar) reflects this same state.
// Phases: idle / loading / playing / paused / failed. Position and
// duration come ONLY from the player's real streams — while the
// player has not reported a duration, none is shown (no invented
// totals). Auto-advance walks the real ayah queue and stops at the end
// of the surah. The source ladder (local file → primary URL → fallback
// URL once → honest failure) is the pure Tilawat.advance logic
// unit-tested in isolation; the provider just executes it.
// Interruption handling (phone-call auto-pause) rides the AudioPlayer
// constructor default handleInterruptions: true — never an optional
// setter call (0.9.46 has no setHandleInterruptions; see build()).
// No manifest edits in this file (Pass Q1's single audio_service entry
// lives in AndroidManifest.xml next to the guarded boot in main.dart).
//
// Pass Q1 adds, all riding the SAME single player + real streams:
// multi-qari selection (persisted pref; mid-play switch = stop →
// restart queue at current ayah — no crossfade lies), hifz repeat
// (off / ayah×N capped at 20 / explicit range — the loop decisions are
// the pure Tilawat.repeatDecision machine) and just_audio setSpeed
// playback speed (persisted, whitelist). Background playback is a
// thin push/pull bridge to TilawatAudioHandler — every notification
// field below is pushed from REAL state, and the sync is a checked
// no-op whenever the service is absent.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/audio/quran_audio_service.dart';
import '../data/audio/tilawat.dart';
import '../data/audio/tilawat_downloader.dart';
import 'reading_preferences_provider.dart';

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
    this.session = 0,
    this.qariId = Tilawat.defaultQariId,
    this.qariName = '',
    this.speed = 1.0,
    this.repeatMode = QuranRepeatMode.off,
    this.repeatCount = 1,
    this.rangeStart = 0,
    this.rangeEnd = 0,
    this.rangePick = QuranRangePick.none,
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

  /// Increments on every NEW startQueue call (never on auto-advance or
  /// retry). Surfaces use it to detect "a fresh playback action happened"
  /// — e.g. the reader re-arms follow-along only on a new session.
  final int session;

  // Pass Q1 (2026-09-14): reciter, speed and hifz state ride on the
  // SAME immutable snapshot so every surface (mini player, reader chips,
  // notification) renders the exact values the controller enforces.

  /// Catalog id of the qari this session plays (see Tilawat.byId).
  final String qariId;

  /// Display name for the subtitle row — '' until known (never null, so
  /// the UI can't branch into an invented name).
  final String qariName;

  /// Playback speed actually applied (whitelist — see Tilawat.knownSpeeds).
  final double speed;

  /// Hifz repeat mode (off = plain queue).
  final QuranRepeatMode repeatMode;

  /// Ayah-repeat count, already clamped at set time (1..20).
  final int repeatCount;

  /// Range bounds (ayah numbers within the playing surah; 0 = unset).
  final int rangeStart;
  final int rangeEnd;

  /// Live tap-picker stage for range bounds (none = not picking).
  final QuranRangePick rangePick;

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
    int? session,
    int? surahNumber,
    String? surahName,
    int? ayahNumber,
    Duration? position,
    Duration? duration,
    bool? buffering,
    String? error,
    int? queueIndex,
    int? queueLength,
    String? qariId,
    String? qariName,
    double? speed,
    QuranRepeatMode? repeatMode,
    int? repeatCount,
    int? rangeStart,
    int? rangeEnd,
    QuranRangePick? rangePick,
    bool clearError = false,
    bool clearDuration = false,
  }) {
    return QuranAudioState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      position: position ?? this.position,
      duration: clearDuration ? null : (duration ?? this.duration),
      buffering: buffering ?? this.buffering,
      error: clearError ? null : (error ?? this.error),
      queueIndex: queueIndex ?? this.queueIndex,
      queueLength: queueLength ?? this.queueLength,
      qariId: qariId ?? this.qariId,
      qariName: qariName ?? this.qariName,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatCount: repeatCount ?? this.repeatCount,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      rangePick: rangePick ?? this.rangePick,
    );
  }
}

class QuranAudioController extends Notifier<QuranAudioState>
    implements TilawatPlaybackDelegate {
  late final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  List<PlayableAyah> _queue = const [];
  bool _resolving = false;

  /// Active reciter for THIS playback session (persisted separately in
  /// prefs — startQueue re-reads, so a new surah always uses the pref).
  TilawatQari _qari = Tilawat.current;

  /// Completions of the current ayah so far (ayah-repeat mode only);
  /// reset on every manual jump, queue advance and new session.
  int _repeatsDone = 0;

  /// Notification throttling: broadcast at most one position tick per
  /// player-reported second (audio_service coalesces further).
  int _lastNotifSec = -1;

  @override
  QuranAudioState build() {
    _player = AudioPlayer();
    // handleInterruptions is the CONSTRUCTOR DEFAULT (true) in just_audio —
    // there is deliberately no setHandleInterruptions() call: that method
    // does not exist in 0.9.46, the version this app resolves to (device
    // build report 2026-09-03; same trap class as gate G13).

    _player.setSpeed(1.0); // neutral; startQueue/_resolveAndPlay apply prefs

    _subs.add(_player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        // Real end of this track — consult the repeat machine, then
        // advance/loop/stop (no silent re-arm: any re-play here is the
        // user's explicit repeat state, never an automatic retry).
        if (!_resolving) unawaited(_onFinished());
        return;
      }
      if (_resolving) return;
      _applyPlayerState();
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (state.phase == QuranAudioPhase.idle) return;
      state = state.copyWith(position: p);
      final sec = p.inSeconds;
      if (sec != _lastNotifSec) {
        _lastNotifSec = sec;
        _syncService();
      }
    }));
    _subs.add(_player.durationStream.listen((d) {
      state = state.copyWith(duration: d, clearDuration: d == null);
      _syncService();
    }));

    // Background bridge: register as the handler's delegate (no-op when
    // audio_service is absent on this platform).
    final h = TilawatAudioHandler.instance;
    if (h != null) h.delegate = this;

    ref.onDispose(() async {
      final hh = TilawatAudioHandler.instance;
      if (hh != null && identical(hh.delegate, this)) hh.delegate = null;
      for (final s in _subs) {
        await s.cancel();
      }
      _subs.clear();
      await _player.dispose();
    });
    return const QuranAudioState();
  }

  // ─── public playback surface ────────────────────────────────

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
  /// the end of the surah (queue built from the real ayah list).
  Future<void> startQueue({
    required int surahNumber,
    required String surahName,
    required List<PlayableAyah> queue,
    required int startIndex,
  }) async {
    if (queue.isEmpty) return;
    final idx = startIndex.clamp(0, queue.length - 1).toInt();
    _queue = List.unmodifiable(queue);
    // Fresh action: re-read the persisted reciter + speed, reset the
    // hifz run-state (repeat counter + any half-picked range bounds;
    // the MODE/count persist for the session as the chips visibly
    // reflect — bounds belong to a surah and are cleared with it).
    final prefs = ref.read(readingPreferencesProvider);
    _qari = Tilawat.byId(prefs.qariId);
    _repeatsDone = 0;
    state = QuranAudioState(
      phase: QuranAudioPhase.loading,
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: _queue[idx].ayah,
      buffering: true,
      queueIndex: idx,
      queueLength: _queue.length,
      session: state.session + 1, // new playback action — surfaces re-arm
      qariId: _qari.id,
      qariName: _qari.displayName,
      speed: ReadingPreferences.validSpeed(prefs.playbackSpeed),
      repeatMode: state.repeatMode,
      repeatCount: state.repeatCount,
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
    _syncService(); // idle ⇒ notification goes away
  }

  // ─── Pass Q1: seek + queue edges ────────────────────────────

  /// Honest seek: only when the player REPORTS a real duration can the
  /// UI offer a slider, and only into [0, duration] do we seek. No
  /// scrubbing onto an unknown-length track, no extrapolated totals.
  Future<void> seek(Duration to) async {
    final dur = state.duration;
    if (dur == null || dur.inMilliseconds <= 0) return;
    final ms = to.inMilliseconds.clamp(0, dur.inMilliseconds).toInt();
    state = state.copyWith(position: Duration(milliseconds: ms));
    try {
      await _player.seek(Duration(milliseconds: ms));
    } catch (e) {
      debugPrint('⚠️ tilawat seek failed: $e');
    }
    _syncService();
  }

  /// Manual next: advance the queue; at the end the queue has run out —
  /// mirrors the auto-advance edge: honest stop (documented choice).
  Future<void> nextAyah() async {
    if (state.queueLength == 0) return;
    final next = Tilawat.nextQueueIndex(state.queueIndex, _queue.length);
    if (next == null) {
      await stop();
      return;
    }
    await _jumpTo(next);
  }

  /// Manual prev. FIRST-AYA EDGE SEMANTICS (mirrors the forward edge,
  /// as the pass brief demands): the forward queue "just runs out" into
  /// an honest stop, so prev on the first ayah stops too — no wrap
  /// around the surah, no fake 'stay playing from zero'.
  Future<void> prevAyah() async {
    if (state.queueLength == 0) return;
    final prev = Tilawat.previousQueueIndex(state.queueIndex, _queue.length);
    if (prev == null) {
      await stop();
      return;
    }
    await _jumpTo(prev);
  }

  Future<void> _jumpTo(int index) async {
    _repeatsDone = 0; // manual jump restarts the repeat tally
    state = state.copyWith(
      queueIndex: index,
      ayahNumber: _queue[index].ayah,
      position: Duration.zero,
      clearDuration: true,
      buffering: true,
    );
    await _resolveAndPlay(index);
  }

  // ─── Pass Q1: reciter switching ─────────────────────────────

  /// Persist a qari and, mid-playback, stop → restart the queue at the
  /// CURRENT ayah with the new reciter. Deliberately blunt: no crossfade,
  /// no pretending continuity that doesn't exist — the session bumps so
  /// follow-highlight re-arms honestly.
  Future<void> selectQari(String id) async {
    final q = Tilawat.byId(id);
    await ref.read(readingPreferencesProvider.notifier).setQariId(q.id);
    final sameIdle = !_hasActivePlayback || (q.id == _qari.id);
    _qari = q;
    state = state.copyWith(qariId: q.id, qariName: q.displayName);
    if (!_hasActivePlayback) {
      _syncService();
      return;
    }
    if (sameIdle) {
      _syncService();
      return;
    }
    _repeatsDone = 0;
    state = state.copyWith(
      phase: QuranAudioPhase.loading,
      position: Duration.zero,
      clearDuration: true,
      buffering: true,
      session: state.session + 1,
    );
    await _player.stop();
    if (state.queueLength > 0) {
      await _resolveAndPlay(state.queueIndex);
    } else {
      await stop();
    }
  }

  bool get _hasActivePlayback => state.active && state.queueLength > 0;

  // ─── Pass Q1: playback speed ────────────────────────────────

  /// Whitelist speed (0.75/1/1.25/1.5) → apply on the live player →
  /// persist. Applies to subsequent resolves as well (setSpeed rides on
  /// the player, surviving setSource — re-applied defensively per track).
  Future<void> setSpeed(double v) async {
    final s = ReadingPreferences.validSpeed(v);
    state = state.copyWith(speed: s);
    await ref.read(readingPreferencesProvider.notifier).setPlaybackSpeed(s);
    try {
      await _player.setSpeed(s);
    } catch (e) {
      debugPrint('⚠️ tilawat speed set failed: $e');
    }
    _syncService();
  }

  // ─── Pass Q1: hifz repeat ───────────────────────────────────

  /// Entering range mode immediately arms the tap-picker (UI shows
  /// 'tap the start ayah'); leaving range parks everything back to off.
  void setRepeatMode(QuranRepeatMode mode) {
    _repeatsDone = 0;
    state = state.copyWith(
      repeatMode: mode,
      rangePick: mode == QuranRepeatMode.range
          ? QuranRangePick.start
          : QuranRangePick.none,
    );
  }

  /// Ayah-repeat count; capped at Tilawat.maxAyahRepeats (20) — the UI
  /// shows '×20 (max)' instead of ∞ on purpose (no unbounded loop).
  void setRepeatCount(int n) {
    _repeatsDone = 0;
    state = state.copyWith(repeatCount: Tilawat.clampRepeatCount(n));
  }

  /// Range flow reuses the existing tap affordance on ayah cards:
  /// first tap sets the start ayah, second sets the end. Returns true
  /// when the tap WAS consumed (the reader then skips opening the
  /// options sheet). Returns false (tap passes through) unless the
  /// reader is showing the very surah that is playing.
  bool consumeRangePick(int surah, int ayah) {
    if (state.rangePick == QuranRangePick.none) return false;
    if (surah != state.surahNumber) return false; // bounds are per-surah
    switch (state.rangePick) {
      case QuranRangePick.start:
        state = state.copyWith(rangeStart: ayah, rangePick: QuranRangePick.end);
        return true;
      case QuranRangePick.end:
        state = state.copyWith(rangeEnd: ayah, rangePick: QuranRangePick.none);
        return true;
      case QuranRangePick.none:
        return false;
    }
  }

  /// Back out of a half-picked range honestly.
  void cancelRangePick() {
    state = state.copyWith(
      repeatMode: QuranRepeatMode.off,
      rangePick: QuranRangePick.none,
    );
  }

  // ─── state mapping + background bridge ──────────────────────

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
        _syncService();
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
    _syncService();
  }

  /// Push REAL controller state into the media notification (title =
  /// surah·ayah, artist = qari, playing/position/speed from the same
  /// fields the mini player renders). Checked no-op when the service is
  /// absent; nothing here invents a duration or a position.
  void _syncService() {
    final h = TilawatAudioHandler.instance;
    if (h == null) return;
    try {
      if (!state.active) {
        h.mediaItem.add(null);
        h.playbackState.add(PlaybackState(
          processingState: AudioProcessingState.idle,
          controls: const [],
        ));
        return;
      }
      final dur = state.duration;
      h.mediaItem.add(MediaItem(
        id: 'tilawat/${state.qariId}/${state.surahNumber}:${state.ayahNumber ?? 0}',
        title: '${state.surahName ?? 'Surah ${state.surahNumber}'}'
            '${state.ayahNumber == null ? '' : ' · ${state.ayahNumber}'}',
        artist: state.qariName.isEmpty ? null : state.qariName,
        album: 'Tilawat',
        duration: dur,
      ));
      h.playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        // NO MediaAction.seek: the notification stays play/pause +
        // prev/next only (minimal by design this pass).
        systemActions: const {
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.playPause,
          MediaAction.stop,
        },
        processingState: state.phase == QuranAudioPhase.loading
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
        playing: state.isPlaying,
        position: state.position,
        bufferedPosition: state.position,
        updatePosition: DateTime.now(),
        currentSpeed: state.speed,
        duration: dur,
      ));
    } catch (e) {
      debugPrint('⚠️ tilawat notification sync failed: $e');
    }
  }

  // TilawatPlaybackDelegate — system controls mirror the in-app buttons.
  @override
  Future<void> servicePlay() async {
    if (state.phase == QuranAudioPhase.failed) {
      await retry();
      return;
    }
    if (!state.active) return;
    unawaited(_player.play());
  }

  @override
  Future<void> servicePause() async {
    if (state.isPlaying) await _player.pause();
  }

  @override
  Future<void> serviceStop() => stop();

  @override
  Future<void> serviceSeek(Duration position) => seek(position);

  @override
  Future<void> serviceNext() => nextAyah();

  @override
  Future<void> servicePrevious() => prevAyah();

  Future<void> _onFinished() async {
    if (state.queueLength == 0) return;
    final hasNext =
        Tilawat.nextQueueIndex(state.queueIndex, _queue.length) != null;
    final act = Tilawat.repeatDecision(
      mode: state.repeatMode,
      timesDone: _repeatsDone,
      timesTarget: state.repeatCount,
      currentAyah: _queue[state.queueIndex].ayah,
      rangeStart: state.rangeStart,
      rangeEnd: state.rangeEnd,
      hasNext: hasNext,
    );
    switch (act.action) {
      case TilawatRepeatAction.replay:
        // Explicit user repeat state — re-arming here is NOT a silent
        // loop: the user asked for this ayah ×N, and the hifz bar shows
        // exactly that.
        _repeatsDone++;
        state = state.copyWith(
          position: Duration.zero,
          clearDuration: true,
          buffering: true,
        );
        await _resolveAndPlay(state.queueIndex);
        return;
      case TilawatRepeatAction.jump:
        final target = act.targetAyah;
        final idx = _queue
            .indexWhere((e) => e.surah == state.surahNumber && e.ayah == target);
        if (idx < 0) {
          // The tapped range isn't inside this queue (e.g. single-ayah
          // playback) — honest stop rather than inventing items.
          await stop();
          return;
        }
        _repeatsDone = 0;
        await _jumpTo(idx);
        return;
      case TilawatRepeatAction.advance:
        final next =
            Tilawat.nextQueueIndex(state.queueIndex, _queue.length)!;
        _repeatsDone = 0;
        state = state.copyWith(
          queueIndex: next,
          ayahNumber: _queue[next].ayah,
          position: Duration.zero,
          clearDuration: true,
        );
        await _resolveAndPlay(next);
        return;
      case TilawatRepeatAction.stop:
        // End of surah (or end of an exhausted repeat budget) — the
        // queue just runs out. Honest idle, no loop.
        await stop();
        return;
    }
  }

  /// Where the player looks for audio, in order — every URL/path is
  /// built with the ACTIVE qari (local files are per-qari directories).
  Future<void> _resolveAndPlay(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final a = _queue[index];
    _resolving = true;
    try {
      var loaded = false;
      try {
        final root = await const TilawatDownloader().rootDir();
        final size = TilawatDownloader.usableSize(
            Tilawat.filePath(root, a.surah, a.ayah, qari: _qari));
        if (size != null) {
          await _player
              .setFilePath(Tilawat.filePath(root, a.surah, a.ayah, qari: _qari));
          loaded = true;
        }
      } catch (e) {
        debugPrint('⚠️ tilawat local load failed: $e');
      }
      if (!loaded) {
        loaded = await _trySetUrl(Tilawat.primaryUrl(a.surah, a.ayah, qari: _qari));
      }
      if (!loaded) {
        loaded = await _trySetUrl(Tilawat.fallbackUrl(a.global, qari: _qari));
      }
      if (!loaded) {
        state = state.copyWith(
          phase: QuranAudioPhase.failed,
          buffering: false,
          error: Tilawat.offlineFailureMessage,
        );
        _syncService();
        return;
      }
      // Speed rides the player; re-assert per resolve (survives source
      // swaps on every just_audio version this app may resolve to).
      try {
        await _player.setSpeed(state.speed);
      } catch (e) {
        debugPrint('⚠️ tilawat speed re-apply failed: $e');
      }
      state = state.copyWith(clearError: true, buffering: true);
      // play()'s Future completes when the track pauses/ends — never
      // await it here; states arrive through the player's streams. A
      // real playback error lands in the try/catch below (typed: a bare
      // void .catchError handler would itself TypeError on this
      // Future<Duration?> the moment an error actually arrived).
      unawaited(() async {
        try {
          await _player.play();
        } catch (e) {
          debugPrint('⚠️ tilawat playback error: $e');
          state = state.copyWith(
            phase: QuranAudioPhase.failed,
            buffering: false,
            error: Tilawat.offlineFailureMessage,
          );
          _syncService();
        }
      }());
    } catch (e) {
      debugPrint('⚠️ tilawat play failed: $e');
      state = state.copyWith(
        phase: QuranAudioPhase.failed,
        buffering: false,
        error: Tilawat.offlineFailureMessage,
      );
      _syncService();
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
