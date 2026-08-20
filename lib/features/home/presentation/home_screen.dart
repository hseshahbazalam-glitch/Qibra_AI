// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME DASHBOARD (Pixel-Perfect Flagship UI)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/prayer_statistics_screen.dart';
import '../../prayer/presentation/salah_schedule_screen.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../quran/presentation/quran_search_screen.dart';
import '../../quran/presentation/surah_reader_screen.dart';
import '../../quran/providers/reading_progress_provider.dart';
import '../../tasbih/providers/tasbih_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Live ticking timer
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final locationInfo = ref.watch(locationProvider);
    final qiblaDirection = ref.watch(qiblaDirectionProvider);
    final statistics = ref.watch(prayerStatisticsProvider);
    final readingProgress = ref.watch(readingProgressProvider);
    final tasbih = ref.watch(tasbihProvider);
    final user = ref.watch(currentUserProvider);

    final userName = user?.name.isNotEmpty == true ? user!.name : 'Shahbaz';
    final cityName = locationInfo.location?.city ?? 'Bangalore';
    final countryName = locationInfo.location?.country ?? 'India';
    final fullLocation = '$cityName, $countryName';

    // Dates
    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    final gregDateStr = DateFormat('EEE, d MMM yyyy').format(now);

    // Countdown
    final countdown = nextPrayerInfo?.countdown ??
        const Duration(hours: 1, minutes: 34, seconds: 56);
    final totalSecs = countdown.inSeconds.abs();
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    final nextName = nextPrayerInfo?.prayer.type.name ?? 'Fajr';
    final nextArabic = nextPrayerInfo?.prayer.type.arabicName ?? 'الفجر';
    final nextTime = nextPrayerInfo?.prayer.formattedTime ?? '04:55 AM';

    return Scaffold(
      backgroundColor: const Color(0xFF020A08),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF0D241A),
          onRefresh: () async {
            ref.invalidate(dailyPrayerTimesProvider);
            ref.invalidate(nextPrayerProvider);
            ref.invalidate(readingProgressProvider);
            ref.invalidate(tasbihProvider);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP APP BAR
                _buildTopAppBar(context, hijriStr, gregDateStr),
                const SizedBox(height: 14),

                // 2. HERO GREETING & NEXT PRAYER BANNER
                _buildHeroBanner(
                  context,
                  userName: userName,
                  location: fullLocation,
                  hijriStr: hijriStr,
                  nextName: nextName,
                  nextArabic: nextArabic,
                  nextTime: nextTime,
                  hours: h,
                  minutes: m,
                  seconds: s,
                ),
                const SizedBox(height: 18),

                // 3. TODAY'S PRAYER TIMES HORIZONTAL BAR
                _buildPrayerTimesStrip(context, dailyTimes, nextName),
                const SizedBox(height: 18),

                // 4. QUICK ACCESS GRID (6 ITEMS)
                _buildQuickAccessSection(context),
                const SizedBox(height: 18),

                // 5. TODAY'S PROGRESS & PRAYER STREAK (TWO-COLUMN)
                _buildProgressAndStreakRow(
                  context,
                  completedPrayers: 4,
                  tasbihCount: tasbih.todayCount,
                  streakDays: statistics.currentStreak > 0
                      ? statistics.currentStreak
                      : 12,
                ),
                const SizedBox(height: 18),

                // 6. CONTINUE READING BANNER
                _buildContinueReadingBanner(context, readingProgress),
                const SizedBox(height: 18),

                // 7. DAILY VERSE & HADITH OF THE DAY (TWO CARDS)
                _buildVerseAndHadithRow(context),
                const SizedBox(height: 18),

                // 8. RAMADAN COUNTDOWN + QIBLA DIRECTION + NEARBY MOSQUES (3 CARDS)
                _buildThreeCardsRow(context, qiblaDirection),
                const SizedBox(height: 18),

                // 9. AI ISLAMIC ASSISTANT BANNER
                _buildAIAssistantBanner(context),
                const SizedBox(height: 20),

                // 10. ALL FEATURES GRID
                _buildAllFeaturesSection(context),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. TOP APP BAR
  // ============================================================
  Widget _buildTopAppBar(
      BuildContext context, String hijriStr, String gregDateStr) {
    return Row(
      children: [
        // Menu Button
        InkWell(
          onTap: () => context.go(AppRoutes.tools),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF071E16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 8),

        // Brand Logo
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QIBRA ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AI',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Islamic Companion ',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8),
                ),
                Text('✦',
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),

        // Center Date Pill
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.islamicCalendar),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF071E16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF143B2C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hijriStr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          gregDateStr,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 7.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Search Icon Button
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF071E16),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 17),
          ),
        ),
        const SizedBox(width: 6),

        // Notification Button with Dot
        InkWell(
          onTap: () => context.push('/settings/notifications'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF071E16),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 17),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Profile Kaaba Avatar
        InkWell(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: const ClipOval(
              child: Center(
                child: Text('🕋', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 2. HERO GREETING & NEXT PRAYER BANNER
  // ============================================================
  Widget _buildHeroBanner(
    BuildContext context, {
    required String userName,
    required String location,
    required String hijriStr,
    required String nextName,
    required String nextArabic,
    required String nextTime,
    required String hours,
    required String minutes,
    required String seconds,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071B14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              left: 40,
              bottom: 25,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/hero/mosque_night.png',
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xD9051812), Color(0xF2020B08)],
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Greeting Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('Assalamu Alaikum ',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                Text('👋', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Good Morning,',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1),
                            ),
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1),
                                ),
                                const SizedBox(width: 4),
                                const Text('💚',
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Text('May Allah bless your day ',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10.5)),
                                Text('🌿', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right Glassmorphic Next Prayer Card
                      InkWell(
                        onTap: () => context.go(AppRoutes.prayer),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 136,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061A13)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('NEXT PRAYER',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(nextName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(nextArabic,
                                  style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 13,
                                      fontFamily: 'Amiri')),
                              const SizedBox(height: 6),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      value: 0.72,
                                      strokeWidth: 5,
                                      backgroundColor: Color(0xFF0D2A20),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Color(0xFF00E676)),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$hours:$minutes:$seconds',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold)),
                                      const Text('Remaining',
                                          style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 7)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(nextTime,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('LIVE',
                                      style: TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 3),
                                  Text('((•))',
                                      style: TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 7)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Info Strip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A241C).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF134533)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFF00E676), size: 13),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(location,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold)),
                                const Text('Auto-detected',
                                    style: TextStyle(
                                        color: Color(0xFF64748B), fontSize: 7.5)),
                              ],
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined,
                                color: Color(0xFFFFB703), size: 13),
                            SizedBox(width: 4),
                            Text('21°C Clear',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9.5)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF00E676), size: 13),
                            const SizedBox(width: 4),
                            Text(hijriStr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 3. TODAY'S PRAYER TIMES HORIZONTAL BAR
  // ============================================================
  Widget _buildPrayerTimesStrip(
      BuildContext context, DailyPrayerTimes? dailyTimes, String nextName) {
    final prayers = [
      {
        'name': 'Fajr',
        'time': dailyTimes?.fajr.formattedTime ?? '04:55 AM',
        'icon': Icons.wb_twilight_rounded,
        'isNext': nextName == 'Fajr',
      },
      {
        'name': 'Dhuhr',
        'time': dailyTimes?.dhuhr.formattedTime ?? '12:30 PM',
        'icon': Icons.wb_sunny_rounded,
        'isNext': nextName == 'Dhuhr',
      },
      {
        'name': 'Asr',
        'time': dailyTimes?.asr.formattedTime ?? '03:46 PM',
        'icon': Icons.cloud_rounded,
        'isNext': nextName == 'Asr',
      },
      {
        'name': 'Maghrib',
        'time': dailyTimes?.maghrib.formattedTime ?? '06:49 PM',
        'icon': Icons.nights_stay_rounded,
        'isNext': nextName == 'Maghrib',
      },
      {
        'name': 'Isha',
        'time': dailyTimes?.isha.formattedTime ?? '08:00 PM',
        'icon': Icons.brightness_2_rounded,
        'isNext': nextName == 'Isha',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled,
                      color: Color(0xFF00E676), size: 14),
                  SizedBox(width: 5),
                  Text("TODAY'S PRAYER TIMES",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SalahScheduleScreen()),
                  );
                },
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios,
                        color: Color(0xFF00E676), size: 9),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: prayers.map((p) {
              final isNext = p['isNext'] as bool;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isNext
                        ? const Color(0xFF0B2E21)
                        : const Color(0xFF03100B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNext
                          ? const Color(0xFF00E676)
                          : const Color(0xFF103023),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p['icon'] as IconData,
                          color: isNext
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFFB703),
                          size: 16),
                      const SizedBox(height: 4),
                      Text(p['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(p['time'] as String,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 8.5)),
                      if (isNext) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00E676).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Upcoming',
                              style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. QUICK ACCESS GRID (6 ITEMS)
  // ============================================================
  Widget _buildQuickAccessSection(BuildContext context) {
    final items = [
      {
        'title': 'Quran',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.quran,
      },
      {
        'title': 'Hadith',
        'icon': Icons.import_contacts_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.hadith,
      },
      {
        'title': 'Qibla',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFFC084FC),
        'route': AppRoutes.qibla,
      },
      {
        'title': 'Tasbih',
        'icon': Icons.radio_button_checked,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.tasbih,
      },
      {
        'title': 'Duas',
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF38BDF8),
        'route': AppRoutes.dua,
      },
      {
        'title': 'More',
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFF94A3B8),
        'route': AppRoutes.tools,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('QUICK ACCESS',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => context.go(AppRoutes.tools),
                child: const Row(
                  children: [
                    Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios,
                        color: Color(0xFF00E676), size: 9),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              final color = item['color'] as Color;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item['route'] as String),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(item['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. TODAY'S PROGRESS & PRAYER STREAK (TWO-COLUMN)
  // ============================================================
  Widget _buildProgressAndStreakRow(
    BuildContext context, {
    required int completedPrayers,
    required int tasbihCount,
    required int streakDays,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Today's Progress Card
        Expanded(
          flex: 58,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TODAY'S PROGRESS",
                        style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrayerStatisticsScreen()),
                        );
                      },
                      child: const Text('View All',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniMetric(
                        Icons.mosque_rounded, 'Prayer', '4/5', 'On Track'),
                    _buildMiniMetric(Icons.menu_book_rounded, 'Quran', '20 min',
                        'On Track'),
                    _buildMiniMetric(Icons.radio_button_checked, 'Tasbih',
                        '66/200', 'Daily Goal'),
                    _buildMiniMetric(Icons.volunteer_activism_rounded, 'Duas',
                        '12/40', 'Daily Goal'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Prayer Streak Card
        Expanded(
          flex: 42,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('PRAYER STREAK',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$streakDays',
                        style: const TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                    const Text(' days',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
                    return Column(
                      children: [
                        Text(d,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 7.5)),
                        const SizedBox(height: 2),
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00E676), size: 10),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                const Text("Keep it up! You're on fire! 🔥",
                    style: TextStyle(color: Color(0xFFFFB703), fontSize: 7.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(
      IconData icon, String label, String value, String status) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00E676), size: 16),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold)),
        Text(status,
            style: const TextStyle(color: Color(0xFF00E676), fontSize: 7)),
      ],
    );
  }

  // ============================================================
  // 6. CONTINUE READING BANNER
  // ============================================================
  Widget _buildContinueReadingBanner(
      BuildContext context, ReadingProgressState progress) {
    final surahName = progress.currentPage?.surahName ?? 'Al-Baqarah';
    final juzNumber = progress.currentPage?.juzNumber ?? 2;
    final pageNumber = progress.currentPage?.pageNumber ?? 35;
    final surahNumber = progress.currentPage?.surahNumber ?? 2;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(
                surahNumber: surahNumber,
                initialAyah: progress.currentPage?.ayahNumber),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF061A13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF143B2C)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONTINUE READING',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(surahName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text('Juz $juzNumber • Page $pageNumber',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2E21),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF16543D)),
              ),
              child: const Row(
                children: [
                  Text('Continue',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Color(0xFF00E676), size: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 7. DAILY VERSE & HADITH OF THE DAY
  // ============================================================
  Widget _buildVerseAndHadithRow(BuildContext context) {
    return Row(
      children: [
        // Daily Verse Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🏮', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text('DAILY VERSE',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900)),
                    Spacer(),
                    Text('❝',
                        style:
                            TextStyle(color: Color(0xFFFFB703), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Indeed, with hardship [will] be ease.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quran 94:6',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => context.go(AppRoutes.quran),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Color(0xFF00E676), size: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Hadith of the Day Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('❞',
                        style:
                            TextStyle(color: Color(0xFFFFB703), fontSize: 12)),
                    SizedBox(width: 4),
                    Text('HADITH OF THE DAY',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900)),
                    Spacer(),
                    Text('🏮', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Whoever believes in Allah should speak good or remain silent.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sahih al-Bukhari 6477',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => context.go(AppRoutes.hadith),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Color(0xFF00E676), size: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 8. RAMADAN + QIBLA + MOSQUES (3 CARDS)
  // ============================================================
  Widget _buildThreeCardsRow(BuildContext context, double? qiblaDirection) {
    return Row(
      children: [
        // 1. Ramadan Countdown Card
        Expanded(
          child: InkWell(
            onTap: () => context.push('/tools/ramadan'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF061A13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF143B2C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🌙', style: TextStyle(fontSize: 10)),
                      SizedBox(width: 3),
                      Flexible(
                        child: Text('RAMADAN',
                            style: TextStyle(
                                color: Color(0xFFFFB703),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('189',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Text('days remaining',
                      style:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2E21),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('View ➔',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Qibla Direction Card
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.qibla),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF061A13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF143B2C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color(0xFF00E676), size: 10),
                      SizedBox(width: 3),
                      Flexible(
                        child: Text('QIBLA',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('🧭', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                        '${qiblaDirection?.round() ?? 293}° NW',
                        style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Nearby Mosques Card
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.mosques),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF061A13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF143B2C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mosque_rounded,
                          color: Color(0xFF00E676), size: 10),
                      SizedBox(width: 3),
                      Flexible(
                        child: Text('MOSQUES',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Find mosques near you',
                      style: TextStyle(color: Colors.white, fontSize: 8)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2E21),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('View ➔',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 9. AI ISLAMIC ASSISTANT BANNER
  // ============================================================
  Widget _buildAIAssistantBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.aiChat),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF053826), Color(0xFF021B12)]),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Color(0xFF00E676), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AI ISLAMIC ASSISTANT ',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      Text('✦',
                          style: TextStyle(
                              color: Color(0xFFFFD700), fontSize: 10)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text('Ask anything about Islam, Quran, Hadith',
                      style: TextStyle(color: Colors.white, fontSize: 10.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text('Ask Now',
                      style: TextStyle(
                          color: Color(0xFF020A08),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Text('✦',
                      style: TextStyle(
                          color: Color(0xFF020A08), fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 10. ALL FEATURES GRID
  // ============================================================
  Widget _buildAllFeaturesSection(BuildContext context) {
    final features = [
      {
        'title': 'Prayer Times',
        'subtitle': 'Accurate timings with countdown',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.prayer,
      },
      {
        'title': 'Quran',
        'subtitle': 'Read & understand the Holy Quran',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.quran,
      },
      {
        'title': 'Hadith',
        'subtitle': 'Authentic hadith collections',
        'icon': Icons.import_contacts_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.hadith,
      },
      {
        'title': 'Islamic Tools',
        'subtitle': 'Zakat, Hajj, Ramadan & more',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.tools,
      },
      {
        'title': 'Translations',
        'subtitle': '50+ languages available',
        'icon': Icons.translate_rounded,
        'color': const Color(0xFF38BDF8),
        'route': AppRoutes.quran,
      },
      {
        'title': 'Bookmarks',
        'subtitle': 'Save your favorite verses',
        'icon': Icons.bookmark_rounded,
        'color': const Color(0xFFC084FC),
        'route': AppRoutes.quran,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      color: Color(0xFF00E676), size: 14),
                  SizedBox(width: 5),
                  Text('ALL FEATURES',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.tools),
                child: const Text('View All',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final f = features[i];
              final color = f['color'] as Color;
              return InkWell(
                onTap: () => context.go(f['route'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03100B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(f['icon'] as IconData,
                            color: color, size: 14),
                      ),
                      const Spacer(),
                      Text(f['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(f['subtitle'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 7.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}