// lib/features/qibla/presentation/qibla_screen.dart
// ============================================================
// QIBRA AI — QIBLA COMPASS (Stage C rebuild, midnight navy)
//
// Rebuilt from the 1,546-line gold-on-cream v2.0:
//  • All 85 hardcoded hexes and 47 alpha sites -> theme tokens
//  • Three permanently-looping AnimationControllers (pulse, shine,
//    float) removed — the needle moves when the sensor moves, and a
//    one-shot haptic marks alignment (perf rule: no looping
//    animations on scrollables)
//  • Kaaba emoji tiles and emoji toasts replaced by drawn elements
//    (the Kaaba marker is a plain cube with a kiswah band)
//  • The fake "3D" background wash (cream 0xFFEEF1EA over navy) is
//    gone; the dial is a flat navy surface + hairline
//  • Real sensor pipeline kept intact: flutter_compass stream with
//    EMA smoothing + spike rejection, magnetic-declination-corrected
//    needle from qiblaProvider
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_stat_card.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/services/qibla_service.dart';
import '../providers/qibla_provider.dart';

bool _qiblaAligned(QiblaState s) {
  final off = ((s.needleAngle % 360) + 360) % 360;
  return off < 5 || off > 355;
}

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  // Exponential moving-average low-pass filter to dampen compass jitter.
  // α (0..1) — smaller = smoother but slower.
  static const double _smoothingAlpha = 0.18;
  // Reject updates that jump > 45° (magnetic spikes).
  static const double _maxDeltaDeg = 45.0;

  double? _smoothedHeading;
  StreamSubscription<CompassEvent>? _compassSub;
  bool _hasCompass = true;

  @override
  void initState() {
    super.initState();
    final events = FlutterCompass.events;
    if (events == null) {
      _hasCompass = false;
    } else {
      _compassSub = events.listen((event) {
        if (!mounted || event.heading == null) return;
        final raw = event.heading!;
        final double filtered;
        if (_smoothedHeading == null) {
          filtered = raw;
        } else {
          final prev = _smoothedHeading!;
          // Shortest angular delta (handles the 0/360 wrap).
          var delta = raw - prev;
          delta = (delta + 180) % 360 - 180;
          if (delta > _maxDeltaDeg) {
            delta = _maxDeltaDeg;
          } else if (delta < -_maxDeltaDeg) {
            delta = -_maxDeltaDeg;
          }
          filtered = (prev + _smoothingAlpha * delta + 360) % 360;
        }
        _smoothedHeading = filtered;
        ref.read(qiblaProvider.notifier).updateCompassHeading(filtered);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qiblaProvider.notifier).loadQibla();
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _shareQibla(QiblaResult result) {
    final text = '''Qibla direction

Location: ${result.city ?? result.locationName}${result.country != null ? ', ${result.country}' : ''}
Bearing: ${result.qiblaAngle.toStringAsFixed(1)}° from true north
Distance to Makkah: ${QiblaService.formatDistance(result.distanceToMakkah)}
Coordinates: ${result.formattedCoordinates}

Shared via QIBRA AI''';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _toast('Qibla info copied');
  }

  void _copyCoordinates(QiblaResult result) {
    Clipboard.setData(ClipboardData(text: result.formattedCoordinates));
    HapticFeedback.lightImpact();
    _toast('Coordinates copied');
  }

  void _toast(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: colors.cardMuted,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final state = ref.watch(qiblaProvider);

    // One-shot haptic the moment the user lines up with the Qibla.
    ref.listen<bool>(qiblaProvider.select(_qiblaAligned), (prev, next) {
      if (next && prev != true) HapticFeedback.mediumImpact();
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: QibraAppBar(
        title: 'Qibla',
        subtitle: 'Direction of the Kaaba',
        actions: [
          if (state.result != null)
            IconButton(
              tooltip: 'Copy qibla info',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareQibla(state.result!),
            ),
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(qiblaProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          QiblaStatus.loading ||
          QiblaStatus.initial =>
            const _QiblaLoadingBody(),
          QiblaStatus.error => QibraStatus.error(
              title: 'Qibla unavailable',
              message: state.errorMessage ??
                  'Location permission is required to compute the '
                      'Qibla bearing.',
              onRetry: () => ref.read(qiblaProvider.notifier).loadQibla(),
            ),
          QiblaStatus.loaded => _QiblaBody(
              state: state,
              hasCompass: _hasCompass,
              onCopyCoordinates: state.result == null
                  ? null
                  : () => _copyCoordinates(state.result!),
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Loading
// ─────────────────────────────────────────────────────────────

class _QiblaLoadingBody extends StatelessWidget {
  const _QiblaLoadingBody();

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.my_location_rounded,
              size: 44,
              color: colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Finding your location…',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 20),
        QibraStatus.skeleton(height: 72),
        const SizedBox(height: 12),
        QibraStatus.skeleton(height: 120),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────

class _QiblaBody extends StatelessWidget {
  const _QiblaBody({
    required this.state,
    required this.hasCompass,
    this.onCopyCoordinates,
  });

  final QiblaState state;
  final bool hasCompass;
  final VoidCallback? onCopyCoordinates;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final result = state.result;
    final needleAngle = state.needleAngle;
    final offset = ((needleAngle % 360) + 360) % 360;
    final aligned = offset < 5 || offset > 355;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (result?.isFromCache ?? false) ...[
          const _CacheNotice(),
          const SizedBox(height: 12),
        ],
        // Compass card
        QibraCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              _CompassDial(
                heading: state.compassHeading,
                needleAngle: needleAngle,
                aligned: aligned,
                live: hasCompass,
              ),
              const SizedBox(height: 16),
              _AlignmentStatus(
                aligned: aligned,
                offsetDeg: offset,
                live: hasCompass,
                bearing: result?.qiblaAngle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result != null) ...[
          const QibraSectionHeader(title: 'Direction details'),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: QibraStatCard(
                    icon: Icons.mosque_rounded,
                    value: QiblaService.formatDistance(result.distanceToMakkah),
                    label: 'Straight-line distance to the Kaaba',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QibraStatCard(
                    icon: Icons.explore_outlined,
                    value: '${result.qiblaAngle.toStringAsFixed(1)}°',
                    label: 'Bearing from true north',
                    footnote: result.declinationNote,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _LocationCard(
            result: result,
            onCopyCoordinates: onCopyCoordinates,
          ),
          const SizedBox(height: 12),
        ],
        const _HowToCard(),
        const SizedBox(height: 16),
        Text(
          'Bearing is computed from your coordinates; the dial follows '
          'the device magnetometer when available.',
          style: AppTextStyles.labelSmall
              .copyWith(color: colors.textTertiary, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CacheNotice extends StatelessWidget {
  const _CacheNotice();

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using the last known location. Pull refresh for '
              'current accuracy.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dial
// ─────────────────────────────────────────────────────────────

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.heading,
    required this.needleAngle,
    required this.aligned,
    required this.live,
  });

  final double heading;
  final double needleAngle;
  final bool aligned;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring — the only "glow" is a solid emerald border when aligned.
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(
                color: aligned ? colors.primary : colors.border,
                width: aligned ? 2 : 1,
              ),
            ),
          ),
          // Rotating dial: ticks + cardinals.
          Transform.rotate(
            angle: -heading * math.pi / 180,
            child: Container(
              width: 276,
              height: 276,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.cardMuted,
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(276, 276),
                    painter: _DialPainter(
                      major: colors.textSecondary,
                      minor: colors.border,
                      label: colors.textTertiary,
                    ),
                  ),
                  ..._cardinals(colors),
                ],
              ),
            ),
          ),
          // North indicator (fixed at 12 o'clock, outside the dial).
          Positioned(
            top: 2,
            child: Icon(
              Icons.navigation_rounded,
              size: 16,
              color: live ? colors.primary : colors.textTertiary,
            ),
          ),
          // Needle + Kaaba marker (declination-corrected).
          AnimatedRotation(
            turns: needleAngle / 360,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 276,
              height: 276,
              child: CustomPaint(
                painter: _NeedlePainter(
                  tip: aligned ? colors.primary : colors.accent,
                  tail: colors.textTertiary,
                ),
              ),
            ),
          ),
          AnimatedRotation(
            turns: needleAngle / 360,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Transform.translate(
              offset: const Offset(0, -104),
              child: const _KaabaMarker(),
            ),
          ),
          // Hub.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(
                color: aligned ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aligned ? colors.primary : colors.textTertiary,
                ),
              ),
            ),
          ),
          if (!live)
            Positioned(
              bottom: 46,
              child: Text(
                'No magnetometer — bearing only',
                style: AppTextStyles.labelSmall
                    .copyWith(color: colors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _cardinals(QibraColors colors) {
    const entries = <(String, Alignment)>[
      ('N', Alignment.topCenter),
      ('E', Alignment.centerRight),
      ('S', Alignment.bottomCenter),
      ('W', Alignment.centerLeft),
    ];
    return [
      for (final (label, align) in entries)
        Align(
          alignment: align,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: label == 'N' ? colors.textPrimary : colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ];
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    // A drawn cube with a kiswah band — no emoji.
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.accent, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(height: 3, color: colors.accent),
        ],
      ),
    );
  }
}

class _AlignmentStatus extends StatelessWidget {
  const _AlignmentStatus({
    required this.aligned,
    required this.offsetDeg,
    required this.live,
    this.bearing,
  });

  final bool aligned;
  final double offsetDeg;
  final bool live;
  final double? bearing;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    if (aligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'You are facing the Qibla',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    final eff = offsetDeg > 180 ? 360 - offsetDeg : offsetDeg;
    final dir = offsetDeg < 180 ? 'right' : 'left';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          offsetDeg < 180
              ? Icons.rotate_right_rounded
              : Icons.rotate_left_rounded,
          size: 18,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          live
              ? 'Turn ${eff.toStringAsFixed(0)}° $dir to align'
              : (bearing != null
                  ? 'Qibla bearing ${bearing!.toStringAsFixed(1)}° '
                      'from true north'
                  : 'Qibla bearing unavailable'),
          style: AppTextStyles.titleSmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Location + usage cards
// ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.result, this.onCopyCoordinates});

  final QiblaResult result;
  final VoidCallback? onCopyCoordinates;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    result.city ?? result.locationName,
                    result.country,
                  ].where((e) => e != null && e.isNotEmpty).join(', '),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (result.accuracy != null)
                Text(
                  '${result.accuracyText} · ±${result.accuracy!.toStringAsFixed(0)} m',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinates',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.formattedCoordinates,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.altitude != null && result.altitude! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Altitude ${result.altitude!.toStringAsFixed(0)} m',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onCopyCoordinates != null)
                IconButton(
                  tooltip: 'Copy coordinates',
                  icon: Icon(Icons.copy_rounded,
                      size: 18, color: colors.textSecondary),
                  onPressed: onCopyCoordinates,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard();

  static const _steps = <(IconData, String)>[
    (
      Icons.screen_rotation_rounded,
      'Hold the phone flat, parallel to the ground',
    ),
    (
      Icons.sensors_off_rounded,
      'Keep away from metal, magnets and cases with magnets',
    ),
    (
      Icons.rotate_right_rounded,
      'Rotate until the Kaaba marker meets the top marker',
    ),
    (
      Icons.check_circle_outline_rounded,
      'The ring turns emerald when you are aligned',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QibraSectionHeader(title: 'How to use'),
          const SizedBox(height: 12),
          for (final (i, step) in _steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(step.$1, size: 15, color: colors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.$2,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (i != _steps.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painters (token colors passed in)
// ─────────────────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.major,
    required this.minor,
    required this.label,
  });

  final Color major;
  final Color minor;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorPaint = Paint()
      ..color = major
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = minor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final isMajor = i % 6 == 0;
      final length = isMajor ? 14.0 : 5.0;
      final outer = radius - 16;
      final inner = outer - length;
      final start = Offset(
        center.dx + outer * math.sin(angle),
        center.dy - outer * math.cos(angle),
      );
      final end = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorPaint : minorPaint);
    }

    for (final deg in const [30, 60, 120, 150, 210, 240, 300, 330]) {
      final angle = deg * math.pi / 180;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$deg',
          style: TextStyle(
            color: label,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final r = radius - 42;
      textPainter.paint(
        canvas,
        Offset(
          center.dx + r * math.sin(angle) - textPainter.width / 2,
          center.dy - r * math.cos(angle) - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.major != major || old.minor != minor || old.label != label;
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({required this.tip, required this.tail});

  final Color tip;
  final Color tail;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final length = size.height * 0.38;
    const halfWidth = 6.0;

    final top = Offset(center.dx, center.dy - length);
    final bottom = Offset(center.dx, center.dy + length * 0.55);
    final left = Offset(center.dx - halfWidth, center.dy);
    final right = Offset(center.dx + halfWidth, center.dy);

    final upper = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    final lower = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    canvas.drawPath(lower, Paint()..color = tail);
    canvas.drawPath(upper, Paint()..color = tip);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.tip != tip || old.tail != tail;
}
