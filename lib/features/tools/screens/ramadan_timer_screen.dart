import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class RamadanTimerScreen extends StatefulWidget {
  const RamadanTimerScreen({super.key});

  @override
  State<RamadanTimerScreen> createState() => _RamadanTimerScreenState();
}

class _RamadanTimerScreenState extends State<RamadanTimerScreen> {
  Timer? _timer;
  Duration _suhoorCountdown = Duration.zero;
  Duration _iftarCountdown = Duration.zero;
  bool _isFasting = false;

  // Ramadan 2025 estimated dates
  static final DateTime _ramadanStart = DateTime(2025, 2, 28);
  static final DateTime _ramadanEnd = DateTime(2025, 3, 30);

  // Default times (will vary by location)
  static const String _suhoorTime = '4:45 AM';
  static const String _iftarTime = '6:35 PM';
  static const int _suhoorHour = 4;
  static const int _suhoorMinute = 45;
  static const int _iftarHour = 18;
  static const int _iftarMinute = 35;

  final List<_RamadanDua> _duas = const [
    _RamadanDua(
      title: 'Suhoor Dua (Intention)',
      arabic: 'وَبِصَوْمِ غَدٍ نَوَيْتُ مِنْ شَهْرِ رَمَضَانَ',
      transliteration: 'Wa bisawmi ghadin nawaytu min shahri Ramadan',
      translation:
          'I intend to keep the fast for tomorrow in the month of Ramadan',
    ),
    _RamadanDua(
      title: 'Iftar Dua',
      arabic:
          'اللَّهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ',
      transliteration:
          'Allahumma inni laka sumtu wa bika aamantu wa ala rizqika aftartu',
      translation:
          'O Allah! I fasted for You and I believe in You and I break my fast with Your sustenance',
    ),
    _RamadanDua(
      title: 'Dua at Iftar Time',
      arabic:
          'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
      transliteration:
          'Dhahaba al-zama wa abtallatil-urooq wa thabatal-ajru insha Allah',
      translation:
          'The thirst has gone, the veins are moistened and the reward is confirmed, if Allah wills',
    ),
  ];

  final List<_RamadanTip> _tips = const [
    _RamadanTip(Icons.nightlight_round, 'Pray Taraweeh',
        'Special night prayer in Ramadan'),
    _RamadanTip(Icons.menu_book_rounded, 'Read Quran Daily',
        'Try to complete it this month'),
    _RamadanTip(Icons.favorite_rounded, 'Give Charity',
        'Rewards are multiplied in Ramadan'),
    _RamadanTip(Icons.self_improvement_rounded, 'Make Dua',
        'Especially before Iftar'),
    _RamadanTip(Icons.mosque_rounded, 'Itikaf',
        'Last 10 days seclusion in mosque'),
    _RamadanTip(Icons.wb_twilight, 'Suhoor', 'Never skip — it is blessed'),
  ];

  @override
  void initState() {
    super.initState();
    _updateCountdowns();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdowns();
    });
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    final todaySuhoor =
        DateTime(now.year, now.month, now.day, _suhoorHour, _suhoorMinute);
    final todayIftar =
        DateTime(now.year, now.month, now.day, _iftarHour, _iftarMinute);

    setState(() {
      if (now.isBefore(todaySuhoor)) {
        _suhoorCountdown = todaySuhoor.difference(now);
        _iftarCountdown = todayIftar.difference(now);
        _isFasting = false;
      } else if (now.isBefore(todayIftar)) {
        _suhoorCountdown = Duration.zero;
        _iftarCountdown = todayIftar.difference(now);
        _isFasting = true;
      } else {
        final tomorrowSuhoor = todaySuhoor.add(const Duration(days: 1));
        _suhoorCountdown = tomorrowSuhoor.difference(now);
        _iftarCountdown = Duration.zero;
        _isFasting = false;
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  int get _daysUntilRamadan {
    final now = DateTime.now();
    if (now.isAfter(_ramadanEnd)) return -1;
    if (now.isAfter(_ramadanStart)) return 0;
    return _ramadanStart.difference(now).inDays;
  }

  int get _currentRamadanDay {
    final now = DateTime.now();
    if (now.isBefore(_ramadanStart) || now.isAfter(_ramadanEnd)) return 0;
    return now.difference(_ramadanStart).inDays + 1;
  }

  bool get _isRamadan {
    final now = DateTime.now();
    return now.isAfter(_ramadanStart) && now.isBefore(_ramadanEnd);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildTimerCards(),
                const SizedBox(height: 20),
                _buildFastingProgress(),
                const SizedBox(height: 24),
                _buildDuasSection(),
                const SizedBox(height: 24),
                _buildTipsSection(),
                const SizedBox(height: 20),
                _buildIslamicNote(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded,
              color: colors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رَمَضَان',
                    style: AppArabicStyles.quranMedium.copyWith(
                      fontSize: 24,
                      color: colors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'Ramadan Timer',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Suhoor & Iftar Countdown',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status Card ────────────────────────────────────────────
  Widget _buildStatusCard() {
    final colors = QibraColors.of(context);
    final isRamadan = _isRamadan;
    final daysLeft = _daysUntilRamadan;
    final ramadanDay = _currentRamadanDay;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRamadan ? colors.primary : colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRamadan
              ? colors.onPrimary.withValues(alpha: 0.16)
              : colors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isRamadan
                  ? colors.onPrimary.withValues(alpha: 0.15)
                  : colors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isRamadan
                    ? Icons.nightlight_round
                    : Icons.calendar_month_rounded,
                size: 28,
                color: isRamadan ? colors.onPrimary : colors.accent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRamadan) ...[
                  Text(
                    'Ramadan Mubarak!',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Day $ramadanDay of 30',
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ramadanDay / 30,
                      minHeight: 5,
                      backgroundColor:
                          colors.onPrimary.withValues(alpha: 0.2),
                      valueColor:
                          AlwaysStoppedAnimation(colors.onPrimary),
                    ),
                  ),
                ] else if (daysLeft > 0) ...[
                  Text(
                    'Ramadan is Coming!',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$daysLeft',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'days remaining',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Ramadan has passed',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'May Allah accept your fasts',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timer Cards ────────────────────────────────────────────
  Widget _buildTimerCards() {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _timerCard(
            label: 'SUHOOR',
            time: _suhoorTime,
            countdown: _suhoorCountdown,
            icon: Icons.wb_twilight,
            color: colors.accent,
            isActive: !_isFasting,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timerCard(
            label: 'IFTAR',
            time: _iftarTime,
            countdown: _iftarCountdown,
            icon: Icons.nightlight_round,
            color: colors.accent,
            isActive: _isFasting,
          ),
        ),
      ],
    );
  }

  Widget _timerCard({
    required String label,
    required String time,
    required Duration countdown,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.16)
              : colors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22, color: color),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NEXT',
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (countdown > Duration.zero)
            Text(
              _formatDuration(countdown),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            )
          else
            Text(
              'Passed',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Fasting Progress ───────────────────────────────────────
  Widget _buildFastingProgress() {
    final colors = QibraColors.of(context);
    if (!_isFasting) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.bedtime_rounded, size: 24,
                color: colors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not Fasting Currently',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Next Suhoor in ${_formatDuration(_suhoorCountdown)}',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    const totalFastMinutes =
        (_iftarHour * 60 + _iftarMinute) - (_suhoorHour * 60 + _suhoorMinute);
    final elapsedMinutes = totalFastMinutes - _iftarCountdown.inMinutes;
    final progress = elapsedMinutes / totalFastMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.self_improvement_rounded, size: 18,
                      color: colors.primary),
                  SizedBox(width: 8),
                  Text(
                    'FASTING NOW',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _suhoorTime,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                _iftarTime,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Duas Section ───────────────────────────────────────────
  Widget _buildDuasSection() {
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.self_improvement_rounded, size: 16,
                color: colors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'RAMADAN DUAS',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._duas.map((dua) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildDuaCard(dua),
            )),
      ],
    );
  }

  Widget _buildDuaCard(_RamadanDua dua) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Clipboard.setData(ClipboardData(text: dua.arabic));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dua copied to clipboard',
                style: TextStyle(color: colors.textPrimary)),
            backgroundColor: colors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: colors.accent.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dua.title,
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.copy_rounded,
                    color: colors.textTertiary, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dua.arabic,
              style: AppArabicStyles.quranSmall.copyWith(
                fontSize: 18,
                color: colors.textPrimary,
                height: 1.6,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              dua.transliteration,
              style: TextStyle(
                color: colors.accent,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dua.translation,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tips Section ───────────────────────────────────────────
  Widget _buildTipsSection() {
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 16),
            const SizedBox(width: 8),
            Text(
              'RAMADAN TIPS',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _tips.length,
            itemBuilder: (ctx, i) {
              final tip = _tips[i];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip.icon, size: 22, color: colors.accent),
                    const Spacer(),
                    Text(
                      tip.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tip.subtitle,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Islamic Note ───────────────────────────────────────────
  Widget _buildIslamicNote() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 14, color: colors.accent),
              SizedBox(width: 8),
              Text(
                'Hadith',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"When Ramadan begins, the gates of Paradise are opened, the gates of Hell are closed, and the devils are chained." — Bukhari & Muslim',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────
class _RamadanDua {
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  const _RamadanDua({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

class _RamadanTip {
  final IconData icon;
  final String title;
  final String subtitle;
  const _RamadanTip(this.icon, this.title, this.subtitle);
}
