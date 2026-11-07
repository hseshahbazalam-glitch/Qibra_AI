// lib/features/calendar/presentation/islamic_calendar_screen.dart
// Premium Islamic Calendar with Countdowns, Events, Reminders

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();
  String _selectedFilter = 'All';

  // A2: the event list is BUILT with the active AppStrings — no
  // hardcoded English copy survives in the data; hijri-date lines compose
  // day + localized month word. Category keys stay English (they are
  // filter identities), labels come from _categoryLabel at render.
  List<_IslamicEvent> _eventsFor(AppStrings s) => [
    _IslamicEvent(
      hijriDate: '1 ${s.hijriMonthName(1, 'Muharram')}',
      name: s.calNewYearName,
      nameArabic: 'رأس السنة الهجرية',
      description: s.calNewYearDesc,
      color: QibraColors.light.primarySoft,
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '10 ${s.hijriMonthName(1, 'Muharram')}',
      name: s.calAshuraName,
      nameArabic: 'يوم عاشوراء',
      description: s.calAshuraDesc,
      color: QibraColors.light.accent,
      icon: Icons.mosque_rounded,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '12 ${s.hijriMonthName(3, 'Rabi al-Awwal')}',
      name: s.calMawlidName,
      nameArabic: 'المولد النبوي',
      description: s.calMawlidDesc,
      color: QibraColors.light.accent,
      icon: Icons.favorite_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '27 ${s.hijriMonthName(7, 'Rajab')}',
      name: s.calIsraName,
      nameArabic: 'الإسراء والمعراج',
      description: s.calIsraDesc,
      color: QibraColors.light.primarySoft,
      icon: Icons.nights_stay_rounded,
      category: 'Special Night',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '15 ${s.hijriMonthName(8, 'Shaban')}',
      name: s.calBaratName,
      nameArabic: 'ليلة النصف من شعبان',
      description: s.calBaratDesc,
      color: QibraColors.light.accent,
      icon: Icons.auto_awesome,
      category: 'Special Night',
      importance: 2,
    ),
    _IslamicEvent(
      hijriDate: '1 ${s.hijriMonthName(9, 'Ramadan')}',
      name: s.calRamadanName,
      nameArabic: 'بداية رمضان',
      description: s.calRamadanDesc,
      color: QibraColors.light.error,
      icon: Icons.nightlight_round,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '27 ${s.hijriMonthName(9, 'Ramadan')}',
      name: s.calQadrName,
      nameArabic: 'ليلة القدر',
      description: s.calQadrDesc,
      color: QibraColors.light.accent,
      icon: Icons.star_rounded,
      category: 'Special Night',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '1 ${s.hijriMonthName(10, 'Shawwal')}',
      name: s.calEidFitrName,
      nameArabic: 'عيد الفطر',
      description: s.calEidFitrDesc,
      color: QibraColors.light.primarySoft,
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '9 ${s.hijriMonthName(12, 'Dhul-Hijjah')}',
      name: s.calArafahName,
      nameArabic: 'يوم عرفة',
      description: s.calArafahDesc,
      color: QibraColors.light.primary,
      icon: Icons.terrain_rounded,
      category: 'Fasting',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: '10 ${s.hijriMonthName(12, 'Dhul-Hijjah')}',
      name: s.calEidAdhaName,
      nameArabic: 'عيد الأضحى',
      description: s.calEidAdhaDesc,
      color: QibraColors.light.accent,
      icon: Icons.celebration_rounded,
      category: 'Holiday',
      importance: 3,
    ),
    _IslamicEvent(
      hijriDate: s.everyWeekday(s.dayName(1)),
      name: s.calMondayFastingName,
      nameArabic: 'صيام الإثنين',
      description: s.calMondayFastingDesc,
      color: QibraColors.light.primarySoft,
      icon: Icons.restaurant_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
    _IslamicEvent(
      hijriDate: s.everyWeekday(s.dayName(4)),
      name: s.calThursdayFastingName,
      nameArabic: 'صيام الخميس',
      description: s.calThursdayFastingDesc,
      color: QibraColors.light.primarySoft,
      icon: Icons.restaurant_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
    _IslamicEvent(
      hijriDate: s.whiteDaysDateLabel,
      name: s.calAyyamName,
      nameArabic: 'أيام البيض',
      description: s.calAyyamDesc,
      color: QibraColors.light.accent,
      icon: Icons.brightness_3_rounded,
      category: 'Sunnah',
      importance: 1,
    ),
  ];

  String _categoryLabel(AppStrings s, String category) =>
      switch (category) {
        'All' => s.scopeAll,
        'Holiday' => s.catHoliday,
        'Fasting' => s.catFasting,
        'Special Night' => s.catSpecialNight,
        _ => s.catSunnah,
      };

  List<_IslamicEvent> _filteredEvents(AppStrings s) {
    final events = _eventsFor(s);
    if (_selectedFilter == 'All') return events;
    return events.where((e) => e.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: colors.background,
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
                        color: colors.accent,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.islamicEventsEyebrow,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.eventsCount(_filteredEvents(s).length),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
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
                      _filteredEvents(s)
                          .map(_buildEventCard)
                          .toList(),
                ),
              ),
            ),

            // Ramadan — sunan & etiquettes. Merged from the retired
            // standalone RamadanTimerScreen (LEAN PASS): its countdown
            // read hardcoded 2025 dates + fixed times (never live), so
            // only the durable content moved here. Suhoor/iftar duas are
            // already in the Duas feature (Fast & Food category).
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RamadanSunanCard(),
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
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: colors.background,
      elevation: 0,
      leading: IconButton(
        tooltip: AppStrings.of(context).tooltipBack,
        icon: Container(
          width: 48,
          height: 48,
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
            context.go(AppRoutes.home);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.hijriCalendarEyebrow,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              fontSize: 10,
            ),
          ),
          Text(
            s.islamicCalendarTitle,
            style: AppTextStyles.titleLarge.copyWith(
              color: colors.textPrimary,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.today_rounded,
                color: colors.textPrimary,
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
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    final hNow = HijriCalendar.now();
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.cardRadiusLarge,
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
                  color: colors.card.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  s.todayPill,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.card,
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
                  color: colors.accent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mosque_rounded,
                        color: colors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      now.weekday == 5 ? s.jummahMubarak : s.blessedDay,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.accent,
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
            '${hNow.hDay} '
            '${s.hijriMonthName(hNow.hMonth, hNow.longMonthName)} '
            '${hNow.hYear}',
            style: AppTextStyles.displayLarge.copyWith(
              color: colors.card,
              fontWeight: FontWeight.w900,
              fontSize: 36,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.dayName(now.weekday)}, ${now.day} '
            '${s.monthName(now.month)} ${now.year}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.card.withValues(alpha: 0.85),
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
                Icon(Icons.info_outline_rounded,
                    color: colors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.hijriMonthName(hNow.hMonth, hNow.longMonthName)} '
                    '${hNow.hYear} AH',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.card.withValues(alpha: 0.9),
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
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    final now = DateTime.now();
    final isMonday = now.weekday == 1;
    final isThursday = now.weekday == 4;
    final isFriday = now.weekday == 5;

    String specialInfo = '';
    Color specialColor = colors.primary;
    IconData specialIcon = Icons.info_outline;

    if (isFriday) {
      specialInfo = s.jummahDayInfo;
      specialColor = colors.primarySoft;
      specialIcon = Icons.mosque_rounded;
    } else if (isMonday || isThursday) {
      specialInfo = isMonday ? s.mondayFastInfo : s.thursdayFastInfo;
      specialColor = colors.primary;
      specialIcon = Icons.restaurant_rounded;
    } else {
      specialInfo = s.makeMostOfDayInfo;
      specialColor = colors.accent;
      specialIcon = Icons.auto_awesome;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: specialColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: specialColor.withValues(alpha: 0.16)),
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
                color: colors.textPrimary,
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
    final colors = QibraColors.of(context);
    final categories = ['All', 'Holiday', 'Fasting', 'Special Night', 'Sunnah'];
    final s = AppStrings.of(context);

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
            child: Semantics(
              // Pass A: the chip's selected state is color-only otherwise.
              button: true,
              selected: isSelected,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : colors.border,
                ),
              ),
              child: Text(
                _categoryLabel(s, cat),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? colors.onPrimary : colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
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
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    final vHijri = HijriCalendar.fromDate(_viewMonth);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.of(context).tooltipPrevMonth,
            icon: Icon(Icons.chevron_left_rounded,
                color: colors.primary),
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
                  '${s.monthName(_viewMonth.month)} '
                  '${_viewMonth.year}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${s.hijriMonthName(vHijri.hMonth, vHijri.longMonthName)} '
                  '${vHijri.hYear} AH',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.of(context).tooltipNextMonth,
            icon: Icon(Icons.chevron_right_rounded,
                color: colors.primary),
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
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border),
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
                          ? colors.accent
                          : colors.textSecondary,
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
                      child: Semantics(
                        // Pass A: day selection/today are color-only
                        // otherwise; selected is a real a11y state.
                        button: true,
                        selected: isSelected,
                        child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? colors.primary
                              : isSelected
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isFriday && !isToday
                              ? Border.all(
                                  color:
                                      colors.accent.withValues(alpha: 0.24),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isToday
                                  ? colors.onPrimary
                                  : isFriday
                                      ? colors.accent
                                      : colors.textPrimary,
                              fontWeight: isToday || isFriday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
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
              _buildLegend(colors.primarySoft, 'Today'),
              _buildLegend(colors.accent, s.dayName(5)),
              _buildLegend(colors.primary, s.selectedLegendLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    final colors = QibraColors.of(context);
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
            color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: event.color,
              shape: BoxShape.circle,
            ),
            child: Icon(event.icon, color: colors.card, size: 24),
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
                          color: colors.textPrimary,
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
                  // In ar the card's name IS the Arabic word — the twin
                  // line blanks to avoid printing it twice.
                  AppStrings.of(context).languageCode == 'ar'
                      ? ''
                      : event.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: AppArabicStyles.quranSmall.copyWith(
                    color: event.color,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
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
                        _categoryLabel(
                            AppStrings.of(context), event.category),
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

class _RamadanTip {
  const _RamadanTip(this.icon, this.title, this.note);

  final IconData icon;
  final String title;
  final String note;
}

class _RamadanSunanCard extends StatelessWidget {
  const _RamadanSunanCard();

  // A2: tips render through AppStrings (was a const English list).
  static List<_RamadanTip> _tipsFor(AppStrings s) => [
    _RamadanTip(
        Icons.nightlight_round, s.tipTaraweehTitle, s.tipTaraweehNote),
    _RamadanTip(
        Icons.menu_book_rounded, s.tipReadQuranTitle, s.tipReadQuranNote),
    _RamadanTip(Icons.favorite_rounded, s.tipCharityTitle, s.tipCharityNote),
    _RamadanTip(Icons.self_improvement_rounded, s.tipDuaTitle, s.tipDuaNote),
    _RamadanTip(Icons.mosque_rounded, s.tipItikafTitle, s.tipItikafNote),
    _RamadanTip(Icons.wb_twilight, s.tipSuhoorTitle, s.tipSuhoorNote),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.of(context).ramadanSunanTitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in _tipsFor(AppStrings.of(context)))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.icon, size: 16, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      t.note,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            AppStrings.of(context).suhoorIftarDuasNote,
            style: AppTextStyles.labelXSmall.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
