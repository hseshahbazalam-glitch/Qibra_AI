// lib/features/quran/presentation/quran_audio_player.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/audio_provider.dart';
import '../services/quran_audio_service.dart';

// ============================================================
// SECTION 1 — AYAH PLAY BUTTON
// ============================================================

class AyahPlayButton extends ConsumerWidget {
  const AyahPlayButton({
    super.key,
    required this.surahNumber,
    required this.ayah,
    this.size = 36,
  });

  final int surahNumber;
  final AyahModel ayah;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch audio state
    final audioState = ref.watch(audioProvider);

    final bool isThisAyahActive = audioState.isActive &&
        audioState.surahNumber == surahNumber &&
        audioState.ayahNumber == ayah.number;

    final bool isThisAyahPlaying = isThisAyahActive && audioState.isPlaying;
    final bool isThisAyahLoading = isThisAyahActive && audioState.isLoading;

    return InkWell(
      onTap: () {
        print(
          '[QIBRA_TEST] *** TAP! surah=$surahNumber '
          'ayah=${ayah.number} global=${ayah.numberInQuran} '
          'isActive=$isThisAyahActive ***',
        );
        HapticFeedback.selectionClick();

        // ALWAYS play fresh for testing
        ref.read(audioProvider.notifier).playAyah(
              surahNumber: surahNumber,
              ayahNumber: ayah.number,
              globalAyahNumber: ayah.numberInQuran,
            );
      },
      borderRadius: BorderRadius.circular(size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isThisAyahActive
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.surfaceElevated.withValues(alpha: 0.80),
          border: Border.all(
            color: isThisAyahActive
                ? AppColors.primary.withValues(alpha: 0.50)
                : AppColors.primary.withValues(alpha: 0.14),
            width: isThisAyahActive ? 1.5 : 1.0,
          ),
        ),
        child: isThisAyahLoading
            ? Padding(
                padding: EdgeInsets.all(size * 0.22),
                child: const CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                isThisAyahPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: size * 0.52,
                color: isThisAyahActive
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
      ),
    );
  }
}

// ============================================================
// SECTION 2 — MINI PLAYER
// ============================================================

class QuranMiniPlayer extends ConsumerWidget {
  const QuranMiniPlayer({
    super.key,
    required this.surahName,
  });

  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);

    if (!audioState.isActive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => QuranFullPlayer.show(context: context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.92),
              AppColors.primary.withValues(alpha: 0.78),
              AppColors.accent.withValues(alpha: 0.70),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$surahName — Ayah ${audioState.ayahNumber ?? ''}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    audioState.reciter.name,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Prev
            _MiniBtn(
              icon: Icons.skip_previous_rounded,
              onTap: () => ref.read(audioProvider.notifier).playPrevious(),
            ),
            // Play/Pause
            _MiniPlayPause(audioState: audioState),
            // Next
            _MiniBtn(
              icon: Icons.skip_next_rounded,
              onTap: () => ref.read(audioProvider.notifier).playNext(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _MiniPlayPause extends ConsumerWidget {
  const _MiniPlayPause({required this.audioState});

  final QuranAudioState audioState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(audioProvider.notifier).togglePlayPause(),
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(left: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: audioState.isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                audioState.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }
}

// ============================================================
// SECTION 3 — FULL PLAYER
// ============================================================

class QuranFullPlayer extends ConsumerStatefulWidget {
  const QuranFullPlayer({super.key});

  static Future<void> show({required BuildContext context}) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => const QuranFullPlayer(),
    );
  }

  @override
  ConsumerState<QuranFullPlayer> createState() => _QuranFullPlayerState();
}

class _QuranFullPlayerState extends ConsumerState<QuranFullPlayer> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            _buildHeader(audioState),
            const SizedBox(height: AppSpacing.xl2),

            // Status
            _buildStatusBadge(audioState),
            const SizedBox(height: AppSpacing.lg),

            // Reciter info
            Text(
              audioState.reciter.name,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Progress bar
            _buildProgressBar(audioState),
            const SizedBox(height: AppSpacing.lg),

            // Controls
            _buildControls(audioState),
            const SizedBox(height: AppSpacing.lg),

            // Bottom row
            _buildBottomRow(audioState),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QuranAudioState audioState) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.90),
                AppColors.accent.withValues(alpha: 0.80),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Now Reciting',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                audioState.isActive
                    ? 'Ayah ${audioState.ayahNumber}'
                    : 'No Ayah Selected',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.80),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(QuranAudioState audioState) {
    final color = audioState.isPlaying
        ? AppColors.primary
        : audioState.isLoading
            ? AppColors.accent
            : AppColors.textTertiary;

    final label = audioState.isPlaying
        ? '● Playing'
        : audioState.isLoading
            ? '◌ Loading...'
            : audioState.isPaused
                ? '‖ Paused'
                : '■ Stopped';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildProgressBar(QuranAudioState audioState) {
    final progress = _isDragging ? _dragValue : audioState.progress;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.16),
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChangeStart: (val) {
              setState(() {
                _isDragging = true;
                _dragValue = val;
              });
            },
            onChanged: (val) {
              setState(() => _dragValue = val);
            },
            onChangeEnd: (val) {
              setState(() => _isDragging = false);
              ref.read(audioProvider.notifier).seekToFraction(val);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audioState.positionFormatted,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                audioState.durationFormatted,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(QuranAudioState audioState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev
        _CtrlBtn(
          icon: Icons.skip_previous_rounded,
          size: 48,
          iconSize: 26,
          onTap: () => ref.read(audioProvider.notifier).playPrevious(),
        ),
        const SizedBox(width: AppSpacing.xl),

        // Play/Pause large
        GestureDetector(
          onTap: () => ref.read(audioProvider.notifier).togglePlayPause(),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.95),
                  AppColors.primary.withValues(alpha: 0.78),
                  AppColors.accent.withValues(alpha: 0.72),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: audioState.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    audioState.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // Next
        _CtrlBtn(
          icon: Icons.skip_next_rounded,
          size: 48,
          iconSize: 26,
          onTap: () => ref.read(audioProvider.notifier).playNext(),
        ),
      ],
    );
  }

  Widget _buildBottomRow(QuranAudioState audioState) {
    return Row(
      children: [
        // Auto-play
        Expanded(
          child: GestureDetector(
            onTap: () => ref.read(audioProvider.notifier).toggleAutoPlay(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: audioState.isAutoPlayEnabled
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.surfaceElevated.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: audioState.isAutoPlayEnabled
                      ? AppColors.primary.withValues(alpha: 0.32)
                      : AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: audioState.isAutoPlayEnabled
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Auto',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: audioState.isAutoPlayEnabled
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Reciter
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              ReciterSelectorSheet.show(context: context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      audioState.reciter.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Stop
        Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(audioProvider.notifier).stop();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stop_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 5),
                  Text(
                    'Stop',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.80),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
      ),
    );
  }
}

// ============================================================
// SECTION 4 — RECITER SELECTOR
// ============================================================

class ReciterSelectorSheet extends ConsumerWidget {
  const ReciterSelectorSheet({super.key});

  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => const ReciterSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentReciter = ref.watch(currentReciterProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Select Reciter',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...QuranReciters.all.map(
            (reciter) => _ReciterTile(
              reciter: reciter,
              isSelected: reciter == currentReciter,
              onTap: () async {
                await ref.read(audioProvider.notifier).setReciter(reciter);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.isSelected,
    required this.onTap,
  });

  final QuranReciter reciter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.40)
                  : AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.surfaceHigh.withValues(alpha: 0.70),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  size: 20,
                  color:
                      isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      reciter.nameArabic,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'Amiri',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — quran_audio_player.dart
// ============================================================
