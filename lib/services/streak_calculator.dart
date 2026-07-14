import '../models/frequency_type.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_streak.dart';
import '../services/habit_repository.dart';
import 'schedule_calculator.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Human-readable frequency, e.g. `"Every Monday and Thursday"`.
String frequencyDescription(Habit habit) {
  switch (habit.frequencyType) {
    case FrequencyType.daily:
      return 'Every day';
    case FrequencyType.specificWeekdays:
      final names = (List<int>.from(habit.weekdays)..sort())
          .map(_weekdayName)
          .toList();
      if (names.isEmpty) return 'No weekdays selected';
      if (names.length == 1) return 'Every ${names.first}';
      if (names.length == 2) {
        return 'Every ${names[0]} and ${names[1]}';
      }
      final head = names.sublist(0, names.length - 1).join(', ');
      return 'Every $head, and ${names.last}';
  }
}

String _weekdayName(int weekday) {
  const names = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };
  return names[weekday] ?? 'Day $weekday';
}

/// Computes streak for [habit] using only due days ([isDueOn]).
///
/// - Non-due days never break or extend a streak.
/// - An incomplete **today** (if due) is ignored for the current streak
///   (day not over yet); a missed past due day resets current to 0.
HabitStreak calculateHabitStreak({
  required Habit habit,
  required Iterable<HabitLog> logs,
  DateTime? asOf,
}) {
  final today = _dateOnly(asOf ?? DateTime.now());
  final start = _dateOnly(habit.createdAt);
  final completed = {
    for (final log in logs)
      if (log.habitId == habit.id && log.completed) log.date,
  };

  final dueDays = <DateTime>[];
  for (var d = start;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))) {
    if (isDueOn(habit, d)) dueDays.add(d);
  }

  var longest = 0;
  var run = 0;
  for (final day in dueDays) {
    final key = HabitRepository.formatDate(day);
    if (completed.contains(key)) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  var current = 0;
  String? lastCompletedDueDate;
  for (var i = dueDays.length - 1; i >= 0; i--) {
    final day = dueDays[i];
    final key = HabitRepository.formatDate(day);
    final isToday = day == today;
    final done = completed.contains(key);

    if (isToday && !done) {
      // Today is still open — skip without breaking.
      continue;
    }
    if (!done) break;
    current++;
    lastCompletedDueDate ??= key;
  }

  return HabitStreak(
    habitId: habit.id,
    currentStreak: current,
    longestStreak: longest > current ? longest : current,
    lastCompletedDueDate: lastCompletedDueDate,
  );
}
