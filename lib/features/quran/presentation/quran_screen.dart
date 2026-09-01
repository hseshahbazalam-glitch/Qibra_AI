// lib/features/quran/presentation/quran_screen.dart
// ============================================================
// QIBRA AI — QURAN HOME (Stage 2, midnight navy rebuild)
// Structure: Verse of the day → Continue reading → Reading
// progress & streak → Quick access (Surah/Juz/Page) → list.
// Honesty: no audio player (recitation is not bundled in this
// build — the only allowed pattern is the explicit notice),
// references show the real surah:ayah from the offline corpus.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/design_system/qibra_navy.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;
import '../providers/reading_progress_provider.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  String _browse = 'Surah';
  final TextEditingController _pageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSurah(int number, {int? ayah}) {
    HapticFeedback.selectionClick();
    context.push(
      '${AppRoutes.surahReader}?surah=$number${ayah == null ? '' : '&ayah=$ayah'}',
    );
  }

  void _openPage() {
    final raw = int.tryParse(_pageController.text.trim());
    if (raw == null || raw < 1 || raw > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a page between 1 and 604')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    context.push('${AppRoutes.mushafReader}?page=$raw');
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final surahsAsync = ref.watch(allSurahsProvider);
    final progress = ref.watch(readingProgressProvider);
    final verse = ref.watch(dailyVerseBundleProvider);
    final page = progress.currentPage;

    return QibraPage(
      title: 'Quran',
      subtitle: 'Read, continue, and browse',
      actions: [
        QibraIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          onTap: () => context.go(AppRoutes.quranSearch),
        ),
        QibraIconButton(
          icon: Icons.bookmark_border_rounded,
          tooltip: 'Bookmarks',
          onTap: () => context.push('/quran/bookmarks'),
        ),
      ],
      child: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          ref.invalidate(allSurahsProvider);
          ref.invalidate(dailyVerseBundleProvider);
          await ref.read(readingProgressProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Verse of the day (featured, honest actions) ──────
            verse.when(
              data: (bundle) => _VerseOfDayCard(bundle: bundle),
              loading: () => QibraStatus.skeleton(height: 240),
              error: (_, __) => QibraStatus.error(
                title: 'Verse of the day unavailable',
                message:
                    'It appears once the offline Quran files finish loading.',
                onRetry: () => ref.invalidate(dailyVerseBundleProvider),
              ),
            ),
            const SizedBox(height: 14),

            // ── Continue reading ─────────────────────────────────
            QibraCard(
              accentBorder: true,
              onTap: () {
                final surah = page?.surahNumber ?? 1;
                final ayah = page?.ayahNumber;
                context.push(
                  '${AppRoutes.continueReading}?surah=$surah'
                  '${ayah == null ? '' : '&ayah=$ayah'}',
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.menu_book_rounded,
                            color: colors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page == null ? 'Begin reading' : 'Continue reading',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              page?.surahName ?? 'Al-Fatihah',
                              style: AppTextStyles.titleMedium.copyWith(
                                  color: colors.textPrimary),
                            ),
                            Text(
                              page == null
                                  ? 'Surah 1'
                                  : 'Juz ${page.juzNumber} · Page ${page.pageNumber}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: colors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.overallProgress,
                      minHeight: 6,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress.overallProgress >= 1.0
                            ? colors.accent
                            : colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress.overallProgress * 100).toStringAsFixed(0)}% read · '
                    '${progress.totalPagesRead} pages total',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Progress & streak ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: QibraNavy.orange,
                    value: progress.streak.currentStreak > 0
                        ? '${progress.streak.currentStreak}'
                        : '0',
                    label: progress.streak.currentStreak == 1
                        ? 'day streak'
                        : 'day streak',
                    hint: progress.hasReadToday
                        ? 'Done today'
                        : 'Read today to keep it alive',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.auto_stories_rounded,
                    iconColor: colors.primary,
                    value:
                        '${progress.todayPagesRead}/${progress.dailyGoalPages}',
                    label: 'pages today',
                    hint: progress.todayPagesRead >= progress.dailyGoalPages
                        ? 'Daily goal met'
                        : 'Daily goal',
                    progress: progress.dailyGoalPages == 0
                        ? 0
                        : (progress.todayPagesRead / progress.dailyGoalPages)
                            .clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.workspace_premium_outlined,
                    iconColor: colors.accent,
                    value: '${progress.streak.longestStreak}',
                    label: 'longest streak',
                    hint: '${progress.streak.totalDaysRead} days read',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Quick access ─────────────────────────────────────
            const QibraSectionHeader(title: 'Browse'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QibraChip(
                    label: 'Surah',
                    selected: _browse == 'Surah',
                    onTap: () => setState(() => _browse = 'Surah'),
                  ),
                  QibraChip(
                    label: 'Juz',
                    selected: _browse == 'Juz',
                    onTap: () => setState(() => _browse = 'Juz'),
                  ),
                  QibraChip(
                    label: 'Page',
                    selected: _browse == 'Page',
                    onTap: () => setState(() => _browse = 'Page'),
                  ),
                  QibraChip(
                    label: 'All surahs',
                    selected: false,
                    onTap: () => context.go('/quran/surahs'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_browse == 'Juz')
              _JuzList(onOpen: (int n, int? ayah) => _openSurah(n, ayah: ayah))
            else if (_browse == 'Page')
              QibraCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: colors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Mushaf page 1–604',
                          prefixIcon: Icon(Icons.local_library_outlined),
                        ),
                        onSubmitted: (_) => _openPage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _openPage,
                      child: const Text('Open'),
                    ),
                  ],
                ),
              )
            else
              surahsAsync.when(
                data: (surahs) => Column(
                  children: [
                    for (final surah in surahs.take(12))
                      _SurahTile(
                        surah: surah,
                        onTap: () => _openSurah(surah.number),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go('/quran/surahs'),
                      child: const Text('View all surahs'),
                    ),
                  ],
                ),
                loading: () => QibraStatus.skeleton(height: 220),
                error: (_, __) => QibraStatus.error(
                  title: 'Quran data unavailable',
                  message:
                      'Try again after the offline files finish loading.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Verse of the day — featured card with honest action row
// ─────────────────────────────────────────────────────────────

class _VerseOfDayCard extends ConsumerWidget {
  const _VerseOfDayCard({required this.bundle});

  final DailyVerseBundle? bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final data = bundle;
    if (data == null) {
      return QibraStatus.empty(
        title: 'Daily verse unavailable',
        message: 'Offline Quran files are still loading.',
      );
    }
    final ayah = data.ayah;
    final bookmarked = ref.watch(isBookmarkedProvider(
      (surah: data.surah.number, ayah: ayah.number),
    ));

    return QibraCard(
      accentBorder: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'AYAH OF THE DAY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                data.shortReference,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ayah.text,
            textAlign: TextAlign.right,
            style:
                AppArabicStyles.quranMedium.copyWith(color: colors.textPrimary),
          ),
          if (ayah.translation != null && ayah.translation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ayah.translation!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: colors.border.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _VerseAction(
                icon: Icons.menu_book_rounded,
                label: 'Read',
                onTap: () {
                  context.push(
                    '${AppRoutes.surahReader}?surah=${data.surah.number}'
                    '&ayah=${ayah.number}',
                  );
                },
              ),
              _VerseAction(
                icon: bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: bookmarked ? 'Saved' : 'Bookmark',
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(bookmarksProvider.notifier)
                      .toggleBookmark(BookmarkModel(
                        surahNumber: data.surah.number,
                        ayahNumber: ayah.number,
                        surahName: data.surah.name,
                        ayahText: ayah.text,
                        bookmarkedAt: DateTime.now(),
                      ));
                },
              ),
              _VerseAction(
                icon: Icons.ios_share_rounded,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text: '${ayah.text}\n\n'
                        '${ayah.translation ?? ''}\n\n— ${data.reference}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verse copied with source')),
                  );
                },
              ),
              // Honesty: recitation audio is NOT bundled → no fake player.
              Tooltip(
                message:
                    'Audio recitation files are not part of this build.',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_off_outlined,
                          size: 14, color: colors.textTertiary),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.of(context).recitationNotBundled,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: colors.textTertiary),
                      ),
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
}

class _VerseAction extends StatelessWidget {
  const _VerseAction({
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
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mini stats
// ─────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.hint,
    this.progress,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String hint;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.labelSmall.copyWith(color: colors.textTertiary)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.labelSmall.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lists (behavior preserved from previous release)
// ─────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final SurahInfoModel surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QibraCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${surah.number}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: colors.primary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    '${surah.englishNameTranslation} · ${surah.numberOfAyahs} ayahs',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              surah.nameArabic,
              style: AppArabicStyles.quranSmall
                  .copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.onOpen});

  final void Function(int number, int? ayah) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        for (var i = 0; i < AppIslamicConstants.juzBoundaries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QibraCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                final start = AppIslamicConstants.juzBoundaries[i];
                onOpen(start[0], start[1]);
              },
              child: Row(
                children: [
                  Icon(Icons.bookmark_added_outlined,
                      size: 16, color: colors.accent),
                  const SizedBox(width: 10),
                  Text(
                    'Juz ${i + 1}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: colors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    'Surah ${AppIslamicConstants.juzBoundaries[i][0]}:'
                    '${AppIslamicConstants.juzBoundaries[i][1]}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
