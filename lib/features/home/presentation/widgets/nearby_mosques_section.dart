// lib/features/home/presentation/widgets/nearby_mosques_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class _Mosque {
  final String name;
  final String nameArabic;
  final String address;
  final String distance;
  final String nextJamaat;
  final bool isOpen;

  const _Mosque({
    required this.name,
    required this.nameArabic,
    required this.address,
    required this.distance,
    required this.nextJamaat,
    required this.isOpen,
  });
}

const List<_Mosque> _mosques = [
  _Mosque(
    name: 'Masjid Al-Noor',
    nameArabic:
        '\u0645\u064E\u0633\u0652\u062C\u0650\u062F \u0627\u0644\u0646\u064F\u0651\u0648\u0631',
    address: 'Block 5, Gulshan-e-Iqbal',
    distance: '0.3 km',
    nextJamaat: 'Asr \u00B7 3:50 PM',
    isOpen: true,
  ),
  _Mosque(
    name: 'Jamia Masjid Baitul Mukarram',
    nameArabic:
        '\u062C\u064E\u0627\u0645\u0650\u0639\u064E\u0629 \u0645\u064E\u0633\u0652\u062C\u0650\u062F',
    address: 'Karachi University Road',
    distance: '0.7 km',
    nextJamaat: 'Asr \u00B7 3:45 PM',
    isOpen: true,
  ),
  _Mosque(
    name: 'Masjid Bilal',
    nameArabic:
        '\u0645\u064E\u0633\u0652\u062C\u0650\u062F \u0628\u0650\u0644\u064E\u0627\u0644',
    address: 'North Nazimabad, Block B',
    distance: '1.2 km',
    nextJamaat: 'Asr \u00B7 3:55 PM',
    isOpen: true,
  ),
];

class HomeNearbyMosquesSection extends StatelessWidget {
  const HomeNearbyMosquesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: _mosques.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return _buildCard(_mosques[index], index);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.mosques);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'View all mosques on map',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
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

  Widget _buildCard(_Mosque mosque, int index) {
    final cardColors = [
      const Color(0xFF004D2E),
      const Color(0xFF003D26),
      const Color(0xFF1A3A2A),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadiusLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColors[index % cardColors.length],
                    AppColors.primary.withValues(alpha: 0.80),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: mosque.isOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : AppColors.error.withValues(alpha: 0.25),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        mosque.isOpen ? 'OPEN' : 'CLOSED',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: mosque.isOpen
                              ? const Color(0xFF10B981)
                              : AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    Text(
                      mosque.distance,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mosque.name,
                      style: AppTextStyles.titleSmall
                          .copyWith(fontWeight: FontWeight.w800, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mosque.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      mosque.address,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary, fontSize: 10),
                      maxLines: 1,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: AppRadius.buttonRadius,
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Next: ${mosque.nextJamaat}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
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
    );
  }
}
