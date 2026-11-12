// lib/features/quran/data/audio/quran_audio_service.dart
// ============================================================
// QIBRA AI — TILAWAT BACKGROUND HANDLER (Pass Q1)
// ============================================================
// Thin audio_service bridge: keeps ONE AudioPlayer alive in the app-wide
// QuranAudioController and merely (a) forwards system commands (media
// notification / lock screen / headset buttons) to it through a tiny
// delegate contract, and (b) carries the controller's REAL state into
// the notification (play/pause, prev/next, stop; title = surah · ayah,
// artist = qari). No seek in the notification, no invented positions:
// every field is pushed by the controller from player truth, and the
// service stops foreground when paused (OS may reclaim it — the user
// resumes from the app, which is honest).
//
// boot() is called from main() and NEVER throws outward: on platforms
// where audio_service is unavailable (tests, desktop) instance stays
// null and every integration point is a checked no-op.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

/// The playback surface the handler may drive. Implemented by
/// QuranAudioController — method set exists, semantics identical to the
/// in-app buttons (never a second source of truth).
abstract class TilawatPlaybackDelegate {
  Future<void> servicePlay();
  Future<void> servicePause();
  Future<void> serviceStop();
  Future<void> serviceSeek(Duration position);
  Future<void> serviceNext();
  Future<void> servicePrevious();
}

class TilawatAudioHandler extends BaseAudioHandler {
  /// Null until boot() succeeds; the controller re-checks on every push.
  static TilawatAudioHandler? instance;

  /// Set/cleared by the controller in build()/dispose.
  TilawatPlaybackDelegate? delegate;

  static Future<void> boot() async {
    if (instance != null) return;
    try {
      instance = await AudioService.init(
        builder: () => TilawatAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.qibra_ai.tilawat',
          androidNotificationChannelName: 'Tilawat playback',
          // Tap → open the app at the reader (existing route): the
          // activity resumes where it was; the doc default is true —
          // spelled out to make the intent reviewable.
          androidNotificationClickStartsActivity: true,
          // Paused ⇒ lower-priority service; the OS may reclaim it.
          // Honest minimal resource use, per the pass's spirit.
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      // No platform support / init failure: audio keeps working
      // in-app, background notification is simply absent.
      debugPrint('⚠️ audio_service unavailable: $e');
      instance = null;
    }
  }

  /// Await the delegate's future (if any) and swallow errors — a
  /// platform callback must never crash the isolate; the controller
  /// already surfaces real failures in-app.
  Future<void> _run(Future<void>? Function()? action) async {
    try {
      await action?.call();
    } catch (e) {
      debugPrint('⚠️ tilawat service command failed: $e');
    }
  }

  @override
  Future<void> play() => _run(() => delegate?.servicePlay());

  @override
  Future<void> pause() => _run(() => delegate?.servicePause());

  @override
  Future<void> stop() async {
    await _run(() => delegate?.serviceStop());
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) =>
      _run(() => delegate?.serviceSeek(position));

  @override
  Future<void> skipToNext() => _run(() => delegate?.serviceNext());

  @override
  Future<void> skipToPrevious() => _run(() => delegate?.servicePrevious());
}
