// lib/features/home/presentation/home_screen.dart

// ============================================================
// QIBRA AI — HOME DASHBOARD
// Version: 1.0.0
// Description: Premium home screen with prayer countdown,
//              Hijri date, ayah of the day, and quick actions.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/shared/widgets/cards/app_card.dart';

// ============================================================
// AYAH OF THE DAY DATA
// ============================================================

class _AyahOfDay {
  final String arabic;
  final String translation;
  final String reference;

  const _AyahOfDay({
    required this.arabic,
    required this.translation,
    required this.reference,
  });
}

// Rotating ayahs — actual app mein API se aayegi
const List<_AyahOfDay> _ayahsList = [
  _AyahOfDay(
    arabic: 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
    translation: 'And whoever fears Allah - He will make for him a way out.',
    reference: 'Surah At-Talaq 65:2',
  ),
  _AyahOfDay(
    arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translation: 'Indeed, with hardship comes ease.',
    reference: 'Surah Ash-Sharh 94:6',
  ),
  _AyahOfDay(
    arabic: 'رَبِّ زِدْنِي عِلْمًا',
    translation: 'My Lord, increase me in knowledge.',
    reference: 'Surah Taha 20:114',
  ),
];

// ============================================================
// HOME SCREEN WIDGET
// ============================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ── STATE ────────────────────────────────────────────
  Timer? _countdownTimer;
  Duration _timeToNextPrayer = const Duration(hours: 2, minutes: 15);
  int _currentAyahIndex = 0;
  Timer? _ayahTimer;

  // Dummy next prayer info
  final String _nextPrayerName = 'Asr';
  final String _nextPrayerNameArabic = 'العصر';
  final String _nextPrayerTime = '3:45 PM';

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _startAyahRotation();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ayahTimer?.cancel();
    super.dispose();
  }

  // ── COUNTDOWN TIMER ──────────────────────────────────
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timeToNextPrayer.inSeconds > 0) {
        setState(() {
          _timeToNextPrayer = _timeToNextPrayer - const Duration(seconds: 1);
        });
      }
    });
  }

  // ── AYAH ROTATION ────────────────────────────────────
  void _startAyahRotation() {
    _ayahTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (mounted) {
          setState(() {
            _currentAyahIndex = (_currentAyahIndex + 1) % _ayahsList.length;
          });
        }
      },
    );
  }

  // ── COUNTDOWN FORMAT ─────────────────────────────────
  String get _formattedCountdown {
    final hours = _timeToNextPrayer.inHours;
    final minutes = _timeToNextPrayer.inMinutes.remainder(60);
    final seconds = _timeToNextPrayer.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ── ISLAMIC GREETING (Time-based) ────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Sabah al-khayr'; // Good morning
    if (hour < 17) return 'Asr al-khayr'; // Good afternoon
    return 'Masa al-khayr'; // Good evening
  }

  String _getGreetingArabic() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صَبَاحُ الْخَيْر';
    if (hour < 17) return 'عَصْرُ الْخَيْر';
    return 'مَسَاءُ الْخَيْر';
  }

  // ── PULL TO REFRESH ──────────────────────────────────
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _currentAyahIndex = (_currentAyahIndex + 1) % _ayahsList.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // ── APP BAR ────────────────────────────────
            _buildAppBar(userName, user),

            // ── BODY CONTENT ───────────────────────────
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.md),

                // Greeting section
                _buildGreetingSection(userName),

                const SizedBox(height: AppSpacing.xl2),

                // Next prayer card
                _buildNextPrayerCard(),

                const SizedBox(height: AppSpacing.xl2),

                // Section: Today
                _buildSectionTitle('TODAY', Icons.today),
                const SizedBox(height: AppSpacing.md),

                // Date card
                _buildDateCard(),

                const SizedBox(height: AppSpacing.xl2),

                // Section: Ayah of the day
                _buildSectionTitle(
                  'AYAH OF THE DAY',
                  Icons.auto_stories,
                ),
                const SizedBox(height: AppSpacing.md),

                // Ayah card
                _buildAyahCard(),

                const SizedBox(height: AppSpacing.xl2),

                // Section: Quick actions
                _buildSectionTitle(
                  'QUICK ACTIONS',
                  Icons.grid_view_rounded,
                ),
                const SizedBox(height: AppSpacing.md),

                // Quick actions grid
                _buildQuickActionsGrid(),

                const SizedBox(height: AppSpacing.xl2),

                // Section: Continue reading
                _buildSectionTitle(
                  'CONTINUE READING',
                  Icons.bookmark_outline,
                ),
                const SizedBox(height: AppSpacing.md),

                // Continue cards
                _buildContinueCard(),

                // Extra space for FAB
                const SizedBox(height: AppSpacing.xl6),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════

  Widget _buildAppBar(String userName, AppUser? user) {
    final isDark = ref.watch(isDarkModeProvider);

    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: _buildAvatar(userName),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreetingArabic(),
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            userName,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Theme toggle
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: AppColors.iconPrimary,
          ),
          onPressed: () {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),

        // Notification bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.iconPrimary,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  // ── AVATAR CIRCLE ────────────────────────────────────
  Widget _buildAvatar(String userName) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppGradients.emerald,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // GREETING SECTION
  // ══════════════════════════════════════════

  Widget _buildGreetingSection(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assalamu Alaikum
          Text(
            'Assalamu Alaikum',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Main greeting
          RichText(
            text: TextSpan(
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              children: [
                TextSpan(text: '${_getGreeting()},\n'),
                TextSpan(
                  text: userName.split(' ').first,
                  style: const TextStyle(color: AppColors.primary),
                ),
                TextSpan(
                  text: ' 👋',
                  style: AppTextStyles.headlineMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // NEXT PRAYER CARD
  // ══════════════════════════════════════════

  Widget _buildNextPrayerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: AppShadows.emeraldGlow,
        ),
        child: Stack(
          children: [
            // Decorative pattern (subtle)
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.mosque,
                size: 140,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(
                            AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.20),
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          child: const Icon(
                            Icons.access_time_filled,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'NEXT PRAYER',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.90),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Location badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Karachi',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Prayer name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _nextPrayerName,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _nextPrayerNameArabic,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          color: AppColors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Prayer time
                Text(
                  'at $_nextPrayerTime',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.80),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.buttonRadius,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'in $_formattedCountdown',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SECTION TITLE
  // ══════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: AppIconSizes.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // DATE CARD
  // ══════════════════════════════════════════

  Widget _buildDateCard() {
    final now = DateTime.now();
    final gregorianDate =
        '${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)} ${now.year}';

    // Dummy Hijri — real app mein hijri package se
    const hijriDate = '15 Rabi al-Thani 1446';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: AppCard(
        child: Row(
          children: [
            // Calendar icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.cardRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month,
                color: AppColors.background,
                size: 28,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Date info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hijriDate,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gregorianDate,
                    style: AppTextStyles.bodySmall.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }

  String _getMonth(int month) {
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

  // ══════════════════════════════════════════
  // AYAH OF THE DAY CARD
  // ══════════════════════════════════════════

  Widget _buildAyahCard() {
    final ayah = _ayahsList[_currentAyahIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        child: Container(
          key: ValueKey(_currentAyahIndex),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.borderGold.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gold decorative line
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Arabic text
              Text(
                ayah.arabic,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  height: 1.8,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Divider
              const Divider(
                color: AppColors.divider,
                height: 1,
              ),

              const SizedBox(height: AppSpacing.md),

              // Translation
              Text(
                ayah.translation,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Reference + actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline,
                        color: AppColors.accent,
                        size: AppIconSizes.sm,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        ayah.reference,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: AppColors.iconSecondary,
                        size: AppIconSizes.sm,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.favorite_outline,
                        color: AppColors.iconSecondary,
                        size: AppIconSizes.sm,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ══════════════════════════════════════════

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
        children: [
          _QuickActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Quran',
            subtitle: '114 Surahs',
            gradient: AppGradients.emerald,
            onTap: () => context.go(AppRoutes.quran),
          ),
          _QuickActionCard(
            icon: Icons.access_time_filled_rounded,
            title: 'Prayer',
            subtitle: 'Times & Qibla',
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF1E40AF),
              ],
            ),
            onTap: () => context.go(AppRoutes.prayer),
          ),
          _QuickActionCard(
            icon: Icons.explore_outlined,
            title: 'Qibla',
            subtitle: 'Find direction',
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7C3AED),
                Color(0xFF6D28D9),
              ],
            ),
            onTap: () => context.go(AppRoutes.qibla),
          ),
          _QuickActionCard(
            icon: Icons.pinch_rounded,
            title: 'Tasbih',
            subtitle: 'Digital counter',
            gradient: AppGradients.gold,
            isGold: true,
            onTap: () => context.go(AppRoutes.tasbih),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // CONTINUE READING CARD
  // ══════════════════════════════════════════

  Widget _buildContinueCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: AppCard(
        onTap: () => context.go(AppRoutes.quran),
        child: Row(
          children: [
            // Bookmark icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.bookmark,
                color: AppColors.primary,
                size: 28,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Surah Al-Baqarah',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ayah 255 · Ayatul Kursi',
                    style: AppTextStyles.bodySmall.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.35,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.emerald,
                                borderRadius: AppRadius.pillRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '35%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Continue arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// QUICK ACTION CARD WIDGET
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isGold;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: isGold ? AppShadows.goldGlow : AppShadows.medium,
        ),
        child: Stack(
          children: [
            // Decorative icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: (isGold ? AppColors.background : AppColors.white)
                    .withValues(alpha: 0.12),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: (isGold ? AppColors.background : AppColors.white)
                          .withValues(alpha: 0.20),
                      borderRadius: AppRadius.buttonRadius,
                    ),
                    child: Icon(
                      icon,
                      color: isGold ? AppColors.background : AppColors.white,
                      size: 20,
                    ),
                  ),

                  // Title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color:
                              isGold ? AppColors.background : AppColors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color:
                              (isGold ? AppColors.background : AppColors.white)
                                  .withValues(alpha: 0.80),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
