// lib/features/prayer/presentation/widgets/prayer_hero_card.dart
// Premium Prayer Hero Card with mountain background

import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class PrayerHeroCard extends StatelessWidget {
  final String prayerName;
  final String prayerNameArabic;
  final String countdown;
  final String? temperature;
  final String? qiblaDirection;
  final String? gregorianDate;
  final VoidCallback? onTap;

  const PrayerHeroCard({
    super.key,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.countdown,
    this.temperature,
    this.qiblaDirection,
    this.gregorianDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F4A2E),
                  Color(0xFF0A3822),
                  Color(0xFF061A10),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Mountain silhouette background
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 100),
                    painter: _MountainPainter(),
                  ),
                ),

                // Moon decoration
                Positioned(
                  top: 20,
                  right: 30,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 40,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                ),

                // Star decorations
                Positioned(
                  top: 40,
                  right: 100,
                  child: Icon(
                    Icons.star_rounded,
                    size: 8,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  ),
                ),
                Positioned(
                  top: 70,
                  left: 50,
                  child: Icon(
                    Icons.star_rounded,
                    size: 6,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NEXT PRAYER label centered
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'NEXT PRAYER',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Prayer Name (English)
                      Center(
                        child: Text(
                          prayerName,
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Prayer Name (Arabic)
                      Center(
                        child: Text(
                          prayerNameArabic,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w700,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Countdown timer BIG
                      Center(
                        child: Text(
                          countdown,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 40,
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Center(
                        child: Text(
                          'Remaining',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Info chips row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: gregorianDate ?? 'Today',
                              iconColor: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.wb_sunny_rounded,
                              label: temperature ?? '25°C',
                              iconColor: const Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.explore_rounded,
                              label: qiblaDirection ?? 'Qibla',
                              iconColor: const Color(0xFF00A86B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Mountain silhouette painter
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.3);
    path.lineTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.55, size.height * 0.6);
    path.lineTo(size.width * 0.7, size.height * 0.35);
    path.lineTo(size.width * 0.85, size.height * 0.55);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
