// lib/features/home/presentation/widgets/feature_grid_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/shared/widgets/cards/app_feature_illustration_card.dart';
import 'package:qibra_ai/features/tafseer/presentation/tafseer_home_screen.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';

final List<FeatureItem> homeFeatures = [
  const FeatureItem(
    title: 'Prayer Times',
    description: 'Accurate prayer times with beautiful countdown',
    icon: Icons.access_time_filled_rounded,
    theme: FeatureCardTheme.gold,
  ),
  const FeatureItem(
    title: 'Quran',
    description: 'Read and understand the Holy Quran',
    icon: Icons.menu_book_rounded,
    theme: FeatureCardTheme.emerald,
  ),
  const FeatureItem(
    title: 'Hadith',
    description: 'Authentic hadith collections with search',
    icon: Icons.collections_bookmark_rounded,
    theme: FeatureCardTheme.amber,
  ),
  const FeatureItem(
    title: 'Qibla',
    description: 'Find the direction of Qibla accurately',
    icon: Icons.explore_rounded,
    theme: FeatureCardTheme.dark,
  ),
  const FeatureItem(
    title: 'AI Assistant',
    description: 'Ask anything about Islam with AI',
    icon: Icons.auto_awesome_rounded,
    theme: FeatureCardTheme.purple,
    badge: FeatureBadgeType.newBadge,
  ),
  const FeatureItem(
    title: 'Tasbih',
    description: 'Digital tasbih with counter and dhikr',
    icon: Icons.grain_rounded,
    theme: FeatureCardTheme.emerald,
  ),
  const FeatureItem(
    title: 'Tafseer',
    description: 'Read Ibn Kathir tafseer in Urdu',
    icon: Icons.menu_book_rounded,
    theme: FeatureCardTheme.amber,
  ),
];

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFeatureIllustrationList(
      features: homeFeatures.map((feature) {
        return FeatureItem(
          title: feature.title,
          description: feature.description,
          icon: feature.icon,
          imagePath: feature.imagePath,
          theme: feature.theme,
          badge: feature.badge,
          onTap: () {
            HapticFeedback.mediumImpact();
            switch (feature.title) {
              case 'Prayer Times':
                context.go(AppRoutes.prayer);
              case 'Quran':
                context.go(AppRoutes.quran);
              case 'Hadith':
                context.go(AppRoutes.hadith);
              case 'Qibla':
                context.go(AppRoutes.qibla);
              case 'AI Assistant':
                context.go(AppRoutes.aiChat);
              case 'Tafseer':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TafseerHomeScreen()));
              case 'Tasbih':
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TasbihScreen()));
              default:
                context.go(AppRoutes.home);
            }
          },
        );
      }).toList(),
      cardSize: FeatureCardSize.standard,
    );
  }
}
