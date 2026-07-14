import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_planner.dart';

/// Fully offline local notifications (no push).
class LocalNotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final LocalNotificationService instance = LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';
  static const _channelDescription =
      'Evening incomplete-habit alerts and Mon/Thu fasting nudges';

  /// Fixed morning hour for Sunnah fasting nudges (local time).
  static const fastingMorningHour = 6;
  static const fastingMorningMinute = 0;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Desktop/tests without native timezone — keep default location.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Missing platform implementation (unit tests / unsupported OS).
      _initialized = true;
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {
        // Older Android / unsupported — ignore.
      }
      return granted ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      return await mac.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    try {
      await _plugin.cancel(id: ReminderIds.evening);
      await _plugin.cancel(id: ReminderIds.fastingMonday);
      await _plugin.cancel(id: ReminderIds.fastingThursday);
    } catch (_) {
      // Platform channel unavailable.
    }
  }

  /// Applies evening + fasting schedules, or cancels everything when disabled.
  Future<void> syncSchedules({
    required bool enabled,
    required int eveningHour,
    required int eveningMinute,
    required EveningReminderPlan? evening,
    required List<FastingMorningPlan> fasting,
  }) async {
    await initialize();
    await cancelAllReminders();
    if (!enabled) return;

    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );

      if (evening != null) {
        final when = _nextInstanceOfTime(eveningHour, eveningMinute);
        await _plugin.zonedSchedule(
          id: ReminderIds.evening,
          title: 'Habits left today',
          body: evening.body,
          scheduledDate: when,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              styleInformation: BigTextStyleInformation(evening.body),
            ),
            iOS: const DarwinNotificationDetails(),
            macOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      for (final plan in fasting) {
        final when = _nextInstanceOfWeekdayTime(
          plan.weekday,
          fastingMorningHour,
          fastingMorningMinute,
        );
        await _plugin.zonedSchedule(
          id: plan.notificationId,
          title: plan.title,
          body: plan.body,
          scheduledDate: when,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              styleInformation: BigTextStyleInformation(plan.body),
            ),
            iOS: details.iOS,
            macOS: details.macOS,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      if (kDebugMode) {
        debugPrint(
          'Reminders synced (evening=${evening != null}, fasting=${fasting.length})',
        );
      }
    } catch (_) {
      // Scheduling may fail on unsupported platforms.
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
