// lib/features/calendar/presentation/islamic_calendar_screen.dart
// Premium Islamic Calendar with Countdowns, Events, Reminders

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();
  String _selectedFilter = 'All';

  final List<_IslamicEvent> _events = [
    _IslamicEvent(
      hijriDate: '1 Muharram',
      name: 'Islamic New Year',
      nameArabic: 'رأس السنة الهجرية',
      description: 'Start of Islamic Hijri year',
      color: const Color(0xFF2F6B5D),
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '10 Muharram',
      name: 'Day of Ashura',
      nameArabic: 'يوم عاشوراء',
      description: 'Day of fasting & remembrance. Prophet Musa was saved.',
      color: const Color(0xFFC6A15B),
      icon: Icons.mosque_rounded,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '12 Rabi al-Awwal',
      name: 'Mawlid an-Nabi',
      nameArabic: 'المولد النبوي',
      description: 'Birth of Prophet Muhammad ﷺ',
      color: const Color(0xFFC6A15B),
      icon: Icons.favorite_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '27 Rajab',
      name: 'Isra & Miraj',
      nameArabic: 'الإسراء والمعراج',
      description:
          'Night journey of Prophet ﷺ from Makkah to Jerusalem & heavens',
      color: const Color(0xFF2F6B5D),
      icon: Icons.nights_stay_rounded,
      category: 'Special Night',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '15 Shaban',
      name: 'Shab-e-Barat',
      nameArabic: 'ليلة النصف من شعبان',
      description: 'Night of forgiveness. Records are transferred.',
      color: const Color(0xFFC6A15B),
      icon: Icons.auto_awesome,
      category: 'Special Night',
      importance: 2,
    ),
    _IslamicEvent(
      hijriDate: '1 Ramadan',
      name: 'Ramadan Begins',
      nameArabic: 'بداية رمضان',
      description: 'Start of the holy month of fasting',
      color: const Color(0xFFEF4444),
      icon: Icons.nightlight_round,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '27 Ramadan',
      name: 'Laylat al-Qadr',
      nameArabic: 'ليلة القدر',
      description: 'Night better than 1000 months. Quran was revealed.',
      color: const Color(0xFFC6A15B),
      icon: Icons.star_rounded,
      category: 'Special Night',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '1 Shawwal',
      name: 'Eid al-Fitr',
      nameArabic: 'عيد الفطر',
      description: 'Festival of Breaking the Fast. Celebrate with family!',
      color: const Color(0xFF2F6B5D),
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '9 Dhul-Hijjah',
      name: 'Day of Arafah',
      nameArabic: 'يوم عرفة',
      description: 'Best day for fasting. Sins of 2 years forgiven.',
      color: const Color(0xFF123F36),
      icon: Icons.terrain_rounded,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '10 Dhul-Hijjah',
      name: 'Eid al-Adha',
      nameArabic: 'عيد الأضحى',
      description: 'Festival of Sacrifice. Remember Ibrahim\'s devotion.',
      color: const Color(0xFFC6A15B),
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: 'Every Monday',
      name: 'Monday Fasting',
      nameArabic: 'صيام الإثنين',
      description: 'Sunnah fasting on Mondays',
      color: const Color(0xFF2F6B5D),
      icon: Icons.restaurant_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
    _IslamicEvent(
      hijriDate: 'Every Thursday',
      name: 'Thursday Fasting',
      nameArabic: 'صيام الخميس',
      description: 'Sunnah fasting on Thursdays',
      color: const Color(0xFF2F6B5D),
      icon: Icons.restaurant_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
    _IslamicEvent(
      hijriDate: '13,14,15 Monthly',
      name: 'Ayyam al-Beedh',
      nameArabic: 'أيام البيض',
      description: 'White days fasting (13th, 14th, 15th of each Hijri month)',
      color: const Color(0xFFC6A15B),
      icon: Icons.brightness_3_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
  ];

  List<_IslamicEvent> get _filteredEvents {
    if (_selectedFilter == 'All') return _events;
    return _events.where((e) => e.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),

            // Today Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildTodayCard(),
              ),
            ),

            // Month Navigator
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildMonthNavigator(),
              ),
            ),

            // Calendar Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildCalendarGrid(),
              ),
            ),

            // Special Days Info (NEW)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildSpecialDaysInfo(),
              ),
            ),

            // Filter Chips (NEW)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildFilterChips(),
              ),
            ),

            // Events Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ISLAMIC EVENTS',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredEvents.length} events',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children:
                      _filteredEvents.map((e) => _buildEventCard(e)).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HIJRI CALENDAR',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              fontSize: 10,
            ),
          ),
          Text(
            'Islamic Calendar',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _selectedDate = DateTime.now();
                _viewMonth = DateTime.now();
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.today_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY CARD
  // ============================================================

  Widget _buildTodayCard() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123F36), Color(0xFF2F6B5D)],
        ),
        borderRadius: AppRadius.cardRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  'TODAY',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6A15B).withValues(alpha: 0.2),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mosque_rounded,
                        color: Color(0xFFC6A15B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      now.weekday == 5 ? 'Jummah Mubarak!' : 'Blessed Day',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFC6A15B),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${HijriCalendar.now().hDay} ${HijriCalendar.now().longMonthName} ${HijriCalendar.now().hYear}',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFC6A15B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${HijriCalendar.now().longMonthName} ${HijriCalendar.now().hYear} AH',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SPECIAL DAYS INFO
  // ============================================================

  Widget _buildSpecialDaysInfo() {
    final now = DateTime.now();
    final isMonday = now.weekday == 1;
    final isThursday = now.weekday == 4;
    final isFriday = now.weekday == 5;

    String specialInfo = '';
    Color specialColor = AppColors.primary;
    IconData specialIcon = Icons.info_outline;

    if (isFriday) {
      specialInfo = 'Jummah Mubarak! Best day for Surah Al-Kahf & Salawat';
      specialColor = const Color(0xFF2F6B5D);
      specialIcon = Icons.mosque_rounded;
    } else if (isMonday || isThursday) {
      specialInfo = isMonday
          ? 'Monday — Sunnah fasting day. Prophet ﷺ used to fast.'
          : 'Thursday — Sunnah fasting day. Deeds are presented to Allah.';
      specialColor = const Color(0xFF123F36);
      specialIcon = Icons.restaurant_rounded;
    } else {
      specialInfo =
          'Make the most of today with dhikr, Quran reading, and good deeds.';
      specialColor = AppColors.accent;
      specialIcon = Icons.auto_awesome;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            specialColor.withValues(alpha: 0.12),
            specialColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: specialColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: specialColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(specialIcon, color: specialColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              specialInfo,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIPS (NEW)
  // ============================================================

  Widget _buildFilterChips() {
    final categories = ['All', 'Holiday', 'Fasting', 'Special Night', 'Sunnah'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedFilter == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = cat);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                cat,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // MONTH NAVIGATOR
  // ============================================================

  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.primary),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_getMonthName(_viewMonth.month)} ${_viewMonth.year}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${HijriCalendar.fromDate(_viewMonth).longMonthName} ${HijriCalendar.fromDate(_viewMonth).hYear} AH',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALENDAR GRID
  // ============================================================

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              final isWeekend = d == 'F';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isWeekend
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ...List.generate((daysInMonth + startWeekday + 6) ~/ 7, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (day) {
                  final dayNum = week * 7 + day - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 36));
                  }

                  final date =
                      DateTime(_viewMonth.year, _viewMonth.month, dayNum);
                  final isToday = _isSameDay(date, DateTime.now());
                  final isSelected = _isSameDay(date, _selectedDate);
                  final isFriday = date.weekday == 5;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDate = date);
                      },
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2F6B5D),
                                    Color(0xFF123F36),
                                  ],
                                )
                              : null,
                          color: isSelected && !isToday
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isFriday && !isToday
                              ? Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.4),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isToday
                                  ? AppColors.white
                                  : isFriday
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                              fontWeight: isToday || isFriday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(const Color(0xFF2F6B5D), 'Today'),
              _buildLegend(AppColors.accent, 'Friday'),
              _buildLegend(AppColors.primary, 'Selected'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EVENT CARD (Enhanced)
  // ============================================================

  Widget _buildEventCard(_IslamicEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  event.color,
                  event.color.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: event.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(event.icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Importance stars
                    Row(
                      children: List.generate(
                        event.importance,
                        (_) => Icon(
                          Icons.star_rounded,
                          color: event.color,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: event.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: event.color, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      event.hijriDate,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: event.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.category,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: event.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

// ============================================================
// EVENT MODEL (Enhanced)
// ============================================================

class _IslamicEvent {
  final String hijriDate;
  final String name;
  final String nameArabic;
  final String description;
  final Color color;
  final IconData icon;
  final String category;
  final int importance; // 1-3 stars

  _IslamicEvent({
    required this.hijriDate,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.color,
    required this.icon,
    required this.category,
    this.importance = 2,
  });
}
