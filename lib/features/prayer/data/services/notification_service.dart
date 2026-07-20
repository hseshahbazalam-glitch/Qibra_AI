// lib/features/prayer/data/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel IDs
  static const String _channelIdAzan = 'qibra_azan_channel';
  static const String _channelIdReminder = 'qibra_reminder_channel';
  static const String _channelIdSilent = 'qibra_silent_channel';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _requestPermissions();
      _initialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init failed: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Permission failed: $e');
      return false;
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  // ============================================================
  // 1. AZAN NOTIFICATION (Prayer Time Alarm)
  // ============================================================

  Future<void> scheduleAzanNotification({
    required int id,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    bool playAdhan = true,
  }) async {
    if (!_initialized) await initialize();

    try {
      if (prayerTime.isBefore(DateTime.now())) {
        debugPrint('⏭️ Skipping $prayerName - time passed');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        _channelIdAzan,
        'Azan Alarms',
        channelDescription: 'Prayer time azan notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playAdhan,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: [
          const AndroidNotificationAction(
            'dismiss_action',
            'Dismiss',
            cancelNotification: true,
          ),
        ],
        styleInformation: BigTextStyleInformation(
          '🕌 It\'s time for $prayerName prayer.\n$prayerNameArabic',
          contentTitle: '🕌 $prayerName Prayer Time',
          summaryText: 'QIBRA AI',
        ),
      );

      final details = NotificationDetails(android: androidDetails);
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: '🕌 $prayerName Prayer Time',
        body: 'It\'s time for $prayerName ($prayerNameArabic) prayer',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'azan_$prayerName',
      );

      debugPrint('✅ Azan scheduled: $prayerName at $prayerTime');
    } catch (e) {
      debugPrint('❌ Azan schedule failed: $e');
    }
  }

  // ============================================================
  // 2. PRE-PRAYER REMINDER (15 min before)
  // ============================================================

  Future<void> schedulePreReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    if (!_initialized) await initialize();

    try {
      final reminderTime =
          prayerTime.subtract(Duration(minutes: minutesBefore));

      if (reminderTime.isBefore(DateTime.now())) {
        debugPrint('⏭️ Skipping reminder for $prayerName - time passed');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelIdReminder,
        'Pre-Prayer Reminders',
        channelDescription: 'Reminders before prayer time',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(android: androidDetails);
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: '⏰ $prayerName in $minutesBefore minutes',
        body: 'Get ready for $prayerName prayer',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_$prayerName',
      );

      debugPrint('✅ Pre-reminder scheduled: $prayerName at $reminderTime');
    } catch (e) {
      debugPrint('❌ Pre-reminder failed: $e');
    }
  }

  // ============================================================
  // 3. SILENT MODE REMINDER (at prayer time)
  // ============================================================

  Future<void> scheduleSilentModeReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required int durationMinutes,
  }) async {
    if (!_initialized) await initialize();

    try {
      if (prayerTime.isBefore(DateTime.now())) return;

      final androidDetails = AndroidNotificationDetails(
        _channelIdSilent,
        'Silent Mode Reminders',
        channelDescription: 'Reminders to enable silent mode during prayer',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'Please put your phone on silent mode for $durationMinutes minutes during $prayerName prayer.',
          contentTitle: '🔇 Silent Mode Reminder',
        ),
      );

      final details = NotificationDetails(android: androidDetails);
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: '🔇 Silent Your Phone',
        body:
            'Put phone on silent for $prayerName prayer ($durationMinutes min)',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'silent_$prayerName',
      );

      debugPrint('✅ Silent reminder scheduled: $prayerName');
    } catch (e) {
      debugPrint('❌ Silent reminder failed: $e');
    }
  }

  // ============================================================
  // CANCEL METHODS
  // ============================================================

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      debugPrint('Cancel all failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPending() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================

  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelIdAzan,
        'Azan Alarms',
        channelDescription: 'Prayer time azan notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(
          '🕌 This is a test notification for QIBRA AI Azan alarms.\nحان وقت الصلاة',
          contentTitle: '🕌 Test Azan Notification',
          summaryText: 'QIBRA AI',
        ),
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id: 99999,
        title: '🕌 Test Azan Notification',
        body: 'QIBRA AI notifications are working perfectly!',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Test failed: $e');
    }
  }
}
