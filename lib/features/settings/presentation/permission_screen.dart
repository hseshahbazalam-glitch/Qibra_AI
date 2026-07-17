// lib/features/settings/presentation/permission_screen.dart

// ============================================================
// QIBRA AI — PERMISSION SCREEN (Phase 2)
// Version: 2.0.0
// Description: Premium permission request screen with
//              location, notifications, and storage.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// PERMISSION DATA MODEL
// ============================================================

enum _PermissionType {
  location,
  notifications,
  storage,
}

class _PermissionData {
  final _PermissionType type;
  final IconData icon;
  final String title;
  final String description;
  final String whyText;
  final List<String> features;
  final Color color;
  final Permission permission;

  const _PermissionData({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.whyText,
    required this.features,
    required this.color,
    required this.permission,
  });
}

// ============================================================
// PERMISSIONS LIST
// ============================================================

const List<_PermissionData> _permissionsList = [
  _PermissionData(
    type: _PermissionType.location,
    icon: Icons.location_on_rounded,
    title: 'Location Access',
    description: 'For accurate prayer times and Qibla direction',
    whyText: 'We use your location only to:',
    features: [
      'Calculate precise prayer times',
      'Show Qibla direction to Makkah',
      'Find nearby mosques',
    ],
    color: AppColors.primary,
    permission: Permission.location,
  ),
  _PermissionData(
    type: _PermissionType.notifications,
    icon: Icons.notifications_active_rounded,
    title: 'Notifications',
    description: 'For Adhan alerts and daily Islamic reminders',
    whyText: 'Get notified about:',
    features: [
      'Prayer time reminders',
      'Beautiful Adhan calls',
      'Daily Ayah and Hadith',
    ],
    color: AppColors.accent,
    permission: Permission.notification,
  ),
  _PermissionData(
    type: _PermissionType.storage,
    icon: Icons.folder_rounded,
    title: 'Storage Access',
    description: 'For offline Quran and audio downloads',
    whyText: 'We need storage to:',
    features: [
      'Download Quran for offline reading',
      'Save Qari recitations',
      'Store bookmarks and preferences',
    ],
    color: Color(0xFF7C3AED),
    permission: Permission.storage,
  ),
];

// ============================================================
// PERMISSION SCREEN
// ============================================================

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with TickerProviderStateMixin {
  // ── STATE ────────────────────────────────────────────
  final Map<_PermissionType, bool> _grantedPermissions = {
    _PermissionType.location: false,
    _PermissionType.notifications: false,
    _PermissionType.storage: false,
  };

  final Map<_PermissionType, bool> _isRequesting = {
    _PermissionType.location: false,
    _PermissionType.notifications: false,
    _PermissionType.storage: false,
  };

  // ── ANIMATION CONTROLLERS ────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  late AnimationController _particleController;

  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    ));

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Icon
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _entranceController.forward();
    _iconController.forward();

    // Check existing permissions
    _checkExistingPermissions();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _particleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // ── CHECK EXISTING PERMISSIONS ───────────────────────
  Future<void> _checkExistingPermissions() async {
    for (final data in _permissionsList) {
      final status = await data.permission.status;
      if (mounted) {
        setState(() {
          _grantedPermissions[data.type] = status.isGranted;
        });
      }
    }
  }

  // ── REQUEST INDIVIDUAL PERMISSION ────────────────────
  Future<void> _requestPermission(_PermissionData data) async {
    // If already granted, do nothing
    if (_grantedPermissions[data.type] == true) return;

    HapticFeedback.selectionClick();

    setState(() => _isRequesting[data.type] = true);

    try {
      final status = await data.permission.request();

      if (mounted) {
        setState(() {
          _grantedPermissions[data.type] = status.isGranted;
          _isRequesting[data.type] = false;
        });

        // Success feedback
        if (status.isGranted) {
          HapticFeedback.mediumImpact();
        } else if (status.isPermanentlyDenied) {
          _showSettingsDialog(data);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting[data.type] = false);
      }
    }
  }

  // ── REQUEST ALL PERMISSIONS ──────────────────────────
  Future<void> _requestAllPermissions() async {
    HapticFeedback.mediumImpact();

    for (final data in _permissionsList) {
      if (_grantedPermissions[data.type] != true) {
        await _requestPermission(data);
      }
    }
  }

  // ── SHOW SETTINGS DIALOG ─────────────────────────────
  void _showSettingsDialog(_PermissionData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
        ),
        title: Text(
          'Permission Required',
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          '${data.title} was denied. Please enable it from app settings.',
          style: AppTextStyles.bodyMedium.secondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTINUE ─────────────────────────────────────────
  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  // ── SKIP ─────────────────────────────────────────────
  Future<void> _handleSkip() async {
    HapticFeedback.selectionClick();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final grantedCount = _grantedPermissions.values.where((v) => v).length;
    final totalCount = _permissionsList.length;

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Background gradient ──
          _buildBackground(),

          // ── LAYER 2: Particles ──
          _buildParticles(size),

          // ── LAYER 3: Content ──
          FadeTransition(
            opacity: _entranceFade,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: AppSpacing.xl2),

                  // Icon
                  _buildIcon(),

                  const SizedBox(height: AppSpacing.xl2),

                  // Title + subtitle
                  _buildTitle(grantedCount, totalCount),

                  const SizedBox(height: AppSpacing.xl2),

                  // Permission cards
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: List.generate(
                          _permissionsList.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _buildPermissionCard(
                              _permissionsList[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildBottomButtons(grantedCount),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2E1A),
              AppColors.background,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════

  Widget _buildParticles(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _PermissionParticlePainter(
              animationValue: _particleController.value,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.background,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  AppInfo.appName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '2',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' / 3',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ICON
  // ══════════════════════════════════════════

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScale.value,
          child: child,
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.30),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.50),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => AppGradients.gold.createShader(bounds),
            child: const Icon(
              Icons.security_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TITLE
  // ══════════════════════════════════════════

  Widget _buildTitle(int granted, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Column(
        children: [
          Text(
            'APP PERMISSIONS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enable Features',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Grant permissions for the best experience',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.20),
                  AppColors.primary.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$granted of $total granted',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PERMISSION CARD
  // ══════════════════════════════════════════

  Widget _buildPermissionCard(_PermissionData data) {
    final isGranted = _grantedPermissions[data.type] ?? false;
    final isRequesting = _isRequesting[data.type] ?? false;

    return GestureDetector(
      onTap: isRequesting ? null : () => _requestPermission(data),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isGranted
                      ? [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.success.withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                ),
                borderRadius: AppRadius.cardRadiusLarge,
                border: Border.all(
                  color: isGranted
                      ? AppColors.success.withValues(alpha: 0.40)
                      : Colors.white.withValues(alpha: 0.10),
                  width: isGranted ? 1.5 : 1,
                ),
                boxShadow: isGranted
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.20),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Top row: Icon + Title + Toggle
                  Row(
                    children: [
                      // Icon container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              data.color.withValues(alpha: 0.30),
                              data.color.withValues(alpha: 0.10),
                            ],
                          ),
                          border: Border.all(
                            color: data.color.withValues(alpha: 0.50),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.color.withValues(alpha: 0.30),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            data.icon,
                            color: data.color,
                            size: 28,
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      // Title + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.description,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // Toggle switch
                      _buildToggle(
                        isGranted: isGranted,
                        isRequesting: isRequesting,
                        color: data.color,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Why text
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: data.color.withValues(alpha: 0.70),
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        data.whyText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: data.color.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Features list
                  ...data.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        bottom: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: data.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ANIMATED TOGGLE
  // ══════════════════════════════════════════

  Widget _buildToggle({
    required bool isGranted,
    required bool isRequesting,
    required Color color,
  }) {
    if (isRequesting) {
      return SizedBox(
        width: 52,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isGranted
            ? LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.80),
                ],
              )
            : null,
        color: isGranted ? null : Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: isGranted
              ? AppColors.success
              : Colors.white.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: isGranted
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.40),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: isGranted ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 4,
              ),
            ],
          ),
          child: isGranted
              ? const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM BUTTONS
  // ══════════════════════════════════════════

  Widget _buildBottomButtons(int grantedCount) {
    final allGranted = grantedCount == _permissionsList.length;

    return Column(
      children: [
        // Grant all / Continue button
        GestureDetector(
          onTap: allGranted ? _handleContinue : _requestAllPermissions,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: allGranted
                  ? LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.80),
                      ],
                    )
                  : AppGradients.gold,
              borderRadius: AppRadius.buttonRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: (allGranted ? AppColors.success : AppColors.accent)
                      .withValues(alpha: 0.50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  allGranted
                      ? Icons.check_circle_rounded
                      : Icons.security_rounded,
                  color: allGranted ? Colors.white : AppColors.background,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  allGranted ? 'Continue' : 'Grant All Permissions',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: allGranted ? Colors.white : AppColors.background,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Skip button
        GestureDetector(
          onTap: _handleSkip,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Skip for now',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PERMISSION PARTICLE PAINTER
// ============================================================

class _PermissionParticlePainter extends CustomPainter {
  final double animationValue;

  _PermissionParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(77);

    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      final particleSize = 1.5 + random.nextDouble() * 2;
      final isGold = i % 3 == 0;
      final color = isGold ? AppColors.accent : AppColors.primary;
      final alpha = 0.15 + (random.nextDouble() * 0.25);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 4,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _PermissionParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue;
}
