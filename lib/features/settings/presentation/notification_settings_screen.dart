// lib/features/settings/presentation/notification_settings_screen.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _prayerNotifications = true;
  bool _prePrayerAlert = true;
  int _preMinutes = 10;
  bool _tahajjudNotification = false;
  int _tahajjudHour = 3;
  int _tahajjudMinute = 30;
  bool _morningAdhkar = true;
  bool _eveningAdhkar = true;
  bool _jummahNotification = true;
  bool _quranReminder = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prayerNotifications = prefs.getBool('prayer_notifications') ?? true;
      _prePrayerAlert = prefs.getBool('pre_prayer_alert') ?? true;
      _preMinutes = prefs.getInt('pre_minutes') ?? 10;
      _tahajjudNotification = prefs.getBool('tahajjud_notification') ?? false;
      _tahajjudHour = prefs.getInt('tahajjud_hour') ?? 3;
      _tahajjudMinute = prefs.getInt('tahajjud_minute') ?? 30;
      _morningAdhkar = prefs.getBool('morning_adhkar') ?? true;
      _eveningAdhkar = prefs.getBool('evening_adhkar') ?? true;
      _jummahNotification = prefs.getBool('jummah_notification') ?? true;
      _quranReminder = prefs.getBool('quran_reminder') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_notifications', _prayerNotifications);
    await prefs.setBool('pre_prayer_alert', _prePrayerAlert);
    await prefs.setInt('pre_minutes', _preMinutes);
    await prefs.setBool('tahajjud_notification', _tahajjudNotification);
    await prefs.setInt('tahajjud_hour', _tahajjudHour);
    await prefs.setInt('tahajjud_minute', _tahajjudMinute);
    await prefs.setBool('morning_adhkar', _morningAdhkar);
    await prefs.setBool('evening_adhkar', _eveningAdhkar);
    await prefs.setBool('jummah_notification', _jummahNotification);
    await prefs.setBool('quran_reminder', _quranReminder);

    final service = NotificationService();
    await service.initialize();
    await service.cancelAllNotifications();

    if (_morningAdhkar) await service.scheduleMorningAdhkar();
    if (_eveningAdhkar) await service.scheduleEveningAdhkar();
    if (_jummahNotification) await service.scheduleJummahReminder();
    if (_tahajjudNotification) {
      await service.scheduleTahajjudReminder(
        hour: _tahajjudHour,
        minute: _tahajjudMinute,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Settings saved! ✅',
          style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1B4332),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _testNotification() async {
    HapticFeedback.heavyImpact();

    // Azan sound bajao
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/azan_makkah.mp3'));
      debugPrint('✅ Azan test playing');
    } catch (e) {
      debugPrint('❌ Azan test error: $e');
    }

    // Notification bhi bhejna
    final service = NotificationService();
    await service.initialize();
    await service.showInstantNotification(
      title: '🕌 Test — Fajr Prayer Time',
      body: 'الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ — Prayer is better than sleep',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPermissionCard(),
                const SizedBox(height: 20),
                _buildSectionHeader('🕌', 'PRAYER NOTIFICATIONS'),
                const SizedBox(height: 12),
                _buildSettingCard(children: [
                  _settingToggle(
                    'Prayer Time Alerts',
                    'Get notified at each prayer time',
                    '🕌',
                    _prayerNotifications,
                    (v) => setState(() => _prayerNotifications = v),
                    const Color(0xFF00E676),
                  ),
                  if (_prayerNotifications) ...[
                    const Divider(color: Color(0xFF1E2535), height: 20),
                    _settingToggle(
                      'Pre-Prayer Alert',
                      'Alert before prayer time',
                      '⏰',
                      _prePrayerAlert,
                      (v) => setState(() => _prePrayerAlert = v),
                      const Color(0xFFFFD166),
                    ),
                    if (_prePrayerAlert) ...[
                      const SizedBox(height: 10),
                      _minuteSelector(),
                    ],
                  ],
                ]),
                const SizedBox(height: 12),
                if (_prayerNotifications) _buildPrayersList(),
                const SizedBox(height: 20),
                _buildSectionHeader('🌙', 'TAHAJJUD REMINDER'),
                const SizedBox(height: 12),
                _buildSettingCard(children: [
                  _settingToggle(
                    'Tahajjud Alarm',
                    'Wake up for night prayer',
                    '🌙',
                    _tahajjudNotification,
                    (v) => setState(() => _tahajjudNotification = v),
                    const Color(0xFFD4AF37),
                  ),
                  if (_tahajjudNotification) ...[
                    const Divider(color: Color(0xFF1E2535), height: 20),
                    _timeSelector(
                      'Alarm Time',
                      _tahajjudHour,
                      _tahajjudMinute,
                      (h, m) => setState(() {
                        _tahajjudHour = h;
                        _tahajjudMinute = m;
                      }),
                      const Color(0xFFD4AF37),
                    ),
                  ],
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader('📿', 'DAILY ADHKAR'),
                const SizedBox(height: 12),
                _buildSettingCard(children: [
                  _settingToggle(
                    'Morning Adhkar',
                    'Daily reminder at 7:00 AM',
                    '🌅',
                    _morningAdhkar,
                    (v) => setState(() => _morningAdhkar = v),
                    const Color(0xFFFFD166),
                  ),
                  const Divider(color: Color(0xFF1E2535), height: 20),
                  _settingToggle(
                    'Evening Adhkar',
                    'Daily reminder at 5:30 PM',
                    '🌇',
                    _eveningAdhkar,
                    (v) => setState(() => _eveningAdhkar = v),
                    const Color(0xFFD4AF37),
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader('🕋', 'SPECIAL REMINDERS'),
                const SizedBox(height: 12),
                _buildSettingCard(children: [
                  _settingToggle(
                    'Jummah Reminder',
                    'Every Friday 11:30 AM',
                    '🕋',
                    _jummahNotification,
                    (v) => setState(() => _jummahNotification = v),
                    const Color(0xFF00E676),
                  ),
                  const Divider(color: Color(0xFF1E2535), height: 20),
                  _settingToggle(
                    'Quran Daily',
                    'Read Quran reminder',
                    '📖',
                    _quranReminder,
                    (v) => setState(() => _quranReminder = v),
                    const Color(0xFF74C0FC),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildTestButton(),
                const SizedBox(height: 12),
                _buildSaveButton(),
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

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E1A),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF0A0E1A)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الإِشْعَارَات',
                      style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 22,
                          fontFamily: 'Amiri')),
                  const Text('Notification Settings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Prayer alerts & reminders',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return GestureDetector(
      onTap: () async {
        final service = NotificationService();
        await service.initialize();
        final granted = await service.requestPermission();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                granted ? 'Permission granted! ✅' : 'Permission denied ❌',
                style: const TextStyle(color: Colors.white)),
            backgroundColor:
                granted ? const Color(0xFF1B4332) : const Color(0xFF7F1D1D),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00E676).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF00E676), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable Notifications',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('Tap to grant notification permission',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF00E676), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
      ],
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingToggle(
    String title,
    String subtitle,
    String emoji,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: value
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 26,
            decoration: BoxDecoration(
              color: value ? color : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _minuteSelector() {
    final options = [5, 10, 15, 20, 30];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alert before prayer:',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: options.map((min) {
            final selected = _preMinutes == min;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _preMinutes = min);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFD166).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFD166)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    '${min}m',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFFFD166)
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _timeSelector(
    String label,
    int hour,
    int minute,
    Function(int, int) onChanged,
    Color color,
  ) {
    final ampm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final timeStr =
        '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00E676),
                surface: Color(0xFF141926),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(picked.hour, picked.minute);
        }
      },
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(timeStr,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayersList() {
    final prayers = [
      const _PrayerItem('Fajr', '🌅', 'Dawn prayer', Color(0xFFFFB703)),
      const _PrayerItem('Dhuhr', '☀️', 'Midday prayer', Color(0xFFFBBF24)),
      const _PrayerItem('Asr', '🌤️', 'Afternoon prayer', Color(0xFF00E676)),
      const _PrayerItem('Maghrib', '🌇', 'Sunset prayer', Color(0xFFD4AF37)),
      const _PrayerItem('Isha', '🌙', 'Night prayer', Color(0xFF0891B2)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: prayers.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(p.subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 9)),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: p.color, shape: BoxShape.circle),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestButton() {
    return GestureDetector(
      onTap: _testNotification,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_rounded,
                color: Color(0xFF00E676), size: 18),
            SizedBox(width: 8),
            Text('Test Azan + Notification',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveSettings,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFF2D6A4F)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Save Settings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _buildIslamicNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.15)),
      ),
      child: Text(
        '"Guard strictly your prayers, especially the middle prayer (Asr). And stand before Allah with obedience." — Quran 2:238',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontStyle: FontStyle.italic,
            height: 1.5),
      ),
    );
  }
}

class _PrayerItem {
  final String name;
  final String emoji;
  final String subtitle;
  final Color color;
  const _PrayerItem(this.name, this.emoji, this.subtitle, this.color);
}
