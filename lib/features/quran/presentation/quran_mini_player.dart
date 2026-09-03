// lib/features/quran/presentation/quran_mini_player.dart
// ============================================================
// QIBRA AI — QURAN MINI PLAYER (restored — REAL state)
// ============================================================
// The bar deleted in earlier honesty passes ("fabricated 00:09/01:01
// timestamps"). This one renders ONLY real player state: hidden while
// idle, live position/duration from the player's streams (the total is
// simply absent until the player reports a duration), indeterminate
// line while buffering (a real 'working' signal, not fake progress),
// and the honest failure copy with an explicit user-initiated Retry —
// no silent loops. Persists across tabs (mounted in the app shell).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/design_system/qibra_navy.dart';
import '../data/audio/tilawat.dart';
import '../providers/quran_audio_provider.dart';

class QuranMiniPlayer extends ConsumerWidget {
  const QuranMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioProvider);
    if (!audio.active) return const SizedBox.shrink();

    final colors = QibraColors.of(context);
    final failed = audio.phase == QuranAudioPhase.failed;
    final ctrl = ref.read(quranAudioProvider.notifier);

    final Widget leading = audio.buffering || audio.phase == QuranAudioPhase.loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          )
        : Icon(
            failed
                ? Icons.error_outline_rounded
                : (audio.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.play_arrow_rounded),
            color: failed ? QibraNavy.red : colors.primary,
            size: 20,
          );

    final subtitle = failed
        ? (audio.error ?? Tilawat.offlineFailureMessage)
        : (audio.duration != null
            ? '${Tilawat.clockLabel(audio.position)} / '
                '${Tilawat.clockLabel(audio.duration!)}'
            : (audio.buffering
                ? 'Buffering…'
                : Tilawat.clockLabel(audio.position)));

    return Material(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: colors.border),
          // Real progress only: determinate when the player reports a
          // duration; an honest indeterminate line while it works;
          // nothing at all when neither applies.
          if (audio.progress != null)
            LinearProgressIndicator(
              value: audio.progress,
              minHeight: 2,
              color: colors.primary,
              backgroundColor: colors.border,
            )
          else if (audio.buffering ||
              audio.phase == QuranAudioPhase.loading)
            const LinearProgressIndicator(
              minHeight: 2,
            )
          else
            const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            child: Row(
              children: [
                SizedBox(width: 26, child: Center(child: leading)),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    // Opens the reader at the playing ayah — real nav.
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (audio.surahNumber == null) return;
                      context.push(
                        '${AppRoutes.surahReader}'
                        '?surah=${audio.surahNumber}'
                        '&ayah=${audio.ayahNumber ?? 1}',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${audio.surahName ?? 'Surah ${audio.surahNumber}'}'
                            ' · ${audio.ayahNumber ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: failed
                                  ? QibraNavy.red
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (failed)
                  TextButton(
                    onPressed: ctrl.retry,
                    child: Text(
                      'Retry',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.primary),
                    ),
                  ),
                IconButton(
                  tooltip: audio.isPlaying
                      ? 'Pause'
                      : (failed ? 'Retry' : 'Play'),
                  onPressed: ctrl.toggle,
                  icon: Icon(
                    audio.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Stop',
                  onPressed: ctrl.stop,
                  icon: Icon(Icons.stop_rounded, color: colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
