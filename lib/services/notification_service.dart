import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _timeKey = 'notif_time';
  static const _defaultTime = '20:00';

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windows = WindowsInitializationSettings(
      appName: 'Lexivo',
      appUserModelId: 'com.lexivo.app',
      guid: 'a8b9c0d1-e2f3-4a5b-6c7d-8e9f0a1b2c3d',
    );
    const settings = InitializationSettings(android: android, windows: windows);

    await _plugin.initialize(settings: settings);
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static Future<String> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_timeKey) ?? _defaultTime;
  }

  static Future<void> saveTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeKey, time);
  }

  static Future<void> scheduleReminder({
    required String customTime,
    required int streak,
    required String userName,
    required bool enabled,
  }) async {
    await _plugin.cancelAll();
    if (!enabled) return;

    // 1. Morning Motivation — fixed 8:00 AM
    await _plugin.zonedSchedule(
      id: 1,
      title: '📚 Good morning!',
      body: 'Start your day with a few words. A small session now builds big vocabulary later.',
      scheduledDate: _nextInstanceOfTime(8, 0),
      notificationDetails: _details('morning', 'Morning Motivation', 'Daily morning study nudge'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Streak at Risk — fixed 9:00 PM
    final streakTitle = streak > 0
        ? '🔥 Don\'t break your $streak-day streak!'
        : '🔥 Start your streak today!';
    await _plugin.zonedSchedule(
      id: 2,
      title: streakTitle,
      body: 'You haven\'t studied yet today. 5 minutes is all it takes.',
      scheduledDate: _nextInstanceOfTime(21, 0),
      notificationDetails: _details('streak_risk', 'Streak at Risk', 'Evening streak warning'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 3. Custom Reminder — user-chosen time
    final parts = customTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final name = userName.trim().isNotEmpty ? userName.trim() : 'Learner';
    await _plugin.zonedSchedule(
      id: 3,
      title: '📖 Time to study, $name!',
      body: 'Your daily Lexivo session is waiting. A few minutes = a few new words.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _details('custom_reminder', 'Daily Reminder', 'Custom daily study reminder'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static NotificationDetails _details(
      String channelId, String channelName, String desc) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: desc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
