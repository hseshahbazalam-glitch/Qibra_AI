// lib/features/prayer/presentation/prayer_times_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';
import 'salah_schedule_screen.dart';
import 'tahajjud_details_screen.dart';
import 'prayer_statistics_screen.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _timer;
  bool _isDuaFavorite = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final locationInfo = ref.watch(locationProvider);
    final qiblaDirection = ref.watch(qiblaDirectionProvider);
    final statistics = ref.watch(prayerStatisticsProvider);

    final cityName = locationInfo.location?.city ?? 'Bangalore';
    final countryName = locationInfo.location?.country ?? 'India';
    final fullLocation = '$cityName, $countryName';

    final countdown = nextPrayerInfo?.countdown ??
        const Duration(hours: 3, minutes: 58, seconds: 59);
    final totalSecs = countdown.inSeconds.abs();
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');

    final nextName = nextPrayerInfo?.prayer.type.name ?? 'Fajr';
    final nextArabic = nextPrayerInfo?.prayer.type.arabicName ?? 'الفجر';

    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy').format(now);
    final dayStr = DateFormat('EEEE').format(now);

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
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopGreetingBar(context),
                const SizedBox(height: 16),
                _buildHeroCard(
                  location: fullLocation,
                  prayerName: nextName,
                  prayerArabic: nextArabic,
                  hours: h,
                  minutes: m,
                  seconds: s,
                  date: '$dateStr\n$dayStr',
                  temperature: '25°C\nClear Sky',
                  qibla: 'Qibla ${qiblaDirection?.round() ?? 287}°\nNW',
                  progressPercent: 72,
                ),
                const SizedBox(height: 20),
                _buildQuickActionsRow(context),
                const SizedBox(height: 20),
                _buildCoreDashboard(dailyTimes, nextPrayerInfo, statistics),
                const SizedBox(height: 16),
                _buildSunAndMosqueRow(dailyTimes),
                const SizedBox(height: 16),
                _buildTodayDuaBanner(),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGreetingBar(BuildContext context) {
    return Row(
      children: [
        const Text('👋', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalamu Alaikum',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Row(
                children: [
                  Text('May Allah bless your day',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  SizedBox(width: 4),
                  Text('💚', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        _buildHeaderIconButton(
            icon: Icons.calendar_month_rounded,
            onTap: () => context.go(AppRoutes.islamicCalendar)),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
            icon: Icons.location_on_outlined,
            onTap: () => context.go(AppRoutes.qibla)),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => context.push('/settings/notifications')),
      ],
    );
  }

  Widget _buildHeaderIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1E18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF163E30)),
        ),
        child: Icon(icon, color: const Color(0xFF00E676), size: 20),
      ),
    );
  }

  Widget _buildHeroCard({
    required String location,
    required String prayerName,
    required String prayerArabic,
    required String hours,
    required String minutes,
    required String seconds,
    required String date,
    required String temperature,
    required String qibla,
    required int progressPercent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071B14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -10,
              bottom: 45,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/hero/mosque_night.png',
                  height: 180,
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
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF00E676), size: 16),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const Text('Auto-detected',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00E676).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Text('LIVE ((•))',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      const Text('🌙', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('⦿ NEXT PRAYER',
                                style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(height: 6),
                          Text(prayerName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0)),
                          Text(prayerArabic,
                              style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 18,
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('Starts in',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('$hours : $minutes : $seconds',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          const Text('Hrs        Mins       Secs',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 105,
                            height: 105,
                            child: CircularProgressIndicator(
                              value: progressPercent / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFF0D2A20),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E676)),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$progressPercent%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              Text('of time until\n$prayerName',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A241C).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF134533)),
                    ),
                    child: Row(
                      children: [
                        _buildChip(Icons.calendar_month_outlined, date,
                            const Color(0xFF00E676)),
                        _buildDivider(),
                        _buildChip(Icons.wb_sunny_outlined, temperature,
                            const Color(0xFFFFB703)),
                        _buildDivider(),
                        _buildChip(Icons.explore_outlined, qibla,
                            const Color(0xFF00E676)),
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

  Widget _buildChip(IconData icon, String text, Color iconColor) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFF1A523E));

  Widget _buildQuickActionsRow(BuildContext context) {
    final actions = [
      {
        'icon': Icons.explore_rounded,
        'label': 'Qibla',
        'route': AppRoutes.qibla
      },
      {
        'icon': Icons.notifications_active_rounded,
        'label': 'Adhan\nSettings',
        'route': '/settings/notifications'
      },
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Calendar\nMonthly',
        'route': AppRoutes.islamicCalendar
      },
      {
        'icon': Icons.nightlight_round,
        'label': 'Tahajjud',
        'route': 'tahajjud_modal'
      },
      {
        'icon': Icons.volunteer_activism_rounded,
        'label': 'Duas',
        'route': AppRoutes.dua
      },
      {
        'icon': Icons.more_horiz_rounded,
        'label': 'More',
        'route': 'more_modal'
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((item) {
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (item['route'] == 'tahajjud_modal') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TahajjudDetailsScreen()));
            } else if (item['route'] == 'more_modal') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SalahScheduleScreen()));
            } else {
              context.push(item['route'] as String);
            }
          },
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF092219),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF164736)),
                ),
                child: Icon(item['icon'] as IconData,
                    color: const Color(0xFF00E676), size: 22),
              ),
              const SizedBox(height: 6),
              Text(item['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoreDashboard(DailyPrayerTimes? dailyTimes,
      NextPrayerInfo? nextPrayerInfo, PrayerStatistics stats) {
    final nextType = nextPrayerInfo?.prayer.type ?? PrayerType.fajr;

    final prayers = [
      {
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': dailyTimes?.fajr.formattedTime ?? '04:56 AM',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFF00E676),
        'isNext': nextType == PrayerType.fajr
      },
      {
        'name': 'Sunrise',
        'arabic': 'الشروق',
        'time': dailyTimes?.sunrise.formattedTime ?? '06:11 AM',
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFFB703),
        'isNext': false
      },
      {
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': dailyTimes?.dhuhr.formattedTime ?? '12:30 PM',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFFFB703),
        'isNext': nextType == PrayerType.dhuhr
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': dailyTimes?.asr.formattedTime ?? '03:45 PM',
        'icon': Icons.cloud_rounded,
        'color': const Color(0xFFEF4444),
        'isNext': nextType == PrayerType.asr
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': dailyTimes?.maghrib.formattedTime ?? '06:48 PM',
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFFA855F7),
        'isNext': nextType == PrayerType.maghrib
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': dailyTimes?.isha.formattedTime ?? '07:59 PM',
        'icon': Icons.brightness_2_rounded,
        'color': const Color(0xFF38BDF8),
        'isNext': nextType == PrayerType.isha
      },
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 54,
          child: Container(
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
                    const Text("TODAY'S PRAYER TIMES",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800)),
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SalahScheduleScreen())),
                      child: const Text('View All',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...prayers.map((p) => _buildPrayerRowTile(p)),
                const SizedBox(height: 6),
                const Text('Juristic Method: Hanafi ⓘ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 46,
          child: Column(
            children: [
              _buildTahajjudCard(context),
              const SizedBox(height: 10),
              _buildStreakCard(stats.currentStreak),
              const SizedBox(height: 10),
              _buildProgressCard(context, 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerRowTile(Map<String, dynamic> p) {
    final isNext = p['isNext'] as bool;
    final color = p['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF0B2E21) : const Color(0xFF03100B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isNext ? const Color(0xFF00E676) : const Color(0xFF103023)),
      ),
      child: Row(
        children: [
          Icon(p['icon'] as IconData, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p['name'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    if (isNext) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFF00E676).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('NEXT',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 7,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(p['arabic'] as String,
                    style: TextStyle(
                        color: isNext
                            ? const Color(0xFF00E676)
                            : const Color(0xFF64748B),
                        fontSize: 9,
                        fontFamily: 'Amiri')),
              ],
            ),
          ),
          Text(p['time'] as String,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTahajjudCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const TahajjudDetailsScreen())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF261947), Color(0xFF120C26)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4C3082)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🟣 TAHAJJUD COUNTDOWN',
                style: TextStyle(
                    color: Color(0xFFC084FC),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tahajjud',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('قيام الليل',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 11,
                            fontFamily: 'Amiri')),
                  ],
                ),
                Text('🌙', style: TextStyle(fontSize: 22)),
              ],
            ),
            SizedBox(height: 6),
            Text('Starts in',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
            Text('02:15:30',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
            Text('Best time: Last third\nof the night',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔥 PRAYER STREAK',
              style: TextStyle(
                  color: Color(0xFFFFB703),
                  fontSize: 9,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('$streak',
                  style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const Text(' Days',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isDone = index < 5;
              return Column(
                children: [
                  Icon(isDone ? Icons.check_circle : Icons.circle_outlined,
                      color: isDone
                          ? const Color(0xFF00E676)
                          : const Color(0xFF334155),
                      size: 14),
                  Text(days[index],
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 8)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int completed) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("⚙ TODAY'S PROGRESS",
              style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        color: Color(0xFF00E676),
                        backgroundColor: Color(0xFF0F3628)),
                  ),
                  Text('$completed/5',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alhamdulillah!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text('Completed today.',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrayerStatisticsScreen())),
            child: const Row(
              children: [
                Icon(Icons.show_chart, color: Color(0xFF00E676), size: 12),
                SizedBox(width: 4),
                Text('View Analytics',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunAndMosqueRow(DailyPrayerTimes? dailyTimes) {
    final sunrise = dailyTimes?.sunrise.formattedTime ?? '06:11 AM';
    final sunset = dailyTimes?.maghrib.formattedTime ?? '06:48 PM';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('☀️ SUN & MOON',
                    style: TextStyle(
                        color: Color(0xFFFFB703),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Center(
                    child: Text('⌒⌒⌒⌒⌒⌒⌒⌒⌒',
                        style: TextStyle(
                            color: Color(0xFF1B5940),
                            fontSize: 14,
                            letterSpacing: 2))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sunrise',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 9)),
                        Text(sunrise,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Column(
                      children: [
                        Text('Daylight',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 9)),
                        Text('12h 37m',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Sunset',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 9)),
                        Text(sunset,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF061A13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF143B2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🕌 NEAREST MOSQUE',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masjid Al-Falah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '0.8 km away',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.go(AppRoutes.mosques),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0B2E21),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View on Map',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF00E676), size: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayDuaBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF071E16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF164735)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book_rounded,
                color: Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TODAY'S DUA",
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                  'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'O Allah, I ask You for well-being in this world and in the Hereafter.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isDuaFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isDuaFavorite
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isDuaFavorite = !_isDuaFavorite);
            },
          ),
        ],
      ),
    );
  }
}
