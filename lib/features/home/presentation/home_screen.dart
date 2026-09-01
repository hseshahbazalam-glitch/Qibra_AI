// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME (command center, midnight-navy identity)
// Priority order (understandable in < 3s):
//   1 greeting → 2 next prayer → 3 prayer context → 4 continue
//   Quran → 5 Ask QIBRA AI → 6 daily content → 7 progress →
//   8 quick actions.
// Honesty rules: no weather (no real source wired), no audio
// player (recitation not bundled), grades show their qualifiers.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../../duas/providers/dua_provider.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../quran/providers/quran_provider.dart'
    hide readingProgressProvider;
import '../../quran/providers/reading_progress_provider.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_sections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    // P0 perf (fix pass): nothing below watches the 1-second ticker —
    // that lives solely inside HomeNightHero's live countdown body.
    // Watching the selected HOUR keeps the greeting fresh (rebuilds at
    // most once an hour); the strip highlights the next prayer via a
    // select on the minute-granular provider (rebuilds only when the
    // selected prayer type actually changes).
    ref.watch(currentTimeProvider.select((a) => a.value?.hour ?? 0));
    final nextType = ref.watch(
      nextPrayerInfoProvider.select((i) => i?.prayer.type),
    );
    final location = ref.watch(locationProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final prayerSettings = ref.watch(prayerSettingsProvider);
    final progress = ref.watch(readingProgressProvider);
    final prayerStats = ref.watch(prayerStatisticsProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final dailyVerse = ref.watch(dailyVerseBundleProvider);
    final dailyDua = ref.watch(dailyDuaProvider);
    final now = DateTime.now();

    return QibraPage(
      child: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          ref.invalidate(dailyPrayerTimesProvider);
          ref.invalidate(nextPrayerProvider);
          ref.invalidate(nextPrayerInfoProvider);
          ref.invalidate(dailyHadithProvider);
          ref.invalidate(dailyVerseBundleProvider);
          await ref.read(readingProgressProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
          children: [
            // ── Compact top row (wordmark + profile) ───────────
            Row(
              children: [
                Text(
                  'QIBRA AI',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.2,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 6, top: 1),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent,
                  ),
                ),
                const Spacer(),
                QibraIconButton(
                  icon: Icons.person_outline_rounded,
                  tooltip: 'Profile',
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 1–3 · Greeting + next prayer + context ─────────
            HomeNightHero(
              name: name,
              now: now,
              locationLabel: _locationLabel(location),
              methodShortName: dailyTimes?.method.shortName,
              notificationsOn:
                  prayerSettings.enableNotifications && prayerSettings.enableAdhan,
              isLoading: location.isLoading,
              hasLocation: location.hasLocation,
              onTap: () => context.go(AppRoutes.prayer),
            ),
            const SizedBox(height: 14),

            // ── 3b · Prayer times strip ─────────────────────────
            if (dailyTimes == null && !location.isLoading)
              QibraStatus.empty(
                title: 'Prayer times unavailable',
                message: 'Times appear after a location is set.',
              )
            else if (dailyTimes != null)
              HomePrayerStrip(
                prayers: dailyTimes.prayers,
                nextType: nextType,
                onTap: () => context.go(AppRoutes.prayer),
              ),
            const SizedBox(height: 16),

            // ── 4 · Continue Quran ──────────────────────────────
            HomeContinueReading(
              page: progress.currentPage,
              overallProgress: progress.overallProgress,
              onResume: () {
                final page = progress.currentPage;
                final surah = page?.surahNumber ?? 1;
                final ayah = page?.ayahNumber;
                context.push(
                  '${AppRoutes.continueReading}?surah=$surah'
                  '${ayah == null ? '' : '&ayah=$ayah'}',
                );
              },
              onSearch: () => context.push(AppRoutes.quranSearch),
            ),
            const SizedBox(height: 14),

            // ── 5 · Ask QIBRA AI ────────────────────────────────
            HomeAskAiCard(onTap: () => context.go(AppRoutes.aiChat)),
            const SizedBox(height: 22),

            // ── 6 · Daily content ───────────────────────────────
            const QibraSectionHeader(title: 'Today'),
            dailyVerse.when(
              data: (bundle) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HomeAyahCard(
                  bundle: bundle,
                  onTap: () => context.go(AppRoutes.quran),
                ),
              ),
              loading: () => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QibraStatus.skeleton(height: 120),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QibraStatus.error(
                  title: 'Ayah unavailable',
                  message:
                      'The daily ayah will appear when offline files finish loading.',
                  onRetry: () => ref.invalidate(dailyVerseBundleProvider),
                ),
              ),
            ),
            dailyHadith.when(
              data: (hadith) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HomeHadithCard(
                  hadith: hadith,
                  onTap: () => context.go(AppRoutes.hadith),
                ),
              ),
              loading: () => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QibraStatus.skeleton(height: 140),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QibraStatus.error(
                  title: 'Hadith unavailable',
                  message: 'Cached collections will appear when they finish loading.',
                  onRetry: () => ref.invalidate(dailyHadithProvider),
                ),
              ),
            ),
            HomeDuaCard(
              dua: dailyDua,
              onTap: () => context.go(AppRoutes.dua),
            ),
            const SizedBox(height: 22),

            // ── 7 · Spiritual progress ──────────────────────────
            QibraSectionHeader(
              title: 'Your progress',
              actionLabel: 'Details',
              onAction: () => context.push(AppRoutes.prayerStatistics),
            ),
            HomeProgressPanel(
              streak: progress.streak,
              todayPagesRead: progress.todayPagesRead,
              dailyGoalPages: progress.dailyGoalPages,
              prayerStreak: prayerStats.currentStreak,
              overallProgress: progress.overallProgress,
            ),
            const SizedBox(height: 22),

            // ── 8 · Quick actions ───────────────────────────────
            QibraSectionHeader(
              title: 'Quick actions',
              actionLabel: 'More',
              onAction: () => context.go(AppRoutes.more),
            ),
            HomeQuickActions(
              actions: [
                HomeQuickAction(
                  icon: Icons.explore_outlined,
                  label: 'Qibla',
                  onTap: () => context.go(AppRoutes.qibla),
                ),
                HomeQuickAction(
                  icon: Icons.radio_button_checked,
                  label: 'Tasbih',
                  onTap: () => context.go(AppRoutes.tasbih),
                ),
                HomeQuickAction(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Duas',
                  onTap: () => context.go(AppRoutes.dua),
                ),
                HomeQuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar',
                  onTap: () => context.push(AppRoutes.islamicCalendar),
                ),
                HomeQuickAction(
                  icon: Icons.library_books_outlined,
                  label: 'Hadith',
                  onTap: () => context.go(AppRoutes.hadith),
                ),
                HomeQuickAction(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  onTap: () => context.go(AppRoutes.more),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
