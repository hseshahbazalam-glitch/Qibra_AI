// lib/shared/widgets/cards/app_listen_card.dart
// ============================================================
// QIBRA AI — LISTEN CARD WIDGET (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: Audio listen card with:
//   - Left icon (audio/mic/headphones)
//   - Title + subtitle (Qari name)
//   - Animated waveform bars (center)
//   - Green play/pause button (right)
//   - Playing state animation
//   - Tap handler with haptic feedback
//   - Multiple variants (compact, standard, expanded)
// Usage: Quran screen, Home screen, Ayah detail
// Reference: "Listen to the Quran" card in reference Screen 2
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// SECTION 1 — ENUMS
// ============================================================

/// Card size variants
enum ListenCardSize {
  compact, // Height 60 - compact rows
  standard, // Height 72 - default (reference match)
  expanded, // Height 90 - detailed view
}

/// Playback state
enum ListenPlaybackState {
  stopped, // Not playing
  playing, // Currently playing (animate waveform)
  paused, // Paused (waveform static)
  loading, // Loading (show spinner)
}

// ============================================================
// SECTION 2 — LISTEN CARD WIDGET
// ============================================================

/// Premium audio listen card with animated waveform
///
/// Example usage:
/// ```dart
/// AppListenCard(
///   title: 'Listen to the Quran',
///   subtitle: 'Recitation by Mishary Rashid',
///   onPlayTap: () => print('Play tapped'),
/// )
/// ```
class AppListenCard extends StatefulWidget {
  /// Main title text
  final String title;

  /// Subtitle text (e.g., "Recitation by [Qari Name]")
  final String subtitle;

  /// Card size variant
  final ListenCardSize size;

  /// Current playback state
  final ListenPlaybackState playbackState;

  /// Left icon (default: headphones)
  final IconData leadingIcon;

  /// Play button tap handler
  final VoidCallback? onPlayTap;

  /// Card tap handler (whole card)
  final VoidCallback? onCardTap;

  /// Long press handler
  final VoidCallback? onLongPress;

  /// Show waveform bars in center
  final bool showWaveform;

  /// Number of waveform bars (default 5)
  final int waveformBarCount;

  /// Custom accent color (default: primary emerald)
  final Color? accentColor;

  /// Custom card background color (default: surface)
  final Color? backgroundColor;

  /// Show subtle border
  final bool showBorder;

  const AppListenCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.size = ListenCardSize.standard,
    this.playbackState = ListenPlaybackState.stopped,
    this.leadingIcon = Icons.graphic_eq_rounded,
    this.onPlayTap,
    this.onCardTap,
    this.onLongPress,
    this.showWaveform = true,
    this.waveformBarCount = 5,
    this.accentColor,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  State<AppListenCard> createState() => _AppListenCardState();
}

// ============================================================
// SECTION 3 — STATE CLASS
// ============================================================

class _AppListenCardState extends State<AppListenCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant AppListenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playbackState != oldWidget.playbackState) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.playbackState == ListenPlaybackState.playing) {
      _waveformController.repeat();
    } else {
      _waveformController.stop();
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = widget.accentColor ?? AppColors.primary;
    final Color effectiveBackground =
        widget.backgroundColor ?? AppColors.surface;
    final _CardDimensions dims = _getDimensions(widget.size);

    Widget card = Container(
      height: dims.height,
      padding: EdgeInsets.symmetric(
        horizontal: dims.horizontalPadding,
        vertical: dims.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: AppRadius.cardRadius,
        border: widget.showBorder
            ? Border.all(
                color: effectiveAccent.withValues(alpha: 0.20),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: effectiveAccent.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── LEFT: Leading icon container ─────────────────
          _buildLeadingIcon(dims, effectiveAccent),

          SizedBox(width: dims.iconSpacing),

          // ── CENTER: Title + Subtitle + Waveform ─────────
          Expanded(
            child: _buildCenterContent(dims, effectiveAccent),
          ),

          SizedBox(width: dims.iconSpacing),

          // ── RIGHT: Play/Pause button ─────────────────────
          _buildPlayButton(dims, effectiveAccent),
        ],
      ),
    );

    // Wrap with tap handler
    if (widget.onCardTap != null || widget.onLongPress != null) {
      card = GestureDetector(
        onTapDown: (_) => HapticFeedback.selectionClick(),
        onTap: widget.onCardTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: card,
      );
    }

    return card;
  }

  // ============================================================
  // SECTION 4 — SUB-COMPONENTS
  // ============================================================

  /// LEFT: Leading icon with animated background
  Widget _buildLeadingIcon(_CardDimensions dims, Color accent) {
    final bool isPlaying = widget.playbackState == ListenPlaybackState.playing;

    return Container(
      width: dims.iconSize,
      height: dims.iconSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.20),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(
          color: accent.withValues(alpha: isPlaying ? 0.50 : 0.30),
          width: 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(
        widget.leadingIcon,
        color: accent,
        size: dims.iconInnerSize,
      ),
    );
  }

  /// CENTER: Title + subtitle + waveform (or just text)
  Widget _buildCenterContent(_CardDimensions dims, Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: dims.titleSize,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: dims.titleSubtitleGap),

        // Subtitle + optional waveform (side-by-side)
        Row(
          children: [
            // Subtitle text
            Flexible(
              child: Text(
                widget.subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: dims.subtitleSize,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Waveform (only if enabled and space allows)
            if (widget.showWaveform) ...[
              SizedBox(width: dims.waveformGap),
              _buildWaveform(dims, accent),
            ],
          ],
        ),
      ],
    );
  }

  /// Waveform bars (animated when playing)
  Widget _buildWaveform(_CardDimensions dims, Color accent) {
    return SizedBox(
      width: dims.waveformWidth,
      height: dims.waveformHeight,
      child: AnimatedBuilder(
        animation: _waveformController,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.waveformBarCount, (index) {
              // Calculate bar height based on animation + index offset
              final double phase =
                  (_waveformController.value + (index * 0.15)) % 1.0;

              double barHeight;
              if (widget.playbackState == ListenPlaybackState.playing) {
                // Animated - each bar pulses with sine wave
                final double sineValue = math.sin(phase * 2 * math.pi).abs();
                barHeight = dims.waveformHeight * (0.30 + (sineValue * 0.70));
              } else {
                // Static - subtle heights
                final List<double> staticHeights = [0.5, 0.8, 0.4, 0.7, 0.6];
                barHeight = dims.waveformHeight *
                    staticHeights[index % staticHeights.length];
              }

              return Container(
                width: dims.waveformBarWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: widget.playbackState == ListenPlaybackState.playing
                        ? 0.85
                        : 0.50,
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// RIGHT: Play/Pause button
  Widget _buildPlayButton(_CardDimensions dims, Color accent) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.mediumImpact(),
      onTap: widget.onPlayTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: dims.playButtonSize,
        height: dims.playButtonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent,
              _darkenColor(accent, 0.15),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.40),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildPlayButtonIcon(dims),
      ),
    );
  }

  /// Play button icon (changes based on state)
  Widget _buildPlayButtonIcon(_CardDimensions dims) {
    switch (widget.playbackState) {
      case ListenPlaybackState.playing:
        return Icon(
          Icons.pause_rounded,
          color: AppColors.white,
          size: dims.playIconSize,
        );

      case ListenPlaybackState.paused:
      case ListenPlaybackState.stopped:
        return Icon(
          Icons.play_arrow_rounded,
          color: AppColors.white,
          size: dims.playIconSize,
        );

      case ListenPlaybackState.loading:
        return SizedBox(
          width: dims.playIconSize * 0.7,
          height: dims.playIconSize * 0.7,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        );
    }
  }

  // ============================================================
  // SECTION 5 — HELPERS
  // ============================================================

  /// Darken color helper
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get card dimensions based on size variant
  _CardDimensions _getDimensions(ListenCardSize size) {
    switch (size) {
      case ListenCardSize.compact:
        return const _CardDimensions(
          height: 60,
          horizontalPadding: AppSpacing.sm,
          verticalPadding: AppSpacing.xs,
          iconSize: 36,
          iconInnerSize: 18,
          iconSpacing: AppSpacing.sm,
          titleSize: 12,
          subtitleSize: 10,
          titleSubtitleGap: 2,
          waveformWidth: 28,
          waveformHeight: 12,
          waveformBarWidth: 2,
          waveformGap: 6,
          playButtonSize: 36,
          playIconSize: 20,
        );

      case ListenCardSize.standard:
        return const _CardDimensions(
          height: 72,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.sm,
          iconSize: 44,
          iconInnerSize: 22,
          iconSpacing: AppSpacing.md,
          titleSize: 14,
          subtitleSize: 11,
          titleSubtitleGap: 3,
          waveformWidth: 36,
          waveformHeight: 14,
          waveformBarWidth: 2.5,
          waveformGap: 8,
          playButtonSize: 44,
          playIconSize: 26,
        );

      case ListenCardSize.expanded:
        return const _CardDimensions(
          height: 90,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.md,
          iconSize: 54,
          iconInnerSize: 28,
          iconSpacing: AppSpacing.md,
          titleSize: 16,
          subtitleSize: 12,
          titleSubtitleGap: 4,
          waveformWidth: 44,
          waveformHeight: 18,
          waveformBarWidth: 3,
          waveformGap: 10,
          playButtonSize: 54,
          playIconSize: 32,
        );
    }
  }
}

// ============================================================
// SECTION 6 — DIMENSIONS HELPER CLASS
// ============================================================

class _CardDimensions {
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double iconInnerSize;
  final double iconSpacing;
  final double titleSize;
  final double subtitleSize;
  final double titleSubtitleGap;
  final double waveformWidth;
  final double waveformHeight;
  final double waveformBarWidth;
  final double waveformGap;
  final double playButtonSize;
  final double playIconSize;

  const _CardDimensions({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.iconInnerSize,
    required this.iconSpacing,
    required this.titleSize,
    required this.subtitleSize,
    required this.titleSubtitleGap,
    required this.waveformWidth,
    required this.waveformHeight,
    required this.waveformBarWidth,
    required this.waveformGap,
    required this.playButtonSize,
    required this.playIconSize,
  });
}

// ============================================================
// SECTION 7 — PRE-CONFIGURED VARIANTS
// ============================================================

/// Pre-configured Quran recitation listen card (reference match)
class AppQuranListenCard extends StatelessWidget {
  final String qariName;
  final ListenPlaybackState playbackState;
  final VoidCallback? onPlayTap;
  final VoidCallback? onCardTap;

  const AppQuranListenCard({
    super.key,
    this.qariName = 'Mishary Rashid',
    this.playbackState = ListenPlaybackState.stopped,
    this.onPlayTap,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListenCard(
      title: 'Listen to the Quran',
      subtitle: 'Recitation by $qariName',
      leadingIcon: Icons.graphic_eq_rounded,
      playbackState: playbackState,
      onPlayTap: onPlayTap,
      onCardTap: onCardTap,
      accentColor: AppColors.primary,
      showWaveform: true,
    );
  }
}

/// Pre-configured Adhan listen card
class AppAdhanListenCard extends StatelessWidget {
  final String muezzinName;
  final ListenPlaybackState playbackState;
  final VoidCallback? onPlayTap;

  const AppAdhanListenCard({
    super.key,
    this.muezzinName = 'Sheikh Ali Ahmed Mulla',
    this.playbackState = ListenPlaybackState.stopped,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListenCard(
      title: 'Play Adhan',
      subtitle: 'Muezzin: $muezzinName',
      leadingIcon: Icons.campaign_rounded,
      playbackState: playbackState,
      onPlayTap: onPlayTap,
      accentColor: AppColors.accent,
      showWaveform: true,
    );
  }
}

/// Pre-configured Dua audio listen card
class AppDuaListenCard extends StatelessWidget {
  final String duaTitle;
  final String reciterName;
  final ListenPlaybackState playbackState;
  final VoidCallback? onPlayTap;

  const AppDuaListenCard({
    super.key,
    required this.duaTitle,
    this.reciterName = 'Sheikh Sudais',
    this.playbackState = ListenPlaybackState.stopped,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListenCard(
      title: duaTitle,
      subtitle: 'Recited by $reciterName',
      leadingIcon: Icons.headphones_rounded,
      playbackState: playbackState,
      onPlayTap: onPlayTap,
      accentColor: const Color(0xFF7C3AED),
      showWaveform: true,
    );
  }
}

// ============================================================
// END OF FILE — app_listen_card.dart (v1.0)
// ============================================================
