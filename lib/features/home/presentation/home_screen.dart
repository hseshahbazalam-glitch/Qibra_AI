// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../../duas/providers/dua_provider.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../quran/presentation/surah_reader_screen.dart';
import '../../quran/providers/reading_progress_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final name = ref.watch(userDisplayNameProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final location = ref.watch(locationProvider);
    final progress = ref.watch(readingProgressProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final dailyDua = ref.watch(dailyDuaProvider);
    final hijri = HijriCalendar.now();
    final hijriLabel = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return QibraPage(
      child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () async {
            ref.invalidate(dailyPrayerTimesProvider);
            ref.invalidate(nextPrayerProvider);
            ref.invalidate(dailyHadithProvider);
            await ref.read(readingProgressProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamu alaikum',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_greeting(DateTime.now())}, $name',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hijriLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  QibraIconButton(
                    icon: Icons.person_outline_rounded,
                    tooltip: 'Profile',
                    onTap: () => context.go(AppRoutes.profile),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              QibraCard(
                filled: true,
                onTap: () => context.go(AppRoutes.prayer),
                child: nextPrayer == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next prayer',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '—',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            location.hasLocation
                                ? 'Prayer times are unavailable right now.'
                                : 'Set your location to see prayer times.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next prayer',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: colors.onPrimary
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nextPrayer.prayer.type.name,
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: colors.onPrimary,
                                  ),
                                ),
                                Text(
                                  nextPrayer.prayer.type.arabicName,
                                  style: AppArabicStyles.quranSmall.copyWith(
                                    color: colors.onPrimary
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nextPrayer.prayer.formattedTime,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: colors.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                nextPrayer.compactCountdown,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                              Text(
                                'remaining',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              QibraCard(
                onTap: () {
                  final page = progress.currentPage;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SurahReaderScreen(
                        surahNumber: page?.surahNumber ?? 1,
                        initialAyah: page?.ayahNumber,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: colors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progress.currentPage == null
                                ? 'Start reading'
                                : 'Continue Quran',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress.currentPage == null
                                ? 'Al-Fatihah'
                                : progress.currentPage!.surahName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            progress.currentPage == null
                                ? 'Open the first surah'
                                : 'Juz ${progress.currentPage!.juzNumber} · Page ${progress.currentPage!.pageNumber}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: colors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const QibraSectionHeader(title: 'Today'),
              dailyHadith.when(
                data: (hadith) {
                  if (hadith == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: QibraCard(
                      accentBorder: true,
                      onTap: () => context.go(AppRoutes.hadith),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hadith of the day',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hadith.hasArabic) ...[
                            const SizedBox(height: 10),
                            Text(
                              hadith.textArabic,
                              textAlign: TextAlign.right,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppArabicStyles.quranMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                          if (hadith.hasEnglish) ...[
                            const SizedBox(height: 8),
                            Text(
                              hadith.textEnglish,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            hadith.displayReference,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              QibraCard(
                onTap: () => context.go(AppRoutes.dua),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A dua for today',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dailyDua.titleEnglish,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dailyDua.arabic,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppArabicStyles.quranSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const QibraSectionHeader(title: 'Quick actions'),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.explore_outlined,
                    label: 'Qibla',
                    onTap: () => context.go(AppRoutes.qibla),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.radio_button_checked,
                    label: 'Tasbih',
                    onTap: () => context.go(AppRoutes.tasbih),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Duas',
                    onTap: () => context.go(AppRoutes.dua),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Saved',
                    onTap: () => context.go(AppRoutes.bookmarks),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Expanded(
      child: QibraCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
