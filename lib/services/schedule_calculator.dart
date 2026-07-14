import '../models/frequency_type.dart';
import '../models/habit.dart';

/// Returns whether [habit] is scheduled to be done on [date].
///
/// Ignores [Habit.isActive] — callers that need active-only habits should use
/// [getDueHabitsForDate] or filter separately.
bool isDueOn(Habit habit, DateTime date) {
  switch (habit.frequencyType) {
    case FrequencyType.daily:
      return true;
    case FrequencyType.specificWeekdays:
      return habit.weekdays.contains(date.weekday);
  }
}

/// Active habits that are due on [date].
List<Habit> getDueHabitsForDate(List<Habit> habits, DateTime date) {
  return habits
      .where((habit) => habit.isActive && isDueOn(habit, date))
      .toList();
}
