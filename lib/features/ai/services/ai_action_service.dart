// lib/features/ai/services/ai_action_service.dart

// ============================================================
// QIBRA AI — AI ACTION SERVICE
// AI ke commands execute karta hai app mein
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/app_constants.dart';

// ============================================================
// ACTION RESULT MODEL
// ============================================================

class ActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const ActionResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory ActionResult.success(String message, [Map<String, dynamic>? data]) {
    return ActionResult(success: true, message: message, data: data);
  }

  factory ActionResult.error(String message) {
    return ActionResult(success: false, message: message);
  }
}

// ============================================================
// AI ACTION SERVICE — Singleton
// ============================================================

class AIActionService {
  static final AIActionService _instance = AIActionService._internal();
  factory AIActionService() => _instance;
  AIActionService._internal();

  BuildContext? _context;

  // Context set karo (screen se)
  void setContext(BuildContext context) {
    _context = context;
  }

  // ============================================================
  // MAIN EXECUTOR — AI ke JSON command ko execute karta hai
  // ============================================================
  Future<ActionResult> executeAction(Map<String, dynamic> action) async {
    try {
      final actionType = action['action'] as String?;
      final params = action['params'] as Map<String, dynamic>? ?? {};

      if (actionType == null) {
        return ActionResult.error('No action specified');
      }

      // Route to specific handler
      switch (actionType) {
        // ─── NOTIFICATION ACTIONS ─────────────────
        case 'SET_TAHAJJUD_ALARM':
          return await _setTahajjudAlarm(params);
        case 'SET_MORNING_ADHKAR':
          return await _setMorningAdhkar(params);
        case 'SET_EVENING_ADHKAR':
          return await _setEveningAdhkar(params);
        case 'SET_JUMMAH_REMINDER':
          return await _setJummahReminder();
        case 'CANCEL_ALL_NOTIFICATIONS':
          return await _cancelAllNotifications();
        case 'TEST_NOTIFICATION':
          return await _testNotification();

        // ─── NAVIGATION ACTIONS ───────────────────
        case 'OPEN_QURAN':
          return _navigate(AppRoutes.quran);
        case 'OPEN_PRAYER':
          return _navigate(AppRoutes.prayer);
        case 'OPEN_QIBLA':
          return _navigate(AppRoutes.qibla);
        case 'OPEN_HADITH':
          return _navigate(AppRoutes.hadith);
        case 'OPEN_TASBIH':
          return _navigate(AppRoutes.tasbih);
        // case 'OPEN_ZAKAT':
//   return _navigate(AppRoutes.zakat);
// case 'OPEN_INHERITANCE':
//   return _navigate(AppRoutes.inheritance);
// case 'OPEN_HABITS':
//   return _navigate(AppRoutes.habits);
        case 'OPEN_SETTINGS':
          return _navigate(AppRoutes.settings);
        case 'OPEN_HOME':
          return _navigate(AppRoutes.home);

        // ─── UNKNOWN ─────────────────────────────
        default:
          return ActionResult.error('Unknown action: $actionType');
      }
    } catch (e) {
      return ActionResult.error('Action failed: ${e.toString()}');
    }
  }

  // ============================================================
  // NOTIFICATION ACTIONS
  // ============================================================

  Future<ActionResult> _setTahajjudAlarm(Map<String, dynamic> params) async {
    try {
      // Time parse karo — "02:00" ya "2:00" format
      final timeStr = params['time'] as String? ?? '02:30';
      final parts = timeStr.split(':');
      if (parts.length != 2) {
        return ActionResult.error('Invalid time format. Use HH:MM');
      }

      final hour = int.tryParse(parts[0]) ?? 2;
      final minute = int.tryParse(parts[1]) ?? 30;

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return ActionResult.error('Invalid time');
      }

      // Notification schedule karo
      await NotificationService.instance.scheduleTahajjudReminder(
        hour: hour,
        minute: minute,
      );

      final displayTime = _formatTime(hour, minute);
      return ActionResult.success(
        'Tahajjud alarm $displayTime ke liye set kar diya',
        {'time': displayTime, 'hour': hour, 'minute': minute},
      );
    } catch (e) {
      return ActionResult.error('Alarm set nahi ho saka: $e');
    }
  }

  Future<ActionResult> _setMorningAdhkar(Map<String, dynamic> params) async {
    try {
      await NotificationService.instance.scheduleMorningAdhkar();
      return ActionResult.success(
          'Morning Adhkar reminder set ho gaya (7:00 AM)');
    } catch (e) {
      return ActionResult.error('Failed: $e');
    }
  }

  Future<ActionResult> _setEveningAdhkar(Map<String, dynamic> params) async {
    try {
      await NotificationService.instance.scheduleEveningAdhkar();
      return ActionResult.success(
          'Evening Adhkar reminder set ho gaya (5:30 PM)');
    } catch (e) {
      return ActionResult.error('Failed: $e');
    }
  }

  Future<ActionResult> _setJummahReminder() async {
    try {
      await NotificationService.instance.scheduleJummahReminder();
      return ActionResult.success(
          'Jummah reminder set ho gaya (Friday 11:30 AM)');
    } catch (e) {
      return ActionResult.error('Failed: $e');
    }
  }

  Future<ActionResult> _cancelAllNotifications() async {
    try {
      await NotificationService.instance.cancelAllNotifications();
      return ActionResult.success('Saari notifications cancel kar di');
    } catch (e) {
      return ActionResult.error('Failed: $e');
    }
  }

  Future<ActionResult> _testNotification() async {
    try {
      await NotificationService.instance.showInstantNotification(
        title: 'Test Notification',
        body: 'Qibra AI se test — sab kaam kar raha hai!',
      );
      return ActionResult.success('Test notification bhej diya');
    } catch (e) {
      return ActionResult.error('Failed: $e');
    }
  }

  // ============================================================
  // NAVIGATION ACTIONS
  // ============================================================

  ActionResult _navigate(String route) {
    if (_context == null) {
      return ActionResult.error('Cannot navigate right now');
    }

    try {
      _context!.go(route);
      return ActionResult.success('Screen open kar diya');
    } catch (e) {
      return ActionResult.error('Navigation failed: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
