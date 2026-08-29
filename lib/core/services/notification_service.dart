import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications only. Scheduling uses inexact alarms.
/// Do not claim reboot-proof or exact-alarm delivery; those are not device-tested.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _fajrId = 1001;
  static const int _dhuhrId = 1002;
  static const int _asrId = 1003;
  static const int _maghribId = 1004;
  static const int _ishaId = 1005;

  static const int _tahajjudId = 1006;
  static const int _jummahId = 1007;
  static const int _morningAdhkarId = 1008;
  static const int _eveningAdhkarId = 1009;

  static const int _fajrPreId = 2001;
  static const int _dhuhrPreId = 2002;
  static const int _asrPreId = 2003;
  static const int _maghribPreId = 2004;
  static const int _ishaPreId = 2005;

  // ────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'azan_channel',
        'Azan Notifications',
        description: 'Prayer time azan notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('azan_makkah'),
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'pre_prayer_channel',
        'Pre-Prayer Reminders',
        description: 'Reminders before prayer time',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'islamic_channel',
        'Islamic Reminders',
        description: 'Daily Islamic reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tahajjud_channel',
        'Tahajjud Reminder',
        description: 'Tahajjud alarm and night prayer reminder',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // PERMISSION
  // ────────────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  // ────────────────────────────────────────────────────────────
  // PRAYER NOTIFICATIONS
  // ────────────────────────────────────────────────────────────
  Future<void> schedulePrayerNotifications({
    required DateTime fajr,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
    bool prePrayerAlert = true,
    int preMinutes = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('prayer_notifications') ?? true;

    if (!enabled) return;

    await cancelPrayerNotifications();

    await _schedulePrayer(
      id: _fajrId,
      preId: _fajrPreId,
      name: 'Fajr',
      arabic: 'الفجر',
      time: fajr,
      prePrayerAlert: prePrayerAlert,
      preMinutes: preMinutes,
    );

    await _schedulePrayer(
      id: _dhuhrId,
      preId: _dhuhrPreId,
      name: 'Dhuhr',
      arabic: 'الظهر',
      time: dhuhr,
      prePrayerAlert: prePrayerAlert,
      preMinutes: preMinutes,
    );

    await _schedulePrayer(
      id: _asrId,
      preId: _asrPreId,
      name: 'Asr',
      arabic: 'العصر',
      time: asr,
      prePrayerAlert: prePrayerAlert,
      preMinutes: preMinutes,
    );

    await _schedulePrayer(
      id: _maghribId,
      preId: _maghribPreId,
      name: 'Maghrib',
      arabic: 'المغرب',
      time: maghrib,
      prePrayerAlert: prePrayerAlert,
      preMinutes: preMinutes,
    );

    await _schedulePrayer(
      id: _ishaId,
      preId: _ishaPreId,
      name: 'Isha',
      arabic: 'العشاء',
      time: isha,
      prePrayerAlert: prePrayerAlert,
      preMinutes: preMinutes,
    );
  }

  Future<void> _schedulePrayer({
    required int id,
    required int preId,
    required String name,
    required String arabic,
    required DateTime time,
    required bool prePrayerAlert,
    required int preMinutes,
  }) async {
    final now = DateTime.now();

    if (time.isBefore(now)) return;

    if (prePrayerAlert && preMinutes > 0) {
      final preTime = time.subtract(Duration(minutes: preMinutes));
      if (preTime.isAfter(now)) {
        await _scheduleNotification(
          id: preId,
          title: '$name in $preMinutes minutes',
          body: 'Time to prepare for $name prayer — $arabic',
          scheduledDate: preTime,
          channelId: 'pre_prayer_channel',
          channelName: 'Pre-Prayer Reminders',
          payload: 'pre_prayer_$name',
        );
      }
    }

    await _scheduleNotification(
      id: id,
      title: '$name — $arabic',
      body: _getPrayerMessage(name),
      scheduledDate: time,
      channelId: 'azan_channel',
      channelName: 'Azan Notifications',
      payload: 'prayer_$name',
      isMax: true,
    );
  }

  String _getPrayerMessage(String prayer) {
    return switch (prayer) {
      'Fajr' =>
        'Prayer is better than sleep — الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ',
      'Dhuhr' => 'Come to prayer — حَيَّ عَلَى الصَّلَاةِ',
      'Asr' => 'Guard your prayers — حَافِظُوا عَلَى الصَّلَوَاتِ',
      'Maghrib' => 'Come to success — حَيَّ عَلَى الْفَلَاحِ',
      'Isha' => 'Establish the prayer — وَأَقِيمُوا الصَّلَاةَ',
      _ => 'Time for prayer — حَيَّ عَلَى الصَّلَاةِ',
    };
  }

  // ────────────────────────────────────────────────────────────
  // TAHAJJUD
  // ────────────────────────────────────────────────────────────
  Future<void> scheduleTahajjudReminder({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('tahajjud_notification') ?? false;

    if (!enabled) return;

    await _plugin.cancel(id: _tahajjudId);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: _tahajjudId,
      title: 'Tahajjud Time',
      body: 'Pray Tahajjud — وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ (17:79)',
      scheduledDate: scheduledDate,
      channelId: 'tahajjud_channel',
      channelName: 'Tahajjud Reminder',
      payload: 'tahajjud',
      daily: true,
    );
  }

  // ────────────────────────────────────────────────────────────
  // MORNING ADHKAR
  // ────────────────────────────────────────────────────────────
  Future<void> scheduleMorningAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('morning_adhkar') ?? true;

    if (!enabled) return;

    await _plugin.cancel(id: _morningAdhkarId);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 7, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: _morningAdhkarId,
      title: 'Morning Adhkar',
      body:
          'Start your day with dhikr — أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      scheduledDate: scheduledDate,
      channelId: 'islamic_channel',
      channelName: 'Islamic Reminders',
      payload: 'morning_adhkar',
      daily: true,
    );
  }

  // ────────────────────────────────────────────────────────────
  // EVENING ADHKAR
  // ────────────────────────────────────────────────────────────
  Future<void> scheduleEveningAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('evening_adhkar') ?? true;

    if (!enabled) return;

    await _plugin.cancel(id: _eveningAdhkarId);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 17, 30);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: _eveningAdhkarId,
      title: 'Evening Adhkar',
      body: 'End your day with dhikr — أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
      scheduledDate: scheduledDate,
      channelId: 'islamic_channel',
      channelName: 'Islamic Reminders',
      payload: 'evening_adhkar',
      daily: true,
    );
  }

  // ────────────────────────────────────────────────────────────
  // JUMMAH
  // ────────────────────────────────────────────────────────────
  Future<void> scheduleJummahReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('jummah_notification') ?? true;

    if (!enabled) return;

    await _plugin.cancel(id: _jummahId);

    final now = DateTime.now();
    int daysUntilFriday = DateTime.friday - now.weekday;

    if (daysUntilFriday == 0) {
      final reminderToday = DateTime(
        now.year,
        now.month,
        now.day,
        11,
        30,
      );
      if (now.isAfter(reminderToday)) {
        daysUntilFriday = 7;
      }
    } else if (daysUntilFriday < 0) {
      daysUntilFriday += 7;
    }

    final nextFriday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilFriday,
      11,
      30,
    );

    await _scheduleNotification(
      id: _jummahId,
      title: 'Jummah Mubarak!',
      body: 'Read Surah Al-Kahf & send Durood on Prophet',
      scheduledDate: nextFriday,
      channelId: 'azan_channel',
      channelName: 'Azan Notifications',
      payload: 'jummah',
    );
  }

  // ────────────────────────────────────────────────────────────
  // TEST NOTIFICATION
  // ────────────────────────────────────────────────────────────
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: 9999,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'azan_channel',
          'Azan Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // CANCEL
  // ────────────────────────────────────────────────────────────
  Future<void> cancelPrayerNotifications() async {
    for (final id in [
      _fajrId,
      _dhuhrId,
      _asrId,
      _maghribId,
      _ishaId,
      _fajrPreId,
      _dhuhrPreId,
      _asrPreId,
      _maghribPreId,
      _ishaPreId,
    ]) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ────────────────────────────────────────────────────────────
  // CORE SCHEDULER
  // ────────────────────────────────────────────────────────────
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    String? payload,
    bool daily = false,
    bool isMax = false,
  }) async {
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: isMax ? Importance.max : Importance.high,
          priority: isMax ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          sound: channelId == 'azan_channel'
              ? const RawResourceAndroidNotificationSound('azan_makkah')
              : null,
          playSound: true,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: channelId == 'azan_channel' ? 'azan_makkah.mp3' : null,
        ),
      );

      if (daily) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}
