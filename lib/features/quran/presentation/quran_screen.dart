// lib/features/quran/presentation/quran_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
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

  int get _dailySurahNumber {
    final today = DateTime.now();
    final dayKey = DateTime(today.year, today.month, today.day)
        .difference(DateTime(2000, 1, 1))
        .inDays;
    return (dayKey % 114) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final surahsAsync = ref.watch(allSurahsProvider);
    final progress = ref.watch(readingProgressProvider);
    final dailyAyah = ref.watch(dailyAyahProvider);
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
          onTap: () => context.go(AppRoutes.bookmarks),
        ),
      ],
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            QibraCard(
              accentBorder: true,
              onTap: () {
                final surah = page?.surahNumber ?? 1;
                final ayah = page?.ayahNumber;
                context.push(
                  '${AppRoutes.continueReading}?surah=$surah${ayah == null ? '' : '&ayah=$ayah'}',
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: colors.primary),
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
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          page == null
                              ? 'Surah 1'
                              : 'Juz ${page.juzNumber} · Page ${page.pageNumber}',
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
            const SizedBox(height: 16),
            dailyAyah.when(
              data: (ayah) {
                if (ayah == null) return const SizedBox.shrink();
                return QibraCard(
                  accentBorder: true,
                  onTap: () {
                    context.push(
                      '${AppRoutes.dailyAyah}?surah=$_dailySurahNumber&ayah=${ayah.number}',
                    );
                  },
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
                      const SizedBox(height: 10),
                      Text(
                        ayah.text,
                        textAlign: TextAlign.right,
                        style: AppArabicStyles.quranMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (ayah.translation != null &&
                          ayah.translation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ayah.translation!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Surah $_dailySurahNumber:${ayah.number}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => QibraStatus.skeleton(height: 120),
              error: (_, __) => QibraStatus.error(
                title: 'Ayah unavailable',
                message: 'The daily ayah will appear when offline files finish loading.',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_browse == 'Juz')
              _JuzList(onOpen: _openSurah)
            else
              surahsAsync.when(
                data: (surahs) => Column(
                  children: [
                    for (final surah in surahs.take(12))
                      _SurahTile(surah: surah, onTap: () => _openSurah(surah.number)),
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
                  message: 'Try again after the offline files finish loading.',
                ),
              ),
          ],
        ),
    );
  }

  void _openSurah(int number, {int? ayah}) {
    HapticFeedback.selectionClick();
    context.push(
      '${AppRoutes.surahReader}?surah=$number${ayah == null ? '' : '&ayah=$ayah'}',
    );
  }
}

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
                style: AppTextStyles.labelLarge.copyWith(color: colors.primary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${surah.englishNameTranslation} · ${surah.numberOfAyahs} ayahs',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              surah.nameArabic,
              style: AppArabicStyles.quranSmall.copyWith(color: colors.goldText),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.onOpen});

  final void Function(int number, {int? ayah}) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < AppIslamicConstants.juzBoundaries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QibraCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                final start = AppIslamicConstants.juzBoundaries[i];
                onOpen(start[0], ayah: start[1]);
              },
              child: Row(
                children: [
                  Text(
                    'Juz ${i + 1}',
                    style: AppTextStyles.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    'Surah ${AppIslamicConstants.juzBoundaries[i][0]}:${AppIslamicConstants.juzBoundaries[i][1]}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
