// lib/features/home/presentation/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/media/safe_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

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

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
    final cityName = locationInfo.location?.city ?? 'My Location';

    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    final countdown = nextPrayerInfo?.countdown ??
        const Duration(hours: 1, minutes: 41, seconds: 9);
    final totalSecs = countdown.inSeconds.abs();
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    final nextName = nextPrayerInfo?.prayer.type.name ?? 'Dhuhr';
    final nextArabic = nextPrayerInfo?.prayer.type.arabicName ?? 'الظهر';
    final nextTime = nextPrayerInfo?.prayer.formattedTime ?? '11:57 AM';

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopAppBar(context, hijriStr),
                const SizedBox(height: 14),
                _buildHeroBanner(
                  context,
                  userName: userName,
                  cityName: cityName,
                  hijriStr: hijriStr,
                  nextName: nextName,
                  nextArabic: nextArabic,
                  nextTime: nextTime,
                  hours: h,
                  minutes: m,
                  seconds: s,
                ),
                const SizedBox(height: 18),
                _buildPrayerTimesStrip(context, dailyTimes, nextName),
                const SizedBox(height: 18),
                _buildQuickAccessSection(context),
                const SizedBox(height: 18),
                _buildProgressAndStreakRow(
                  context,
                  completedPrayers: 4,
                  tasbihCount: tasbih.todayCount > 0 ? tasbih.todayCount : 66,
                  streakDays: statistics.currentStreak > 0
                      ? statistics.currentStreak
                      : 12,
                ),
                const SizedBox(height: 18),
                _buildContinueReadingBanner(context, readingProgress),
                const SizedBox(height: 18),
                _buildVerseAndHadithRow(context),
                const SizedBox(height: 18),
                _buildThreeCardsRow(context, qiblaDirection),
                const SizedBox(height: 18),
                _buildAIAssistantBanner(context),
                const SizedBox(height: 20),
                _buildAllFeaturesSection(context),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP APP BAR
  Widget _buildTopAppBar(BuildContext context, String hijriStr) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.tools),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0C100E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2620)),
            ),
            child:
                const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('QIBRA ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
                Text('AI',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your Islamic Companion ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                Text('💛', style: TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.islamicCalendar),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0C100E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2620)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Color(0xFFFFB703), size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      hijriStr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuranSearchScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0C100E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E2620)),
            ),
            child:
                const Icon(Icons.search_rounded, color: Colors.white, size: 17),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => context.push('/settings/notifications'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0C100E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E2620)),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 17),
          ),
        ),
        const SizedBox(width: 6),
        // Real Kaaba Image Avatar
        InkWell(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
            ),
            child: ClipOval(
              child: SafeImage(
                assetPath: 'assets/images/hero/kaaba_3d.png',
                fit: BoxFit.cover,
                fallback: SafeImageFallback.mosque,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. HERO GREETING & NEXT PRAYER BANNER (Visible Mosque Background)
  Widget _buildHeroBanner(
    BuildContext context, {
    required String userName,
    required String cityName,
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
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Vibrant Mosque Background Image
            Positioned.fill(
              child: Opacity(
                opacity: 0.75,
                child: SafeImage(
                  assetPath: 'assets/images/hero/mosque_night.png',
                  fit: BoxFit.cover,
                  fallback: SafeImageFallback.mosque,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF040A07).withValues(alpha: 0.40),
                    const Color(0xFF020503).withValues(alpha: 0.85),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('Assalamu Alikum ',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                Text('👋', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Good Morning,',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1)),
                            Row(
                              children: [
                                Text(userName,
                                    style: const TextStyle(
                                        color: Color(0xFFFFB703),
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1)),
                                const SizedBox(width: 4),
                                const Text('💛',
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
                      InkWell(
                        onTap: () => context.go(AppRoutes.prayer),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 136,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0B100D).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1E2822)),
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
                                      color: Color(0xFFFFB703),
                                      fontSize: 13,
                                      fontFamily: 'Amiri')),
                              const SizedBox(height: 6),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: 0.76,
                                      strokeWidth: 5,
                                      backgroundColor: Color(0xFF161F1A),
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C120F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1C2620)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFFFB703), size: 13),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cityName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold)),
                                const Text('Auto-detected',
                                    style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 7.5)),
                              ],
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined,
                                color: Color(0xFFFFB703), size: 13),
                            SizedBox(width: 4),
                            Text('29°C Clear',
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

  // 3. TODAY'S PRAYER TIMES
  Widget _buildPrayerTimesStrip(
      BuildContext context, DailyPrayerTimes? dailyTimes, String nextName) {
    final prayers = [
      {
        'name': 'Fajr',
        'time': dailyTimes?.fajr.formattedTime ?? '04:38 AM',
        'icon': Icons.wb_twilight_rounded,
        'isNext': nextName == 'Fajr'
      },
      {
        'name': 'Dhuhr',
        'time': dailyTimes?.dhuhr.formattedTime ?? '11:57 AM',
        'icon': Icons.wb_sunny_rounded,
        'isNext': nextName == 'Dhuhr'
      },
      {
        'name': 'Asr',
        'time': dailyTimes?.asr.formattedTime ?? '03:21 PM',
        'icon': Icons.cloud_rounded,
        'isNext': nextName == 'Asr'
      },
      {
        'name': 'Maghrib',
        'time': dailyTimes?.maghrib.formattedTime ?? '06:11 PM',
        'icon': Icons.nights_stay_rounded,
        'isNext': nextName == 'Maghrib'
      },
      {
        'name': 'Isha',
        'time': dailyTimes?.isha.formattedTime ?? '07:32 PM',
        'icon': Icons.brightness_2_rounded,
        'isNext': nextName == 'Isha'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled,
                      color: Color(0xFFFFB703), size: 14),
                  SizedBox(width: 5),
                  Text("TODAY'S PRAYER TIMES",
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SalahScheduleScreen())),
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios,
                        color: Color(0xFFFFB703), size: 9),
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
                        ? const Color(0xFF0A2217)
                        : const Color(0xFF050806),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isNext
                            ? const Color(0xFF00E676)
                            : const Color(0xFF16201A)),
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
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4)),
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

  // 4. QUICK ACCESS
  Widget _buildQuickAccessSection(BuildContext context) {
    final items = [
      {
        'title': 'Quran',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.quran
      },
      {
        'title': 'Hadith',
        'icon': Icons.import_contacts_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.hadith
      },
      {
        'title': 'Qibla',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.qibla
      },
      {
        'title': 'Tasbih',
        'icon': Icons.radio_button_checked,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.tasbih
      },
      {
        'title': 'Duas',
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.dua
      },
      {
        'title': 'More',
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFFCBD5E1),
        'route': AppRoutes.tools
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: Color(0xFFFFB703), size: 14),
                  SizedBox(width: 4),
                  Text('QUICK ACCESS',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.tools),
                child: const Row(
                  children: [
                    Text('Edit',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios,
                        color: Color(0xFFFFB703), size: 9),
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

  // 5. TODAY'S PROGRESS & PRAYER STREAK
  Widget _buildProgressAndStreakRow(
    BuildContext context, {
    required int completedPrayers,
    required int tasbihCount,
    required int streakDays,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 58,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
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
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrayerStatisticsScreen())),
                      child: const Text('View All >',
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
                    _buildMiniMetric(
                        Icons.menu_book_rounded, 'Quran', '20 min', '2+ Track'),
                    _buildMiniMetric(Icons.radio_button_checked, 'Tasbih',
                        '$tasbihCount/200', 'Daily Goal'),
                    _buildMiniMetric(Icons.volunteer_activism_rounded, 'Duas',
                        '12/40', 'Daily Goal'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 42,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                    final isStar = d == 'S';
                    return Column(
                      children: [
                        Text(d,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 7.5)),
                        const SizedBox(height: 2),
                        Icon(isStar ? Icons.star_rounded : Icons.check_circle,
                            color: isStar
                                ? const Color(0xFFFFB703)
                                : const Color(0xFF00E676),
                            size: 10),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
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

  // 6. CONTINUE READING BANNER (Quran Cover Image)
  Widget _buildContinueReadingBanner(
      BuildContext context, ReadingProgressState progress) {
    final surahName = progress.currentPage?.surahName ?? 'Al-Baqarah';
    final juzNumber = progress.currentPage?.juzNumber ?? 2;
    final pageNumber = progress.currentPage?.pageNumber ?? 36;
    final surahNumber = progress.currentPage?.surahNumber ?? 2;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(
              surahNumber: surahNumber,
              initialAyah: progress.currentPage?.ayahNumber,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeImage(
                  assetPath: 'assets/images/quran_cover.png',
                  fit: BoxFit.cover,
                  fallback: SafeImageFallback.quran,
                ),
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
                color: const Color(0xFF072418),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF144D34)),
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

  // 7. DAILY VERSE & HADITH OF THE DAY
  Widget _buildVerseAndHadithRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('❝',
                        style:
                            TextStyle(color: Color(0xFFFFB703), fontSize: 13)),
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
                const Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Indeed, with hardship [will] be ease.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF080C0A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A221C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('❝',
                        style:
                            TextStyle(color: Color(0xFFFFB703), fontSize: 12)),
                    SizedBox(width: 4),
                    Text('HADITH OF THE DAY',
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
                    'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Whoever believes in Allah should speak good or remain silent.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
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

  // 8. RAMADAN + QIBLA + MOSQUES
  Widget _buildThreeCardsRow(BuildContext context, double? qiblaDirection) {
    return Row(
      children: [
        // 1. Ramadan
        Expanded(
          child: InkWell(
            onTap: () => context.push('/tools/ramadan'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF080C0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A221C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Text('🌙', style: TextStyle(fontSize: 10)),
                      SizedBox(width: 3),
                      Flexible(
                          child: Text('RAMADAN',
                              style: TextStyle(
                                  color: Color(0xFFFFB703),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('189',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Days Remaining',
                      style:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                  SizedBox(height: 6),
                  Text('View ➔',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Qibla Compass Image
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.qibla),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF080C0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A221C)),
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
                                  fontWeight: FontWeight.w900))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 1.2),
                      ),
                      child: ClipOval(
                        child: SafeImage(
                          assetPath: 'assets/images/hero/compass_qibla.png',
                          fit: BoxFit.cover,
                          fallback: SafeImageFallback.mosque,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('${qiblaDirection?.round() ?? 260}° NW',
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

        // 3. Nearby Mosques
        Expanded(
          child: InkWell(
            onTap: () => context.go(AppRoutes.mosques),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF080C0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A221C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.mosque_rounded,
                          color: Color(0xFF00E676), size: 10),
                      SizedBox(width: 3),
                      Flexible(
                          child: Text('MOSQUES',
                              style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Find mosques near you',
                      style: TextStyle(color: Colors.white, fontSize: 8)),
                  SizedBox(height: 6),
                  Text('View ➔',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 9. AI ISLAMIC ASSISTANT
  Widget _buildAIAssistantBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.aiChat),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: SafeImage(
                assetPath: 'assets/images/hero/ai_robot_3d.png',
                fit: BoxFit.contain,
                fallback: SafeImageFallback.mosque,
              ),
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
                              color: Color(0xFFFFB703), fontSize: 10)),
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
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Text('Ask Now',
                      style: TextStyle(
                          color: Color(0xFF020A08),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 2),
                  Text('✦',
                      style: TextStyle(color: Color(0xFF020A08), fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 10. ALL FEATURES 3x3 GRID
  Widget _buildAllFeaturesSection(BuildContext context) {
    final features = [
      {
        'title': 'Prayer Times',
        'subtitle': 'Accurate timings with notifications',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.prayer
      },
      {
        'title': 'Quran',
        'subtitle': 'Read, understand and reflect',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.quran
      },
      {
        'title': 'Hadith',
        'subtitle': 'Authentic hadith collections',
        'icon': Icons.import_contacts_rounded,
        'color': const Color(0xFFFFB703),
        'route': AppRoutes.hadith
      },
      {
        'title': 'Qibla Finder',
        'subtitle': 'Accurate qibla direction',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF00E676),
        'route': AppRoutes.qibla
      },
      {
        'title': 'Islamic Calendar',
        'subtitle': 'Hijri dates & important events',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFFC084FC),
        'route': AppRoutes.islamicCalendar
      },
      {
        'title': 'Bookmarks',
        'subtitle': 'Save your favorite verses & hadith',
        'icon': Icons.bookmark_rounded,
        'color': const Color(0xFFC084FC),
        'route': AppRoutes.quran
      },
      {
        'title': 'Islamic Tools',
        'subtitle': 'Zakat, Dua, Tasbih & more',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF38BDF8),
        'route': AppRoutes.tools
      },
      {
        'title': 'Translations',
        'subtitle': 'Multilanguage translations',
        'icon': Icons.translate_rounded,
        'color': const Color(0xFF38BDF8),
        'route': AppRoutes.quran
      },
      {
        'title': 'More Apps',
        'subtitle': 'Explore more Islamic apps',
        'icon': Icons.apps_rounded,
        'color': const Color(0xFFC084FC),
        'route': AppRoutes.tools
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      color: Color(0xFFFFB703), size: 14),
                  SizedBox(width: 5),
                  Text('ALL FEATURES',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.tools),
                child: const Text('View All >',
                    style: TextStyle(
                        color: Color(0xFFFFB703),
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
              childAspectRatio: 0.82,
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
                    color: const Color(0xFF040605),
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
                            borderRadius: BorderRadius.circular(6)),
                        child:
                            Icon(f['icon'] as IconData, color: color, size: 14),
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
