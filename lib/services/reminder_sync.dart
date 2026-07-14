import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'local_notification_service.dart';
import 'notification_planner.dart';
import 'schedule_calculator.dart';

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService.instance;
});

/// Rebuild local schedules from current habits, logs, and settings.
Future<void> syncHabitReminders(WidgetRef ref) async {
  final service = ref.read(localNotificationServiceProvider);
  final enabled = ref.read(remindersEnabledProvider);
  final minutes = ref.read(eveningReminderMinutesProvider);
  final hour = minutes ~/ 60;
  final minute = minutes % 60;

  final habits = ref.read(habitsProvider);
  final today = todayDate();
  final due = getDueHabitsForDate(habits, today);
  final repo = ref.read(habitRepositoryProvider);
  final logs = {
    for (final log in repo.getLogsForDateRange(today, today)) log.habitId: log,
  };

  final evening = planEveningReminder(dueToday: due, todayLogs: logs);
  final fasting = planFastingMorningReminders(activeHabits: habits);

  await service.syncSchedules(
    enabled: enabled,
    eveningHour: hour,
    eveningMinute: minute,
    evening: evening,
    fasting: fasting,
  );
}
