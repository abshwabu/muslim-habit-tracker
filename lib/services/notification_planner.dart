import '../models/frequency_type.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

/// Notification ids reserved by this app (local only).
abstract final class ReminderIds {
  static const evening = 1001;
  static const fastingMonday = 1002;
  static const fastingThursday = 1003;
}

class EveningReminderPlan {
  const EveningReminderPlan({
    required this.incompleteCount,
    required this.dueCount,
  });

  final int incompleteCount;
  final int dueCount;

  String get body =>
      '$incompleteCount of $dueCount today\'s habits left — keep the streak alive';
}

class FastingMorningPlan {
  const FastingMorningPlan({
    required this.weekday,
    required this.notificationId,
    required this.title,
    required this.body,
  });

  /// Dart weekday: 1=Mon, 4=Thu.
  final int weekday;
  final int notificationId;
  final String title;
  final String body;
}

/// Sunnah Mon/Thu fasting (seed or custom Mon/Thu-only habits).
bool isSunnahFastingHabit(Habit habit) {
  if (!habit.isActive) return false;
  if (habit.id == 'seed_fasting') return true;
  if (habit.frequencyType != FrequencyType.specificWeekdays) return false;
  final days = habit.weekdays.toSet();
  return days.isNotEmpty && days.every((d) => d == DateTime.monday || d == DateTime.thursday);
}

/// Evening reminder only when at least one due habit is still incomplete.
EveningReminderPlan? planEveningReminder({
  required List<Habit> dueToday,
  required Map<String, HabitLog> todayLogs,
}) {
  if (dueToday.isEmpty) return null;

  final incomplete = dueToday.where((h) {
    return todayLogs[h.id]?.completed != true;
  }).length;

  if (incomplete == 0) return null;

  return EveningReminderPlan(
    incompleteCount: incomplete,
    dueCount: dueToday.length,
  );
}

/// Morning fasting nudges only on weekdays the fasting habit is due.
List<FastingMorningPlan> planFastingMorningReminders({
  required List<Habit> activeHabits,
}) {
  final fastingHabits =
      activeHabits.where(isSunnahFastingHabit).toList(growable: false);
  if (fastingHabits.isEmpty) return const [];

  final weekdays = <int>{};
  for (final habit in fastingHabits) {
    for (final day in habit.weekdays) {
      if (day == DateTime.monday || day == DateTime.thursday) {
        weekdays.add(day);
      }
    }
  }

  return [
    for (final day in weekdays.toList()..sort())
      FastingMorningPlan(
        weekday: day,
        notificationId: day == DateTime.monday
            ? ReminderIds.fastingMonday
            : ReminderIds.fastingThursday,
        title: day == DateTime.monday
            ? 'Monday fasting'
            : 'Thursday fasting',
        body: day == DateTime.monday
            ? 'Sunnah fast today — set your intention this morning'
            : 'Sunnah fast today — set your intention this morning',
      ),
  ];
}
