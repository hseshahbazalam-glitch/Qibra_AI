// lib/features/home/presentation/widgets/home_sections.dart
// ============================================================
// QIBRA AI — HOME SECTIONS
// Command-center sections with explicit visual priority:
// Continue Quran > Ask QIBRA AI > Today > Progress > Actions.
// All data is real; missing data renders honest empty states.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/qibra_colors.dart';
import '../../../../core/design_system/qibra_navy.dart';
import '../../../../shared/widgets/qibra_status.dart';
import '../../../../shared/widgets/qibra_ui.dart';
import '../../../hadith/data/models/hadith_models.dart';
import '../../../prayer/data/models/prayer_models.dart';
import '../../../quran/data/repository/reading_progress_repository.dart';
import '../../../quran/providers/quran_provider.dart' show DailyVerseBundle;
import '../../../duas/data/models/dua_model.dart';

// ─────────────────────────────────────────────────────────────
// PRAYER TIMES STRIP
// ─────────────────────────────────────────────────────────────

class HomePrayerStrip extends StatelessWidget {
  const HomePrayerStrip({
    super.key,
    required this.prayers,
    required this.nextType,
    required this.onTap,
  });

  final List<PrayerTime> prayers;
  final PrayerType? nextType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final obligatory = prayers.where((p) => p.type.isObligatory).toList();
    return Row(
      children: [
        for (var i = 0; i < obligatory.length; i++) ...[
          Expanded(
            child: _PrayerMini(
              prayer: obligatory[i],
              isNext: obligatory[i].type == nextType,
              onTap: onTap,
            ),
          ),
          if (i != obligatory.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _PrayerMini extends StatelessWidget {
  const _PrayerMini({
    required this.prayer,
    required this.isNext,
    required this.onTap,
  });

  final PrayerTime prayer;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final accent = isNext ? colors.primary : colors.textTertiary;
    return Semantics(
      button: true,
      label: isNext
          ? '${prayer.type.name} at ${prayer.formattedTime} — next prayer'
          : '${prayer.type.name} at ${prayer.formattedTime}',
      child: Material(
        color: isNext
            ? colors.primary.withValues(alpha: 0.08)
            : colors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isNext ? colors.primary.withValues(alpha: 0.65) : colors.border,
              ),
              boxShadow: isNext ? QibraNavy.nightGlow : null,
            ),
            child: Column(
              children: [
                Icon(prayer.type.icon, size: 16, color: accent),
                const SizedBox(height: 6),
                Text(
                  prayer.type.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isNext ? colors.textPrimary : colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prayer.formattedTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accent,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 13,
                  child: isNext
                      ? Text(
                          'NEXT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.primary,
                            fontSize: 8.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTINUE QURAN
// ─────────────────────────────────────────────────────────────

class HomeContinueReading extends StatelessWidget {
  const HomeContinueReading({
    super.key,
    required this.page,
    required this.overallProgress,
    required this.onResume,
    required this.onSearch,
  });

  final MushafPageModel? page;
  final double overallProgress;
  final VoidCallback onResume;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      onTap: onResume,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Medallion(
                icon: Icons.menu_book_rounded,
                tint: Color(0xFFF2D98F),
                deep: Color(0xFF0E9F6E),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page == null ? 'Start reading' : 'Continue Quran',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      page == null
                          ? 'Al-Fatiha — open the first surah'
                          : page!.surahName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      page == null
                          ? 'Every ayah with verified sources'
                          : 'Juz ${page!.juzNumber} · Page ${page!.pageNumber}'
                              ' · Ayah ${page!.ayahNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded,
                  color: colors.primary, size: 26),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: overallProgress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overallProgress >= 1.0 ? colors.accent : colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                page == null
                    ? 'Surah 1 · Juz 1'
                    : '${(overallProgress * 100).toStringAsFixed(0)}% of the Quran',
                style: AppTextStyles.labelSmall
                    .copyWith(color: colors.textTertiary),
              ),
              InkWell(
                onTap: onSearch,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 15, color: QibraNavy.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Find a surah',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: QibraNavy.blue,
                            fontWeight: FontWeight.w600),
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

// ─────────────────────────────────────────────────────────────
// ASK QIBRA AI
// ─────────────────────────────────────────────────────────────

class HomeAskAiCard extends StatelessWidget {
  const HomeAskAiCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Semantics(
      button: true,
      label: 'Ask QIBRA — answers with Quran and Hadith sources',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: QibraNavy.aiViolet,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: QibraNavy.violet.withValues(alpha: 0.35),
              ),
              boxShadow: QibraNavy.aiGlow,
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            QibraNavy.violet,
                            QibraNavy.violetDeep,
                          ],
                        ),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask QIBRA',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quran & Hadith answers with sources.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: QibraNavy.violet
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: QibraNavy.violet
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'Retrieval only — not a fatwa',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFFC7ADFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            QibraNavy.violet,
                            QibraNavy.violetDeep,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Ask',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TODAY — AYAH / HADITH / DUA
// ─────────────────────────────────────────────────────────────

class HomeAyahCard extends StatelessWidget {
  const HomeAyahCard({super.key, required this.bundle, this.onTap});

  final DailyVerseBundle? bundle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final ayah = bundle?.ayah;
    if (bundle == null || ayah == null) {
      return QibraStatus.empty(
        title: 'Daily ayah unavailable',
        message: 'Offline Quran files are still loading.',
      );
    }
    final translation = ayah.translation;
    return QibraCard(
      onTap: onTap,
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 15, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                'AYAH OF THE DAY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.goldText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                bundle!.shortReference,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ayah.text,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppArabicStyles.quranMedium
                .copyWith(color: colors.textPrimary),
          ),
          if (translation != null && translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              translation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeHadithCard extends StatelessWidget {
  const HomeHadithCard({
    super.key,
    required this.hadith,
    this.onTap,
  });

  final HadithModel? hadith;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final h = hadith;
    if (h == null) {
      return QibraStatus.empty(
        title: 'Daily hadith unavailable',
        message: 'Cached collections will appear when they finish loading.',
      );
    }
    return QibraCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 15, color: QibraNavy.blue),
              const SizedBox(width: 6),
              Text(
                'HADITH OF THE DAY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: QibraNavy.blue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (h.hasArabic) ...[
            Text(
              h.textArabic,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppArabicStyles.quranSmall
                  .copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            h.textEnglish,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium
                .copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                h.displayReference,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _GradeChip(grade: h.grade),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.grade});

  final HadithGrade grade;

  @override
  Widget build(BuildContext context) {
    // Trust UI: show the collection's stated grade with its honest
    // qualifier — never marketing copy like "100% Authentic".
    final label = grade == HadithGrade.sahih
        ? 'Grade: ${grade.label} · ${grade.description}'
        : 'Grade: ${grade.label}';
    final color = grade == HadithGrade.unknown
        ? QibraNavy.textMuted
        : QibraNavy.blue;
    return Tooltip(
      message: grade.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomeDuaCard extends StatelessWidget {
  const HomeDuaCard({super.key, required this.dua, this.onTap});

  final DuaModel dua;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_outlined,
                  size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'A DUA FOR TODAY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dua.titleEnglish,
            style: AppTextStyles.titleSmall
                .copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            dua.arabic,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppArabicStyles.quranSmall
                .copyWith(color: colors.textPrimary),
          ),
          if (dua.translationEnglish.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dua.translationEnglish,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROGRESS PANEL — real local stats only
// ─────────────────────────────────────────────────────────────

class HomeProgressPanel extends StatelessWidget {
  const HomeProgressPanel({
    super.key,
    required this.streak,
    required this.todayPagesRead,
    required this.dailyGoalPages,
    required this.prayerStreak,
    required this.overallProgress,
  });

  final ReadingStreakModel streak;
  final int todayPagesRead;
  final int dailyGoalPages;
  final int prayerStreak;
  final double overallProgress;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_outlined,
            iconColor: QibraNavy.orange,
            value: streak.currentStreak > 0 ? '${streak.currentStreak}' : '—',
            unit: streak.currentStreak == 1 ? 'day' : 'days',
            label: streak.currentStreak > 0
                ? 'Reading streak'
                : 'Read today to start a streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.auto_stories_rounded,
            iconColor: colors.primary,
            value: '$todayPagesRead/$dailyGoalPages',
            unit: 'pages today',
            label: dailyGoalProgressLabel,
            progress: dailyGoalPages == 0
                ? 0.0
                : (todayPagesRead / dailyGoalPages).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.mosque,
            iconColor: QibraNavy.gold,
            value: prayerStreak > 0 ? '$prayerStreak' : '—',
            unit: prayerStreak == 1 ? 'day' : 'days',
            label: prayerStreak > 0
                ? 'Prayer streak'
                : 'Track prayers in Prayer',
            footnote: overallProgress > 0
                ? 'Quran ${(overallProgress * 100).toStringAsFixed(0)}%'
                : null,
          ),
        ),
      ],
    );
  }

  String get dailyGoalProgressLabel {
    if (dailyGoalPages == 0) return 'Daily goal';
    return todayPagesRead >= dailyGoalPages
        ? 'Daily goal met'
        : 'Daily goal';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    this.progress,
    this.footnote,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final double? progress;
  final String? footnote;

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
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall
                .copyWith(color: colors.textTertiary),
          ),
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
          Text(
            footnote ?? label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall
                .copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────────

class HomeQuickAction {
  const HomeQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return Semantics(
          button: true,
          label: a.label,
          child: Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                a.onTap();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.icon, size: 22, color: colors.primary),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          a.label,
                          maxLines: 1,
                          softWrap: false,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED — icon medallion (replaces oversized raster thumbnails
// with a token-driven vector mark; navy-compatible by design)
// ─────────────────────────────────────────────────────────────

class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.icon,
    required this.tint,
    required this.deep,
  });

  final IconData icon;
  final Color tint;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep.withValues(alpha: 0.9), const Color(0xFF0A2536)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}
