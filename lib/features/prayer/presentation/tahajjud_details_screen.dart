// lib/features/prayer/presentation/tahajjud_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

class TahajjudDetailsScreen extends ConsumerStatefulWidget {
  const TahajjudDetailsScreen({super.key});

  @override
  ConsumerState<TahajjudDetailsScreen> createState() =>
      _TahajjudDetailsScreenState();
}

class _TahajjudDetailsScreenState extends ConsumerState<TahajjudDetailsScreen> {
  bool _alarmEnabled = false;

  String _formatClock(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  _NightWindows? _windows(DailyPrayerTimes? times) {
    final maghrib = times?.getPrayer(PrayerType.maghrib)?.adjustedTime;
    final fajr = times?.getPrayer(PrayerType.fajr)?.adjustedTime;
    if (maghrib == null || fajr == null) return null;
    var fajrAt = fajr;
    if (!fajrAt.isAfter(maghrib)) {
      fajrAt = fajrAt.add(const Duration(days: 1));
    }
    final night = fajrAt.difference(maghrib);
    if (night.inMinutes < 30) return null;
    final third = Duration(milliseconds: night.inMilliseconds ~/ 3);
    final firstEnd = maghrib.add(third);
    final lastStart = maghrib.add(Duration(milliseconds: third.inMilliseconds * 2));
    return _NightWindows(
      first: '${_formatClock(maghrib)} - ${_formatClock(firstEnd)}',
      middle: '${_formatClock(firstEnd)} - ${_formatClock(lastStart)}',
      last: '${_formatClock(lastStart)} - ${_formatClock(fajrAt)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final windows = _windows(ref.watch(dailyPrayerTimesProvider));
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: colors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colors.textPrimary,
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.prayer);
                }
              },
            ),
            centerTitle: true,
            title: Text(
              'Tahajjud Details',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // HERO CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEEF1EA),
                      Color(0xFF312E81),
                      Color(0xFFEEF1EA),
                    ],
                  ),
                  borderRadius: AppRadius.cardRadiusLarge,
                  border: Border.all(
                    color: const Color(0xFFC6A15B).withValues(alpha: 0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.nightlight_round,
                        size: 100,
                        color: const Color(0xFFC6A15B).withValues(alpha: 0.15),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahajjud',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                          ),
                        ),
                        const Text(
                          'قيام الليل',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 22,
                            color: Color(0xFFC6A15B),
                            fontWeight: FontWeight.w700,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The best time for Tahajjud is in the last third of the night.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recommended Time
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildInfoTile(
                icon: Icons.access_time_filled_rounded,
                iconColor: const Color(0xFF2F6B5D),
                title: 'Recommended Time',
                subtitle: windows?.last ?? 'Not available',
                onTap: () => _showTimeDetails(windows),
              ),
            ),
          ),

          // Alarm
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F6B5D).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: Color(0xFF2F6B5D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alarm',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Wake me for Tahajjud',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _alarmEnabled,
                      activeThumbColor: const Color(0xFF2F6B5D),
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _alarmEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recommended Surahs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildInfoTile(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFFC6A15B),
                title: 'Recommended Surahs',
                subtitle: 'Al-Mulk, Al-Insan, Al-Jinn, Al-Muzzammil',
                onTap: _showSurahsSheet,
              ),
            ),
          ),

          // Recommended Duas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildInfoTile(
                icon: Icons.volunteer_activism_rounded,
                iconColor: const Color(0xFFC6A15B),
                title: 'Recommended Duas',
                subtitle: 'Dua Qunoot, Istighfar, Any Dua',
                onTap: _showDuasSheet,
              ),
            ),
          ),

          // Streak
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildInfoTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Tahajjud Streak',
                subtitle: 'Not tracked',
                onTap: _showStreakSheet,
              ),
            ),
          ),

          // Set Alarm Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showAlarmSetDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2F6B5D),
                        Color(0xFF123F36),
                      ],
                    ),
                    borderRadius: AppRadius.cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F6B5D).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm_add_rounded,
                        color: colors.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Set Tahajjud Alarm',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET WRAPPER — Reusable
  // ============================================================

  void _openSheet(Widget content) {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 100,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TIME DETAILS
  // ============================================================

  void _showTimeDetails(_NightWindows? windows) {
    final colors = QibraColors.of(context);
    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Best Times for Tahajjud',
            style: AppTextStyles.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            windows == null
                ? 'Windows appear after Maghrib and Fajr can be calculated.'
                : 'Divided from today\'s Maghrib to Fajr.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeSection(
            'Last Third of Night',
            windows?.last ?? 'Not available',
            'Usually the preferred window',
            const Color(0xFFC6A15B),
          ),
          const SizedBox(height: 12),
          _buildTimeSection(
            'Middle of Night',
            windows?.middle ?? 'Not available',
            'Optional window',
            const Color(0xFFC6A15B),
          ),
          const SizedBox(height: 12),
          _buildTimeSection(
            'First Third',
            windows?.first ?? 'Not available',
            'Optional window',
            const Color(0xFF2F6B5D),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(
      String title, String time, String desc, Color color) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            desc,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SURAHS SHEET
  // ============================================================

  void _showSurahsSheet() {
    final colors = QibraColors.of(context);
    final surahs = [
      {
        'name': 'Al-Mulk',
        'arabic': 'الملك',
        'benefit': 'Protection from grave'
      },
      {
        'name': 'Al-Insan',
        'arabic': 'الإنسان',
        'benefit': 'Recite in Fajr on Friday'
      },
      {'name': 'Al-Jinn', 'arabic': 'الجن', 'benefit': 'About jinn creation'},
      {
        'name': 'Al-Muzzammil',
        'arabic': 'المزمل',
        'benefit': 'About night prayer'
      },
      {
        'name': 'As-Sajdah',
        'arabic': 'السجدة',
        'benefit': 'Contains prostration'
      },
      {
        'name': 'Al-Kahf',
        'arabic': 'الكهف',
        'benefit': 'Protection from Dajjal'
      },
    ];

    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recommended Surahs',
            style: AppTextStyles.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suggested surahs for Tahajjud prayer',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...surahs.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6A15B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFC6A15B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s['name']!,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              s['arabic']!,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                color: Color(0xFFC6A15B),
                                fontWeight: FontWeight.w700,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['benefit']!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // DUAS SHEET
  // ============================================================

  void _showDuasSheet() {
    final colors = QibraColors.of(context);
    final duas = [
      {
        'name': 'Dua Qunoot',
        'arabic': 'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ',
        'trans': 'O Allah, guide me among those You have guided',
      },
      {
        'name': 'Istighfar',
        'arabic': 'أَسْتَغْفِرُ اللَّهَ',
        'trans': 'I seek forgiveness from Allah',
      },
      {
        'name': 'Sayyidul Istighfar',
        'arabic': 'اللَّهُمَّ أَنْتَ رَبِّي',
        'trans': 'O Allah, You are my Lord',
      },
      {
        'name': 'Tahajjud Dua',
        'arabic': 'اللَّهُمَّ لَكَ الْحَمْدُ',
        'trans': 'O Allah, all praise is for You',
      },
    ];

    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tahajjud Duas',
            style: AppTextStyles.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...duas.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: const Color(0xFFC6A15B).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['name']!,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: const Color(0xFFC6A15B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d['arabic']!,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      color: Color(0xFFC6A15B),
                      fontWeight: FontWeight.w700,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d['trans']!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // STREAK SHEET
  // ============================================================

  void _showStreakSheet() {
    final colors = QibraColors.of(context);
    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Tahajjud Streak',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tahajjud nights are not tracked in this build. Counts will appear here only after a real record exists.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Current streak', 'Not available', colors.primary),
          _buildStatRow('Longest streak', 'Not available', const Color(0xFFC6A15B)),
          _buildStatRow('Total Tahajjud', 'Not available', colors.primary),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAlarmSetDialog() {
    final colors = QibraColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
        ),
        title: Row(
          children: [
            const Icon(
              Icons.alarm_rounded,
              color: Color(0xFF2F6B5D),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Reminder',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Text(
          'This toggle is only a reminder on this screen. No device alarm is scheduled.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6B5D),
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _NightWindows {
  const _NightWindows({
    required this.first,
    required this.middle,
    required this.last,
  });

  final String first;
  final String middle;
  final String last;
}
