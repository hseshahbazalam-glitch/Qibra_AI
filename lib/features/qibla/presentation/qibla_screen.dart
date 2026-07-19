// lib/features/qibla/presentation/qibla_screen.dart

// ============================================================
// QIBRA AI — PREMIUM 3D QIBLA COMPASS
// Beautiful 3D compass with glassmorphism & depth
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
      if (event.heading != null && mounted) {
        ref.read(qiblaProvider.notifier).updateCompassHeading(event.heading!);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qiblaState = ref.watch(qiblaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── ANIMATED BACKGROUND GRADIENT ────────────────
          _buildAnimatedBackground(),

          // ── SCROLLABLE CONTENT ──────────────────────────
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

                      const SizedBox(height: 24),

                      // 3D Compass
                      _build3DCompass(qiblaState),

                      const SizedBox(height: 32),

                      // Angle badge
                      if (qiblaState.result != null)
                        _buildAngleBadge(qiblaState),

                      const SizedBox(height: 24),

                      // Info cards
                      _buildInfoCards(qiblaState),

                      const SizedBox(height: 20),

                      // Refresh button
                      _buildRefreshButton(),

                      const SizedBox(height: 24),

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

  // ──────────────────────────────────────────────────────────
  // ANIMATED BACKGROUND
  // ──────────────────────────────────────────────────────────

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF1E1B4B).withValues(alpha: 0.4),
              const Color(0xFF0F172A).withValues(alpha: 0.6),
              AppColors.background,
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // APP BAR
  // ──────────────────────────────────────────────────────────

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القبلة',
                  style: AppTextStyles.arabicLarge.copyWith(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFA78BFA)],
                  ).createShader(bounds),
                  child: Text(
                    'Qibla Direction',
                    style: AppTextStyles.displaySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: Colors.white,
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
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Using cached location. Enable GPS for accuracy.',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // 3D COMPASS — MAIN ATTRACTION
  // ──────────────────────────────────────────────────────────

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
          // ── LAYER 1: Outer glow (when aligned) ────────
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

          // ── LAYER 2: Outer ring with gradient border ──
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
                        const Color(0xFF8B5CF6),
                        const Color(0xFF6D28D9),
                        const Color(0xFF4C1D95),
                        const Color(0xFF6D28D9),
                        const Color(0xFF8B5CF6),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isAligned ? AppColors.primary : const Color(0xFF8B5CF6))
                          .withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // ── LAYER 3: Inner black recess (depth) ───────
          Container(
            width: 292,
            height: 292,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                  Colors.black,
                ],
                stops: const [0.0, 0.7, 1.0],
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

          // ── LAYER 4: Compass face (rotates with body) ──
          Transform.rotate(
            angle: -state.compassHeading * math.pi / 180,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    const Color(0xFF334155),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _CompassFacePainter(),
              ),
            ),
          ),

          // ── LAYER 5: Shine overlay (glass effect) ─────
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

          // ── LAYER 6: Qibla needle (rotates) ───────────
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

          // ── LAYER 7: Floating Kaaba (top of needle) ───
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

          // ── LAYER 8: Center hub (3D dome) ─────────────
          _buildCenterHub(isAligned),

          // ── LAYER 9: Cardinal directions (fixed) ──────
          Transform.rotate(
            angle: -state.compassHeading * math.pi / 180,
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: _buildCardinalDirections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FLOATING KAABA
  // ──────────────────────────────────────────────────────────

  Widget _buildFloatingKaaba(bool isAligned) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F2937),
            Color(0xFF111827),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFBBF24),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? AppColors.primary : const Color(0xFFFBBF24))
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
          // Golden band
          Container(
            width: double.infinity,
            height: 8,
            margin: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFBBF24),
                  const Color(0xFFF59E0B),
                  const Color(0xFFFBBF24),
                ],
              ),
            ),
          ),
          // Kaaba emoji center
          const Text('🕋', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CENTER HUB (3D dome effect)
  // ──────────────────────────────────────────────────────────

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
                  const Color(0xFF34D399),
                  AppColors.primary,
                  const Color(0xFF047857),
                  const Color(0xFF064E3B),
                ]
              : [
                  const Color(0xFFA78BFA),
                  const Color(0xFF8B5CF6),
                  const Color(0xFF6D28D9),
                  const Color(0xFF4C1D95),
                ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? AppColors.primary : const Color(0xFF8B5CF6))
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
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CARDINAL DIRECTIONS (N, S, E, W)
  // ──────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────
  // LOADING & ERROR STATES
  // ──────────────────────────────────────────────────────────

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
                    const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
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
              child: Icon(
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

  // ──────────────────────────────────────────────────────────
  // ANGLE BADGE
  // ──────────────────────────────────────────────────────────

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
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'You are facing Qibla! 🕋',
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white,
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
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.explore_rounded,
            color: Color(0xFF8B5CF6),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${state.result!.qiblaAngle.toStringAsFixed(1)}° from North',
            style: AppTextStyles.titleSmall.copyWith(
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // INFO CARDS
  // ──────────────────────────────────────────────────────────

  Widget _buildInfoCards(QiblaState state) {
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
            color: const Color(0xFFFBBF24),
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
            color: const Color(0xFF8B5CF6),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceElevated,
          ],
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

  // ──────────────────────────────────────────────────────────
  // REFRESH BUTTON
  // ──────────────────────────────────────────────────────────

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(qiblaProvider.notifier).refresh();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Refresh Location',
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
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
// COMPASS FACE PAINTER (Tick marks, degree numbers)
// ============================================================

class _CompassFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Tick marks
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final isMajor = i % 6 == 0; // Every 30 degrees
      final isMinor = i % 2 == 0; // Every 10 degrees

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

    // Degree numbers (30, 60, 120, 150, 210, 240, 300, 330)
    final degrees = [30, 60, 120, 150, 210, 240, 300, 330];
    for (final deg in degrees) {
      final angle = deg * math.pi / 180;
      final textRadius = radius - 44;

      final textPainter = TextPainter(
        text: TextSpan(
          text: deg.toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
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
// PREMIUM 3D NEEDLE PAINTER
// ============================================================

class _Premium3DNeedlePainter extends CustomPainter {
  final bool isAligned;

  _Premium3DNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.height * 0.4;
    final needleWidth = 14.0;

    final topPoint = Offset(center.dx, center.dy - needleLength);
    final bottomPoint = Offset(center.dx, center.dy + needleLength * 0.35);
    final leftPoint = Offset(center.dx - needleWidth / 2, center.dy);
    final rightPoint = Offset(center.dx + needleWidth / 2, center.dy);

    final color = isAligned ? AppColors.primary : const Color(0xFF8B5CF6);
    final colorLight =
        isAligned ? const Color(0xFF34D399) : const Color(0xFFA78BFA);
    final colorDark =
        isAligned ? const Color(0xFF047857) : const Color(0xFF4C1D95);

    // ── Shadow behind needle ────────────────────────────
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

    // ── LEFT HALF (darker — 3D depth) ───────────────────
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
        ).createShader(
          Rect.fromPoints(topPoint, bottomPoint),
        ),
    );

    // ── RIGHT HALF (lighter — 3D highlight) ─────────────
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
        ).createShader(
          Rect.fromPoints(topPoint, bottomPoint),
        ),
    );

    // ── Highlight line down center ──────────────────────
    canvas.drawLine(
      topPoint,
      Offset(center.dx, center.dy - 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Glow when aligned ───────────────────────────────
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
