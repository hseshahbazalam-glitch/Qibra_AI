// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../../duas/providers/dua_provider.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../quran/providers/quran_provider.dart' hide readingProgressProvider;
import '../../quran/providers/reading_progress_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _locationLabel(LocationState location) {
    final loc = location.location;
    if (loc == null) return 'Location not set';
    if (loc.city == 'UNKNOWN' || loc.country == 'UNKNOWN') return 'UNKNOWN';
    return loc.displayName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final name = ref.watch(userDisplayNameProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final currentPrayer = ref.watch(currentPrayerProvider);
    final location = ref.watch(locationProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final progress = ref.watch(readingProgressProvider);
    final prayerStats = ref.watch(prayerStatisticsProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final dailyAyah = ref.watch(dailyAyahProvider);
    final dailyDua = ref.watch(dailyDuaProvider);
    final hijri = HijriCalendar.now();
    final now = DateTime.now();
    final gregorian = MaterialLocalizations.of(context).formatMediumDate(now);
    final hijriLabel = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return QibraPage(
      title: 'Assalamu alaikum',
      subtitle: '${_greeting(now)}, $name',
      actions: [
        QibraIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Profile',
          onTap: () => context.go(AppRoutes.profile),
        ),
      ],
      child: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          ref.invalidate(dailyPrayerTimesProvider);
          ref.invalidate(nextPrayerProvider);
          ref.invalidate(dailyHadithProvider);
          ref.invalidate(dailyAyahProvider);
          await ref.read(readingProgressProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              '$gregorian · $hijriLabel',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _locationLabel(location),
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            if (location.isLoading)
              QibraStatus.skeleton(height: 140)
            else
              QibraHeroCard(
                onTap: () => context.go(AppRoutes.prayer),
                child: nextPrayer == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next prayer',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '—',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            location.hasLocation
                                ? 'Prayer times are unavailable right now.'
                                : 'Set your location to see prayer times.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
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
                                if (currentPrayer != null) ...[
                                  Text(
                                    'Now · ${currentPrayer.type.name}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  'Next prayer',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nextPrayer.prayer.type.name,
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  nextPrayer.prayer.type.arabicName,
                                  style: AppArabicStyles.quranSmall.copyWith(
                                    color: colors.goldText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nextPrayer.prayer.formattedTime,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: colors.textPrimary,
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
                                  color: colors.primary,
                                ),
                              ),
                              Text(
                                'remaining',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 12),
            if (dailyTimes == null)
              QibraStatus.empty(
                title: 'Prayer strip unavailable',
                message: 'Times appear after a location is set.',
              )
            else
              Row(
                children: [
                  for (final prayer in dailyTimes.prayers
                      .where((p) => p.type.isObligatory))
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _PrayerChip(
                          prayer: prayer,
                          isNext: nextPrayer?.prayer.type == prayer.type,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            QibraCard(
              onTap: () {
                final page = progress.currentPage;
                final surah = page?.surahNumber ?? 1;
                final ayah = page?.ayahNumber;
                context.push(
                  '${AppRoutes.continueReading}?surah=$surah${ayah == null ? '' : '&ayah=$ayah'}',
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
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
            if (progress.streak.currentStreak > 0 ||
                prayerStats.currentStreak > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (progress.streak.currentStreak > 0)
                    Expanded(
                      child: QibraCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Quran streak ${progress.streak.currentStreak}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (progress.streak.currentStreak > 0 &&
                      prayerStats.currentStreak > 0)
                    const SizedBox(width: 10),
                  if (prayerStats.currentStreak > 0)
                    Expanded(
                      child: QibraCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Prayer streak ${prayerStats.currentStreak}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const QibraSectionHeader(title: 'Today'),
            dailyAyah.when(
              data: (ayah) {
                if (ayah == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QibraCard(
                    accentBorder: true,
                    onTap: () => context.go(AppRoutes.quran),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayah of the day',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.goldText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ayah.text,
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppArabicStyles.quranMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: QibraStatus.skeleton(height: 88),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: QibraStatus.error(
                  title: 'Ayah unavailable',
                  message:
                      'The daily ayah will appear when offline files finish loading.',
                ),
              ),
            ),
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
                            color: colors.goldText,
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
                child: QibraStatus.skeleton(height: 88),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: QibraStatus.error(
                  title: 'Hadith unavailable',
                  message:
                      'Cached collections will appear when they finish loading.',
                ),
              ),
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
            const SizedBox(height: 16),
            QibraCard(
              onTap: () => context.go(AppRoutes.aiChat),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, color: colors.violetAi),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask Qibra',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Retrieval only — not a fatwa',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: colors.violetAi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({required this.prayer, required this.isNext});

  final PrayerTime prayer;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isNext ? colors.primarySoft : colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? colors.primary : colors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            prayer.type.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: isNext ? colors.textPrimary : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prayer.formattedTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
