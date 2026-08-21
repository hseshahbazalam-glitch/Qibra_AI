// lib/features/prayer/presentation/prayer_times_screen.dart
// ============================================================
// QIBRA AI — FLAGSHIP PRAYER SCREEN (Exact Gold & Emerald UI)
// Fully interactive: Live Countdown, Calculation Method Selector,
// Prayer Tracking, Tahajjud Hub, Streak Analytics & Mosque Finder
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/media/safe_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';
import 'prayer_statistics_screen.dart';
import 'salah_schedule_screen.dart';
import 'tahajjud_details_screen.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _timer;
  final Set<String> _completedPrayers = {'Fajr', 'Sunrise'};

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
    final qiblaDirection = ref.watch(qiblaDirectionProvider);
    final statistics = ref.watch(prayerStatisticsProvider);
    final settings = ref.watch(prayerSettingsProvider);

    // Dates
    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    final gregDateStr = DateFormat('EEEE, d MMM yyyy').format(now);

    // Countdown
    final countdown = nextPrayerInfo?.countdown ??
        const Duration(hours: 1, minutes: 41, seconds: 9);
    final totalSecs = countdown.inSeconds.abs();
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    final nextName = nextPrayerInfo?.prayer.type.name ?? 'Dhuhr';
    final nextArabic = nextPrayerInfo?.prayer.type.arabicName ?? 'الظهر';

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
            ref.invalidate(prayerStatisticsProvider);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP APP BAR
                _buildTopAppBar(context),
                const SizedBox(height: 14),

                // 2. HERO ILLUMINATED MOSQUE CARD WITH RADIAL RING
                _buildHeroPrayerCard(
                  context,
                  hijriStr: hijriStr,
                  gregDateStr: gregDateStr,
                  nextName: nextName,
                  nextArabic: nextArabic,
                  hours: h,
                  minutes: m,
                  seconds: s,
                  qiblaAngle: qiblaDirection?.round() ?? 290,
                ),
                const SizedBox(height: 16),

                // 3. TODAY'S PRAYER TIMES LIST CARD WITH STATUS CHECKMARKS
                _buildTodayPrayerTimesCard(
                  context,
                  dailyTimes: dailyTimes,
                  nextName: nextName,
                  methodName: settings.calculationMethod.name,
                ),
                const SizedBox(height: 16),

                // 4. TAHAJJUD & PRAYER STREAK (TWO-COLUMN)
                _buildTahajjudAndStreakRow(
                  context,
                  streakDays: statistics.currentStreak > 0
                      ? statistics.currentStreak
                      : 12,
                ),
                const SizedBox(height: 16),

                // 5. QIBLA DIRECTION TRAJECTORY CARD
                _buildQiblaTrajectoryCard(
                    context, qiblaDirection?.round() ?? 290),
                const SizedBox(height: 16),

                // 6. NEAREST MOSQUE CARD WITH MAP PREVIEW
                _buildNearestMosqueCard(context),
                const SizedBox(height: 16),

                // 7. DUA BEFORE PRAYER BANNER
                _buildDuaBeforePrayerBanner(context),
                const SizedBox(height: 110), // Bottom navigation spacing
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
  Widget _buildTopAppBar(BuildContext context) {
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
            child:
                const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),

        // Title
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRAYER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Strengthen your connection with Allah ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                  ),
                  Text('💚', style: TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ),

        // 3 Emerald Action Buttons
        _buildTopIconBtn(
          icon: Icons.calendar_month_rounded,
          onTap: () => context.go(AppRoutes.islamicCalendar),
        ),
        const SizedBox(width: 8),
        _buildTopIconBtn(
          icon: Icons.location_on_outlined,
          onTap: () => context.go(AppRoutes.qibla),
        ),
        const SizedBox(width: 8),
        _buildTopIconBtn(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/settings/notifications'),
        ),
      ],
    );
  }

  Widget _buildTopIconBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF071E16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF143B2C)),
        ),
        child: Icon(icon, color: const Color(0xFF00E676), size: 19),
      ),
    );
  }

  // ============================================================
  // 2. HERO PRAYER CARD (Illuminated Mosque + Radial Ring)
  // ============================================================
  Widget _buildHeroPrayerCard(
    BuildContext context, {
    required String hijriStr,
    required String gregDateStr,
    required String nextName,
    required String nextArabic,
    required String hours,
    required String minutes,
    required String seconds,
    required int qiblaAngle,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Prayer Details & Digital Timer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('NEXT PRAYER',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Text('LIVE ((•))',
                                    style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0),
                            ),
                            Text(
                              nextArabic,
                              style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 16,
                                  fontFamily: 'Amiri'),
                            ),
                            const SizedBox(height: 8),
                            const Text('Starts in',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 10.5)),
                            const SizedBox(height: 2),
                            Text(
                              '$hours : $minutes : $seconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                'Hrs        Mins       Secs',
                                style: TextStyle(
                                    color: Color(0xFF64748B), fontSize: 9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SalahScheduleScreen()),
                                );
                              },
                              child: const Text('View All Timings >',
                                  style: TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      // Right Radial Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: 0.72,
                              strokeWidth: 6,
                              backgroundColor: Color(0xFF16221B),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E676)),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('72%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('of time passed\nuntil $nextName',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 8)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Info Strip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF00E676), size: 13),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hijriStr,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold)),
                                Text(gregDateStr,
                                    style: const TextStyle(
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
                            Text('25°C\nClear Sky',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    height: 1.1)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.explore_outlined,
                                color: Color(0xFF00E676), size: 13),
                            const SizedBox(width: 4),
                            Text('Qibla $qiblaAngle°\nNW',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    height: 1.1)),
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
  // 3. TODAY'S PRAYER TIMES LIST CARD WITH STATUS CHECKMARKS
  // ============================================================
  Widget _buildTodayPrayerTimesCard(
    BuildContext context, {
    required DailyPrayerTimes? dailyTimes,
    required String nextName,
    required String methodName,
  }) {
    final prayers = [
      {
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': dailyTimes?.fajr.formattedTime ?? '04:30 AM',
        'icon': Icons.wb_twilight_rounded,
        'color': const Color(0xFF00E676),
        'isNext': nextName == 'Fajr',
      },
      {
        'name': 'Sunrise',
        'arabic': 'الشروق',
        'time': dailyTimes?.sunrise.formattedTime ?? '05:42 AM',
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFFB703),
        'isNext': false,
      },
      {
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': dailyTimes?.dhuhr.formattedTime ?? '11:57 AM',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFFFB703),
        'isNext': nextName == 'Dhuhr',
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': dailyTimes?.asr.formattedTime ?? '03:01 PM',
        'icon': Icons.cloud_rounded,
        'color': const Color(0xFFEF4444),
        'isNext': nextName == 'Asr',
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': dailyTimes?.maghrib.formattedTime ?? '06:11 PM',
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFFFFB703),
        'isNext': nextName == 'Maghrib',
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': dailyTimes?.isha.formattedTime ?? '07:19 PM',
        'icon': Icons.brightness_2_rounded,
        'color': const Color(0xFF38BDF8),
        'isNext': nextName == 'Isha',
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
                onTap: () => _showCalculationMethodSheet(context),
                child: const Text('Method: Karachi (Hanafi) ⓘ',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...prayers.map((p) => _buildPrayerTimelineTile(context, p)),
        ],
      ),
    );
  }

  Widget _buildPrayerTimelineTile(
      BuildContext context, Map<String, dynamic> p) {
    final isNext = p['isNext'] as bool;
    final name = p['name'] as String;
    final isDone = _completedPrayers.contains(name);
    final color = p['color'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isDone) {
            _completedPrayers.remove(name);
          } else {
            _completedPrayers.add(name);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDone
                ? '$name prayer unmarked'
                : '$name marked as completed! MashaAllah 💚'),
            backgroundColor: const Color(0xFF0B2E21),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xFF0A2217) : const Color(0xFF050806),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext ? const Color(0xFF00E676) : const Color(0xFF16201A),
          ),
        ),
        child: Row(
          children: [
            Icon(p['icon'] as IconData, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      if (isNext) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00E676).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                          fontSize: 9.5,
                          fontFamily: 'Amiri')),
                ],
              ),
            ),
            Text(p['time'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : (isNext
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.circle_outlined),
              color: isDone
                  ? const Color(0xFF00E676)
                  : (isNext
                      ? const Color(0xFFFFB703)
                      : const Color(0xFF64748B)),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 4. TAHAJJUD & PRAYER STREAK (TWO-COLUMN)
  // ============================================================
  Widget _buildTahajjudAndStreakRow(BuildContext context,
      {required int streakDays}) {
    return Row(
      children: [
        // Left: Tahajjud Card (Purple Theme)
        Expanded(
          flex: 54,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TahajjudDetailsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF261B40), Color(0xFF130E20)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF4C367C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.nightlight_round,
                          color: Color(0xFFFFB703), size: 12),
                      SizedBox(width: 4),
                      Text('TAHAJJUD HUB',
                          style: TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text('Tahajjud',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('قيام الليل',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 11,
                          fontFamily: 'Amiri')),
                  SizedBox(height: 6),
                  Text('Starts in 04:32:15',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold)),
                  Text('Hrs        Mins       Secs',
                      style:
                          TextStyle(color: Color(0xFF64748B), fontSize: 7.5)),
                  SizedBox(height: 4),
                  Text('Best time: Last third of the night',
                      style:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Prayer Streak Card
        Expanded(
          flex: 46,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrayerStatisticsScreen()),
              );
            },
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
                      Text('🔥', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text('PRAYER STREAK',
                          style: TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('$streakDays',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const Text(' Days',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
                      final isStar = d == 'S';
                      return Column(
                        children: [
                          Icon(isStar ? Icons.star_rounded : Icons.check_circle,
                              color: isStar
                                  ? const Color(0xFFFFB703)
                                  : const Color(0xFF00E676),
                              size: 10),
                          const SizedBox(height: 2),
                          Text(d,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 7.5)),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text("Keep it up! You're on fire! 🔥",
                      style:
                          TextStyle(color: Color(0xFFFFB703), fontSize: 7.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 5. QIBLA DIRECTION TRAJECTORY CARD
  // ============================================================
  Widget _buildQiblaTrajectoryCard(BuildContext context, int angle) {
    return InkWell(
      onTap: () => context.go(AppRoutes.qibla),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF080C0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1A221C)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🕋 ', style: TextStyle(fontSize: 12)),
                      Text('QIBLA DIRECTION',
                          style: TextStyle(
                              color: Color(0xFFFFB703),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Your Qibla Direction',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('$angle° NW',
                      style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Text('┈┈┈ 🕋 ┈┈┈>',
                style: TextStyle(color: Color(0xFFFFB703), fontSize: 12)),
            const SizedBox(width: 8),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
              ),
              child: ClipOval(
                child: SafeImage(
                  assetPath: 'assets/images/hero/compass_qibla.png',
                  fit: BoxFit.cover,
                  fallback: SafeImageFallback.mosque,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 6. NEAREST MOSQUE CARD WITH MAP PREVIEW
  // ============================================================
  Widget _buildNearestMosqueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A221C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mosque_rounded,
                        color: Color(0xFFFFB703), size: 14),
                    SizedBox(width: 4),
                    Text('NEAREST MOSQUE',
                        style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Masjid Al-Falah',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const Text('0.8 km away • Women area, Parking',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.go(AppRoutes.mosques),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF072418),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF144D34)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Find Mosques >',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF00E676), size: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF0C1612),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF163828)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 32)),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Color(0xFF00E676), shape: BoxShape.circle),
                  child: const Icon(Icons.mosque,
                      color: Color(0xFF020A08), size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7. DUA BEFORE PRAYER BANNER
  // ============================================================
  Widget _buildDuaBeforePrayerBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Row(
                children: [
                  Icon(Icons.volunteer_activism_rounded,
                      color: Color(0xFFFFB703), size: 14),
                  SizedBox(width: 5),
                  Text('DUA BEFORE PRAYER',
                      style: TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.dua),
                child: const Text('View More Duas >',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Amiri',
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '"O Allah, keep me away from my sins as You have kept the east and the west apart."',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showCalculationMethodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF080C0A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border:
                Border(top: BorderSide(color: Color(0xFF1E3A2B), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calculation Method & Juristic School',
                  style: TextStyle(
                      color: Color(0xFFFFB703),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00E676)),
                title: const Text('University of Karachi (Hanafi)',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                subtitle: const Text('Standard method for Indian Subcontinent',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                onTap: () {
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .setCalculationMethod(CalculationMethod.karachi);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.circle_outlined, color: Color(0xFF64748B)),
                title: const Text('Muslim World League (MWL)',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text(
                    'Standard method for Europe, Far East, parts of US',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                onTap: () {
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .setCalculationMethod(
                          CalculationMethod.muslimWorldLeague);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.circle_outlined, color: Color(0xFF64748B)),
                title: const Text('Umm al-Qura (Makkah)',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: const Text('Standard method for Arabian Peninsula',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                onTap: () {
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .setCalculationMethod(CalculationMethod.ummAlQura);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
