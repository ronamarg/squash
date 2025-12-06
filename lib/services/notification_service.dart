import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notification Service for Squash
/// 
/// Handles daily practice reminders and streak warnings.
/// Uses flutter_local_notifications for local scheduling.
/// Persists user preferences with SharedPreferences.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int dailyReminderId = 1;
  static const int streakWarningId = 2;
  static const int levelUpId = 3;

  // Channel IDs
  static const String dailyChannelId = 'daily_practice';
  static const String streakChannelId = 'streak_warnings';
  static const String achievementChannelId = 'achievements';

  // SharedPreferences keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyStreakWarningsEnabled = 'streak_warnings_enabled';
  static const String _keyStreakWarningHour = 'streak_warning_hour';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android only)
    await _createNotificationChannels();

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Daily practice channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        dailyChannelId,
        'Daily Practice Reminders',
        description: 'Reminders to practice your Python skills',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Streak warnings channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        streakChannelId,
        'Streak Warnings',
        description: 'Alerts when your practice streak is at risk',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Achievements channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        achievementChannelId,
        'Achievements',
        description: 'Notifications for badges and level ups',
        importance: Importance.defaultImportance,
        enableVibration: true,
      ),
    );
  }

  /// Callback for handling notification navigation
  static void Function(String? payload)? onNotificationTapped;

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    // Invoke callback if set (allows navigation from main app)
    onNotificationTapped?.call(response.payload);
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Assume granted on other platforms
  }

  // ============================================
  // DAILY PRACTICE REMINDER
  // ============================================

  /// Schedule daily practice reminder at specified time
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      dailyReminderId,
      '🐍 Time to Practice!',
      'Keep your streak going with a quick Python session.',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          dailyChannelId,
          'Daily Practice Reminders',
          channelDescription: 'Reminders to practice your Python skills',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(
            'You have cards due for review. A few minutes of practice helps retain what you\'ve learned!',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint('[NotificationService] Daily reminder scheduled for $hour:$minute');
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(dailyReminderId);
    debugPrint('[NotificationService] Daily reminder cancelled');
  }

  // ============================================
  // STREAK WARNING
  // ============================================

  /// Send immediate streak warning notification
  Future<void> sendStreakWarning(int currentStreak) async {
    await _notifications.show(
      streakWarningId,
      '⚠️ Streak at Risk!',
      'Practice now to maintain your $currentStreak-day streak!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          streakChannelId,
          'Streak Warnings',
          channelDescription: 'Alerts when your practice streak is at risk',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF5722), // Orange warning color
          styleInformation: BigTextStyleInformation(
            'You haven\'t practiced today! Complete just one review to keep your $currentStreak-day streak alive.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'streak_warning',
    );

    debugPrint('[NotificationService] Streak warning sent for $currentStreak-day streak');
  }

  /// Schedule evening streak warning if user hasn't practiced
  Future<void> scheduleStreakWarning({
    required int currentStreak,
    int hour = 20, // 8 PM default
    int minute = 0,
  }) async {
    if (currentStreak == 0) return; // No streak to protect

    await _notifications.zonedSchedule(
      streakWarningId,
      '⚠️ Don\'t Break Your Streak!',
      'You still have time! Practice now to keep your $currentStreak-day streak.',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          streakChannelId,
          'Streak Warnings',
          channelDescription: 'Alerts when your practice streak is at risk',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'streak_warning',
    );
  }

  /// Cancel streak warning (called after user practices)
  Future<void> cancelStreakWarning() async {
    await _notifications.cancel(streakWarningId);
  }

  // ============================================
  // ACHIEVEMENT NOTIFICATIONS
  // ============================================

  /// Send level up notification
  Future<void> sendLevelUpNotification(String newLevel, int level) async {
    final emoji = _getLevelEmoji(newLevel);
    
    await _notifications.show(
      levelUpId,
      '$emoji Level Up!',
      'Congratulations! You\'ve reached $newLevel level!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          achievementChannelId,
          'Achievements',
          channelDescription: 'Notifications for badges and level ups',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50), // Green success color
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'level_up:$newLevel',
    );
  }

  /// Send badge earned notification
  Future<void> sendBadgeNotification(String badgeName, String badgeEmoji) async {
    await _notifications.show(
      100 + badgeName.hashCode % 1000, // Unique ID per badge
      '$badgeEmoji Badge Earned!',
      'You\'ve unlocked the "$badgeName" badge!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          achievementChannelId,
          'Achievements',
          channelDescription: 'Notifications for badges and level ups',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'badge:$badgeName',
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Get next occurrence of specified time (today or tomorrow)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }

  /// Get emoji for skill level
  String _getLevelEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return '🌱';
      case 'novice': return '📚';
      case 'intermediate': return '⭐';
      case 'advanced': return '🚀';
      case 'expert': return '👑';
      default: return '🎉';
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true; // Assume enabled on other platforms
  }

  // ============================================
  // SETTINGS PERSISTENCE
  // ============================================

  /// Get notification settings from SharedPreferences
  Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      notificationsEnabled: prefs.getBool(_keyNotificationsEnabled) ?? true,
      reminderHour: prefs.getInt(_keyReminderHour) ?? 9,
      reminderMinute: prefs.getInt(_keyReminderMinute) ?? 0,
      streakWarningsEnabled: prefs.getBool(_keyStreakWarningsEnabled) ?? true,
      streakWarningHour: prefs.getInt(_keyStreakWarningHour) ?? 20,
    );
  }

  /// Save notification settings
  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, settings.notificationsEnabled);
    await prefs.setInt(_keyReminderHour, settings.reminderHour);
    await prefs.setInt(_keyReminderMinute, settings.reminderMinute);
    await prefs.setBool(_keyStreakWarningsEnabled, settings.streakWarningsEnabled);
    await prefs.setInt(_keyStreakWarningHour, settings.streakWarningHour);

    // Apply settings
    if (settings.notificationsEnabled) {
      await scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      );
    } else {
      await cancelDailyReminder();
    }

    if (!settings.streakWarningsEnabled) {
      await cancelStreakWarning();
    }

    debugPrint('[NotificationService] Settings saved: $settings');
  }

  /// Initialize notifications based on saved settings
  /// Call this on app startup after user is logged in
  Future<void> applyStoredSettings({int? currentStreak}) async {
    final settings = await getSettings();
    
    if (settings.notificationsEnabled) {
      await scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      );
    }

    if (settings.streakWarningsEnabled && currentStreak != null && currentStreak > 0) {
      await scheduleStreakWarning(
        currentStreak: currentStreak,
        hour: settings.streakWarningHour,
      );
    }

    debugPrint('[NotificationService] Applied stored settings');
  }

  /// Called when user completes practice - cancel today\'s streak warning
  Future<void> onPracticeCompleted() async {
    await cancelStreakWarning();
    debugPrint('[NotificationService] Practice completed - streak warning cancelled');
  }
}

/// Notification settings model
class NotificationSettings {
  final bool notificationsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool streakWarningsEnabled;
  final int streakWarningHour;

  const NotificationSettings({
    this.notificationsEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.streakWarningsEnabled = true,
    this.streakWarningHour = 20,
  });

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? streakWarningsEnabled,
    int? streakWarningHour,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      streakWarningsEnabled: streakWarningsEnabled ?? this.streakWarningsEnabled,
      streakWarningHour: streakWarningHour ?? this.streakWarningHour,
    );
  }

  String get reminderTimeFormatted {
    final hour12 = reminderHour > 12 ? reminderHour - 12 : (reminderHour == 0 ? 12 : reminderHour);
    final amPm = reminderHour >= 12 ? 'PM' : 'AM';
    return '$hour12:${reminderMinute.toString().padLeft(2, '0')} $amPm';
  }

  String get streakWarningTimeFormatted {
    final hour12 = streakWarningHour > 12 ? streakWarningHour - 12 : (streakWarningHour == 0 ? 12 : streakWarningHour);
    final amPm = streakWarningHour >= 12 ? 'PM' : 'AM';
    return '$hour12:00 $amPm';
  }

  @override
  String toString() => 'NotificationSettings(enabled: $notificationsEnabled, reminder: $reminderHour:$reminderMinute, streakWarning: $streakWarningHour:00)';
}
