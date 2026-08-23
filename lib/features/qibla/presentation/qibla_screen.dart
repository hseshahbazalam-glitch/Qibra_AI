// lib/features/qibla/presentation/qibla_screen.dart

// ============================================================
// QIBRA AI — PREMIUM 3D QIBLA COMPASS (v2.0)
// Beautiful 3D compass + Enhanced info + Location
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import '../providers/qibla_provider.dart';
import '../data/services/qibla_service.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shineController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _shineAnim;
  late Animation<double> _floatAnim;

  // Exponential moving-average low-pass filter to dampen compass jitter.
  // α (0..1) — smaller = smoother but slower response.  0.18 ≈ 82% weight on past.
  static const double _compassSmoothingAlpha = 0.18;
  // Reject updates that jump > 45° instantaneously (magnetic spikes).
  static const double _maxDeltaPerSampleDeg = 45.0;
  double? _smoothedHeading;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_shineController);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qiblaProvider.notifier).loadQibla();
    });

    FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      final raw = event.heading!;
      final double filtered;
      if (_smoothedHeading == null) {
        filtered = raw;
      } else {
        final prev = _smoothedHeading!;
        // Compute shortest angular delta (handles wrap-around 0/360).
        double delta = raw - prev;
        delta = (delta + 180) % 360 - 180;
        if (delta > _maxDeltaPerSampleDeg) {
          delta = _maxDeltaPerSampleDeg;
        } else if (delta < -_maxDeltaPerSampleDeg) {
          delta = -_maxDeltaPerSampleDeg;
        }
        filtered = (prev + _compassSmoothingAlpha * delta + 360) % 360;
      }
      _smoothedHeading = filtered;
      ref.read(qiblaProvider.notifier).updateCompassHeading(filtered);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _calibrate() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.compass_calibration_rounded,
                color: Color(0xFFC6A15B), size: 24),
            const SizedBox(width: 8),
            Text('Calibrate Compass',
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To calibrate your compass:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _calibrationStep('1', 'Hold phone flat in your hand'),
            _calibrationStep('2', 'Move phone in figure-8 pattern'),
            _calibrationStep('3', 'Rotate 360° slowly'),
            _calibrationStep('4', 'Keep away from metal objects'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC6A15B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFC6A15B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Move phone slowly for best results',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFC6A15B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: Color(0xFFC6A15B))),
          ),
        ],
      ),
    );
  }

  Widget _calibrationStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFC6A15B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                    color: const Color(0xFF19312C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _shareQibla() {
    final state = ref.read(qiblaProvider);
    final result = state.result;
    if (result == null) return;

    final text = '''🕋 Qibla Direction

📍 Location: ${result.city ?? 'Unknown'}, ${result.country ?? ''}
🧭 Direction: ${result.qiblaAngle.toStringAsFixed(1)}° from North
📏 Distance to Makkah: ${QiblaService.formatDistance(result.distanceToMakkah)}
🗺️ Coordinates: ${result.formattedCoordinates}

Shared via Qibra AI 🌙''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: const Color(0xFF19312C), size: 18),
            SizedBox(width: 8),
            Text('📋 Qibla info copied - paste to share'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qiblaState = ref.watch(qiblaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (qiblaState.result?.isFromCache == true)
                        _buildCacheWarning(),
                      const SizedBox(height: 20),
                      // Location card (NEW)
                      if (qiblaState.result != null)
                        _buildLocationCard(qiblaState),
                      const SizedBox(height: 20),
                      // 3D Compass
                      _build3DCompass(qiblaState),
                      const SizedBox(height: 32),
                      // Angle badge
                      if (qiblaState.result != null)
                        _buildAngleBadge(qiblaState),
                      const SizedBox(height: 20),
                      // Enhanced Info cards
                      _buildEnhancedInfoCards(qiblaState),
                      const SizedBox(height: 12),
                      // Coordinates card (NEW)
                      if (qiblaState.result != null)
                        _buildCoordinatesCard(qiblaState),
                      const SizedBox(height: 20),
                      // Action buttons row (NEW)
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                      // Instructions
                      _buildInstructions(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMATED BACKGROUND
  // ============================================================

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              const Color(0xFFEEF1EA).withValues(alpha: 0.4),
              const Color(0xFF19312C).withValues(alpha: 0.6),
              AppColors.background,
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القبلة',
                        style: AppTextStyles.arabicLarge.copyWith(
                          color: const Color(0xFFC6A15B),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFF2F6B5D)],
                        ).createShader(bounds),
                        child: Text(
                          'Qibla Direction',
                          style: AppTextStyles.displaySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            color: const Color(0xFF19312C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Share button (NEW)
                GestureDetector(
                  onTap: _shareQibla,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC6A15B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFFC6A15B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCacheWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC6A15B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC6A15B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC6A15B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Using cached location. Tap refresh for accuracy.',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFFC6A15B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION CARD (NEW)
  // ============================================================

  Widget _buildLocationCard(QiblaState state) {
    final result = state.result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC6A15B).withValues(alpha: 0.15),
            const Color(0xFF2F6B5D).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC6A15B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC6A15B), Color(0xFF2F6B5D)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC6A15B).withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: const Color(0xFF19312C),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.city ?? 'Unknown',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF19312C),
                  ),
                ),
                if (result.country != null && result.country!.isNotEmpty)
                  Text(
                    result.country!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF19312C).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (result.accuracy != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getAccuracyColor(result.accuracy!)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              size: 10,
                              color: _getAccuracyColor(result.accuracy!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.accuracyText} (${result.accuracy!.toStringAsFixed(0)}m)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getAccuracyColor(result.accuracy!),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy < 5) return const Color(0xFF2F6B5D);
    if (accuracy < 15) return const Color(0xFF2F6B5D);
    if (accuracy < 30) return const Color(0xFFC6A15B);
    return const Color(0xFFEF4444);
  }

  // ============================================================
  // 3D COMPASS (Unchanged - Already Perfect!)
  // ============================================================

  Widget _build3DCompass(QiblaState state) {
    if (state.status == QiblaStatus.loading) {
      return _buildLoadingCompass();
    }

    if (state.status == QiblaStatus.error) {
      return _buildErrorCompass(state.errorMessage);
    }

    final needleAngle = state.needleAngle;
    final normalizedAngle = ((needleAngle % 360) + 360) % 360;
    final isAligned = normalizedAngle < 5 || normalizedAngle > 355;

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isAligned)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.4),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: isAligned
                    ? [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary,
                      ]
                    : [
                        const Color(0xFFC6A15B),
                        const Color(0xFF2F6B5D),
                        const Color(0xFF123F36),
                        const Color(0xFF2F6B5D),
                        const Color(0xFFC6A15B),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isAligned ? AppColors.primary : const Color(0xFFC6A15B))
                          .withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          Container(
            width: 292,
            height: 292,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF2C3B36),
                  Color(0xFF19312C),
                  Colors.black,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: -state.compassHeading * math.pi / 180,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  colors: [
                    Color(0xFFD4CFC3),
                    Color(0xFF2C3B36),
                    Color(0xFF19312C),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(painter: _CompassFacePainter()),
            ),
          ),
          AnimatedBuilder(
            animation: _shineAnim,
            builder: (_, __) => Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.03),
                  ],
                  stops: [
                    0.0,
                    _shineAnim.value * 0.5,
                    _shineAnim.value * 0.5 + 0.1,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
          AnimatedRotation(
            turns: needleAngle / 360,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: _Premium3DNeedlePainter(isAligned: isAligned),
              ),
            ),
          ),
          AnimatedRotation(
            turns: needleAngle / 360,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Transform.translate(
              offset: const Offset(0, -110),
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: _buildFloatingKaaba(isAligned),
                ),
              ),
            ),
          ),
          _buildCenterHub(isAligned),
          Transform.rotate(
            angle: -state.compassHeading * math.pi / 180,
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(children: _buildCardinalDirections()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingKaaba(bool isAligned) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF19312C), Color(0xFF19312C), Colors.black],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC6A15B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? AppColors.primary : const Color(0xFFC6A15B))
                .withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 8,
            margin: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFC6A15B),
                  Color(0xFFC6A15B),
                  Color(0xFFC6A15B),
                ],
              ),
            ),
          ),
          const Text('🕋', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildCenterHub(bool isAligned) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: isAligned
              ? [
                  const Color(0xFF2F6B5D),
                  AppColors.primary,
                  const Color(0xFF123F36),
                  const Color(0xFF123F36),
                ]
              : [
                  const Color(0xFF2F6B5D),
                  const Color(0xFFC6A15B),
                  const Color(0xFF2F6B5D),
                  const Color(0xFF123F36),
                ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? AppColors.primary : const Color(0xFFC6A15B))
                .withValues(alpha: 0.7),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black,
            blurRadius: 6,
            offset: Offset(0, 3),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF19312C).withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF19312C).withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardinalDirections() {
    final positions = [
      ('N', 0.0, Alignment.topCenter, AppColors.error),
      ('E', 90.0, Alignment.centerRight, Colors.white.withValues(alpha: 0.8)),
      ('S', 180.0, Alignment.bottomCenter, Colors.white.withValues(alpha: 0.8)),
      ('W', 270.0, Alignment.centerLeft, Colors.white.withValues(alpha: 0.8)),
    ];

    return positions.map((p) {
      return Align(
        alignment: p.$3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.$1 == 'N'
                  ? AppColors.error.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Center(
              child: Text(
                p.$1,
                style: AppTextStyles.labelSmall.copyWith(
                  color: p.$4,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoadingCompass() {
    return SizedBox(
      width: 320,
      height: 320,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC6A15B).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFFC6A15B),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Finding your location...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCompass(String? message) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? 'Location unavailable',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleBadge(QiblaState state) {
    final normalizedAngle = ((state.needleAngle % 360) + 360) % 360;
    final isAligned = normalizedAngle < 5 || normalizedAngle > 355;

    if (isAligned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppGradients.emerald,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: const Color(0xFF19312C), size: 20),
            const SizedBox(width: 10),
            Text(
              'You are facing Qibla! 🕋',
              style: AppTextStyles.titleSmall.copyWith(
                color: const Color(0xFF19312C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC6A15B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFC6A15B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_rounded, color: Color(0xFFC6A15B), size: 18),
          const SizedBox(width: 8),
          Text(
            '${state.result!.qiblaAngle.toStringAsFixed(1)}° from North',
            style: AppTextStyles.titleSmall.copyWith(
              color: const Color(0xFFC6A15B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ENHANCED INFO CARDS
  // ============================================================

  Widget _buildEnhancedInfoCards(QiblaState state) {
    final result = state.result;
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: '🕋',
            label: 'Distance to Makkah',
            value: result != null
                ? QiblaService.formatDistance(result.distanceToMakkah)
                : '--',
            color: const Color(0xFFC6A15B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: '🧭',
            label: 'Qibla Angle',
            value: result != null
                ? '${result.qiblaAngle.toStringAsFixed(1)}°'
                : '--',
            color: const Color(0xFFC6A15B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COORDINATES CARD (NEW)
  // ============================================================

  Widget _buildCoordinatesCard(QiblaState state) {
    final result = state.result!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2F6B5D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.gps_fixed_rounded,
              color: Color(0xFF2F6B5D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordinates',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  result.formattedCoordinates,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (result.altitude != null && result.altitude! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Altitude: ${result.altitude!.toStringAsFixed(0)}m',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: result.formattedCoordinates,
              ));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Coordinates copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6B5D).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: Color(0xFF2F6B5D),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS (NEW)
  // ============================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Refresh
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(qiblaProvider.notifier).refresh();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC6A15B), Color(0xFF2F6B5D)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC6A15B).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: const Color(0xFF19312C), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFF19312C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Calibrate
        Expanded(
          child: GestureDetector(
            onTap: _calibrate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFC6A15B).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.compass_calibration_rounded,
                      color: Color(0xFFC6A15B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Calibrate',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: const Color(0xFFC6A15B),
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

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                'How to Use',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInstStep('1', 'Hold your phone flat (parallel to ground)'),
          _buildInstStep('2', 'Stay away from metal objects & electronics'),
          _buildInstStep('3', 'Rotate your body until Kaaba is at the top'),
          _buildInstStep('4', 'Green glow means you are facing Qibla ✅'),
        ],
      ),
    );
  }

  Widget _buildInstStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC6A15B), Color(0xFF2F6B5D)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF19312C),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPASS FACE PAINTER (Unchanged)
// ============================================================

class _CompassFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final isMajor = i % 6 == 0;
      final isMinor = i % 2 == 0;

      final tickLength = isMajor ? 14.0 : (isMinor ? 8.0 : 4.0);
      final tickWidth = isMajor ? 2.5 : (isMinor ? 1.5 : 1.0);

      final startRadius = radius - 20;
      final endRadius = radius - 20 - tickLength;

      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      final paint = Paint()
        ..color = isMajor
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }

    final degrees = [30, 60, 120, 150, 210, 240, 300, 330];
    for (final deg in degrees) {
      final angle = deg * math.pi / 180;
      final textRadius = radius - 44;

      final textPainter = TextPainter(
        text: TextSpan(
          text: deg.toString(),
          style: TextStyle(
            color: const Color(0xFF19312C).withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          center.dx + textRadius * math.sin(angle) - textPainter.width / 2,
          center.dy - textRadius * math.cos(angle) - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_CompassFacePainter old) => false;
}

// ============================================================
// PREMIUM 3D NEEDLE PAINTER (Unchanged)
// ============================================================

class _Premium3DNeedlePainter extends CustomPainter {
  final bool isAligned;

  _Premium3DNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.height * 0.4;
    const needleWidth = 14.0;

    final topPoint = Offset(center.dx, center.dy - needleLength);
    final bottomPoint = Offset(center.dx, center.dy + needleLength * 0.35);
    final leftPoint = Offset(center.dx - needleWidth / 2, center.dy);
    final rightPoint = Offset(center.dx + needleWidth / 2, center.dy);

    final color = isAligned ? AppColors.primary : const Color(0xFFC6A15B);
    final colorLight =
        isAligned ? const Color(0xFF2F6B5D) : const Color(0xFF2F6B5D);
    final colorDark =
        isAligned ? const Color(0xFF123F36) : const Color(0xFF123F36);

    final shadowPath = Path()
      ..moveTo(topPoint.dx + 3, topPoint.dy + 5)
      ..lineTo(leftPoint.dx + 3, leftPoint.dy + 5)
      ..lineTo(bottomPoint.dx + 3, bottomPoint.dy + 5)
      ..lineTo(rightPoint.dx + 3, rightPoint.dy + 5)
      ..close();

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final leftPath = Path()
      ..moveTo(topPoint.dx, topPoint.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(bottomPoint.dx, bottomPoint.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(
      leftPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorDark, color.withValues(alpha: 0.7)],
        ).createShader(Rect.fromPoints(topPoint, bottomPoint)),
    );

    final rightPath = Path()
      ..moveTo(topPoint.dx, topPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..lineTo(bottomPoint.dx, bottomPoint.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(
      rightPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorLight, color],
        ).createShader(Rect.fromPoints(topPoint, bottomPoint)),
    );

    canvas.drawLine(
      topPoint,
      Offset(center.dx, center.dy - 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    if (isAligned) {
      final glowPath = Path()
        ..moveTo(topPoint.dx, topPoint.dy)
        ..lineTo(leftPoint.dx, leftPoint.dy)
        ..lineTo(bottomPoint.dx, bottomPoint.dy)
        ..lineTo(rightPoint.dx, rightPoint.dy)
        ..close();

      canvas.drawPath(
        glowPath,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(_Premium3DNeedlePainter old) => old.isAligned != isAligned;
}
