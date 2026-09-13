// lib/features/quran/presentation/quran_mini_player.dart
// ============================================================
// QIBRA AI — QURAN MINI PLAYER (Pass Q1 — full transport, REAL state)
// ============================================================
// Renders ONLY real player state: hidden while idle, live position and
// duration from the player's streams (the total — and with it the scrub
// slider — is simply ABSENT until the player reports a real duration),
// an indeterminate line while buffering, and the honest failure copy with
// an explicit user-initiated Retry. No silent loops.
//
// Pass Q1 additions, all driven by the controller (never local guesses):
// prev/play/next transport, a real seek slider (clamped to [0, duration]),
// a hifz summary row (repeat mode/count, range, speed) with a tune menu
// to set them, the qari name in the subtitle, and a range-pick banner
// while the reader is waiting for a range endpoint tap.
// Persists across tabs (mounted in the app shell).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import '../data/audio/tilawat.dart';
import '../providers/quran_audio_provider.dart';

class QuranMiniPlayer extends ConsumerStatefulWidget {
  const QuranMiniPlayer({super.key});

  @override
  ConsumerState<QuranMiniPlayer> createState() => _QuranMiniPlayerState();
}

class _QuranMiniPlayerState extends ConsumerState<QuranMiniPlayer> {
  /// Live drag value while the user scrubs (ms). Null = follow the
  /// player. Seeking only happens on release — onChangeEnd — with the
  /// clamped target (never a mid-drag seek storm).
  double? _dragMs;

  void _handleMenu(String v) {
    final ctrl = ref.read(quranAudioProvider.notifier);
    switch (v) {
      case 'off':
        ctrl.setRepeatMode(QuranRepeatMode.off);
      case 'ayah':
        ctrl.setRepeatMode(QuranRepeatMode.ayah);
      case 'range':
        ctrl.setRepeatMode(QuranRepeatMode.range);
      case 'n1':
        ctrl.setRepeatCount(1);
      case 'n3':
        ctrl.setRepeatCount(3);
      case 'n5':
        ctrl.setRepeatCount(5);
      case 'n20':
        ctrl.setRepeatCount(Tilawat.maxAyahRepeats);
      case 's075':
        ctrl.setSpeed(0.75);
      case 's100':
        ctrl.setSpeed(1.0);
      case 's125':
        ctrl.setSpeed(1.25);
      case 's150':
        ctrl.setSpeed(1.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(quranAudioProvider);
    if (!audio.active) return const SizedBox.shrink();

    final strings = AppStrings.of(context);
    final colors = QibraColors.of(context);
    final failed = audio.phase == QuranAudioPhase.failed;
    final ctrl = ref.read(quranAudioProvider.notifier);

    final Widget leading = audio.buffering ||
            audio.phase == QuranAudioPhase.loading
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

    final dur = audio.duration;
    final subtitle = failed
        ? (audio.error ?? Tilawat.offlineFailureMessage)
        : (dur != null
            ? '${Tilawat.clockLabel(audio.position)} / '
                '${Tilawat.clockLabel(dur)}'
            : (audio.buffering
                ? 'Buffering…'
                : Tilawat.clockLabel(audio.position)));
    final subtitleWithQari = audio.qariName.isEmpty
        ? subtitle
        : '$subtitle · ${audio.qariName}';

    final hifzActive = audio.repeatMode != QuranRepeatMode.off ||
        audio.speed != 1.0;

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
          else if (audio.buffering || audio.phase == QuranAudioPhase.loading)
            const LinearProgressIndicator(
              minHeight: 2,
            )
          else
            const SizedBox(height: 2),
          // Range arming banner: while set, the NEXT ayah tap in the
          // reader fixes the start (then the end). Tap here to abandon.
          if (audio.rangePick != QuranRangePick.none)
            InkWell(
              onTap: ctrl.cancelRangePick,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        audio.rangePick == QuranRangePick.start
                            ? strings.pickStartAyah
                            : strings.pickEndAyah,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                            subtitleWithQari,
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
                      strings.retry,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.primary),
                    ),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Previous ayah',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                        minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: ctrl.prevAyah,
                    icon: Icon(Icons.skip_previous_rounded,
                        size: 22, color: colors.textPrimary),
                  ),
                  IconButton(
                    tooltip: audio.isPlaying ? 'Pause' : 'Play',
                    onPressed: ctrl.toggle,
                    icon: Icon(
                      audio.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next ayah',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                        minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: ctrl.nextAyah,
                    icon: Icon(Icons.skip_next_rounded,
                        size: 22, color: colors.textPrimary),
                  ),
                  // Tune: repeat mode/count + speed, in one compact menu.
                  PopupMenuButton<String>(
                    tooltip: strings.repeat,
                    enabled: !audio.buffering,
                    color: colors.card,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 34, minHeight: 34),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: hifzActive ? colors.primary : colors.textTertiary,
                    ),
                    onSelected: _handleMenu,
                    itemBuilder: (menuContext) => [
                      PopupMenuItem<String>(
                          value: 'off', child: Text(strings.repeatOff)),
                      PopupMenuItem<String>(
                          value: 'ayah', child: Text(strings.repeatAyah)),
                      PopupMenuItem<String>(
                          value: 'range', child: Text(strings.repeatRange)),
                      const PopupMenuItem<String>(value: 'n1', child: Text('1×')),
                      const PopupMenuItem<String>(value: 'n3', child: Text('3×')),
                      const PopupMenuItem<String>(value: 'n5', child: Text('5×')),
                      const PopupMenuItem<String>(
                          value: 'n20', child: Text('20×')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                          value: 's075', child: Text('0.75×')),
                      const PopupMenuItem<String>(
                          value: 's100', child: Text('1×')),
                      const PopupMenuItem<String>(
                          value: 's125', child: Text('1.25×')),
                      const PopupMenuItem<String>(
                          value: 's150', child: Text('1.5×')),
                    ],
                  ),
                ],
                IconButton(
                  tooltip: 'Stop',
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 34, minHeight: 34),
                  padding: EdgeInsets.zero,
                  onPressed: ctrl.stop,
                  icon:
                      Icon(Icons.stop_rounded, size: 20, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          // Hifz row — only when something non-default is set. Real
          // state echoed, tap the tune menu to change.
          if (hifzActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  if (audio.repeatMode != QuranRepeatMode.off)
                    _MiniChip(
                      icon: Icons.repeat_rounded,
                      label: audio.repeatMode == QuranRepeatMode.ayah
                          ? '${strings.repeatAyah} · ${audio.repeatCount}×'
                          : (audio.rangeStart > 0 && audio.rangeEnd > 0
                              ? '${strings.repeatRange} · '
                                  '${audio.rangeStart}–${audio.rangeEnd}'
                              : '${strings.repeatRange} · ${strings.rangeNotSet}'),
                      color: colors.primary,
                    ),
                  if (audio.speed != 1.0) ...[
                    const SizedBox(width: 6),
                    _MiniChip(
                      icon: Icons.speed_rounded,
                      label: '${audio.speed}×',
                      color: colors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          // Scrubbing exists ONLY when the duration is real; the seek
          // target is clamped to [0, duration] below.
          if (dur != null && !failed)
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 2,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                trackShape: RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                activeColor: colors.primary,
                inactiveColor: colors.border,
                min: 0,
                max: dur.inMilliseconds.toDouble(),
                value: (_dragMs ??
                        audio.position.inMilliseconds
                            .clamp(0, dur.inMilliseconds))
                    .toDouble()
                    .clamp(0.0, dur.inMilliseconds.toDouble()),
                onChanged: (v) => setState(() => _dragMs = v),
                onChangeEnd: (v) {
                  setState(() => _dragMs = null);
                  ctrl.seek(Duration(milliseconds: v.round()));
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
