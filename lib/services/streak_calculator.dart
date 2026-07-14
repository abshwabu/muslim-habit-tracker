import 'dart:math' as math;

import '../models/frequency_type.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_streak.dart';
import '../models/perfect_day_streak.dart';
import 'habit_repository.dart';
import 'schedule_calculator.dart';

DateTime dateOnlyOf(DateTime d) => DateTime(d.year, d.month, d.day);

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

/// Due dates for [habit] from [start] through [end] inclusive, ascending.
List<DateTime> dueDatesInRange(Habit habit, DateTime start, DateTime end) {
  final from = dateOnlyOf(start);
  final to = dateOnlyOf(end);
  final dates = <DateTime>[];
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    if (isDueOn(habit, d)) dates.add(d);
  }
  return dates;
}

/// Days where at least one active habit is due, ascending.
List<DateTime> eligiblePerfectDatesInRange(
  List<Habit> habits,
  DateTime start,
  DateTime end,
) {
  final from = dateOnlyOf(start);
  final to = dateOnlyOf(end);
  final dates = <DateTime>[];
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    if (getDueHabitsForDate(habits, d).isNotEmpty) dates.add(d);
  }
  return dates;
}

DateTime? _previousDateBefore(List<DateTime> ascendingDates, DateTime date) {
  final day = dateOnlyOf(date);
  DateTime? previous;
  for (final d in ascendingDates) {
    final dd = dateOnlyOf(d);
    if (dd.isBefore(day)) {
      previous = dd;
    } else {
      break;
    }
  }
  return previous;
}

/// Updates streak after a **completion** on [completedDate].
///
/// Uses [allDueDatesInOrder] (ascending) to find the previous *due* date —
/// non-due days are skipped entirely (e.g. Tue/Wed between Mon/Thu fasting).
/// Continues the streak only when that previous due date is
/// [HabitStreak.lastCompletedDueDate]; otherwise resets to 1.
HabitStreak updateHabitStreak(
  Habit habit,
  HabitStreak current,
  DateTime completedDate,
  List<DateTime> allDueDatesInOrder,
) {
  final day = dateOnlyOf(completedDate);
  final dayKey = HabitRepository.formatDate(day);
  final previous = _previousDateBefore(allDueDatesInOrder, day);

  final int newCurrent;
  if (previous == null) {
    newCurrent = 1;
  } else {
    final previousKey = HabitRepository.formatDate(previous);
    if (current.lastCompletedDueDate == previousKey) {
      newCurrent = current.currentStreak + 1;
    } else {
      newCurrent = 1;
    }
  }

  return HabitStreak(
    habitId: habit.id,
    currentStreak: newCurrent,
    longestStreak: math.max(current.longestStreak, newCurrent),
    lastCompletedDueDate: dayKey,
  );
}

/// True only when every habit in [dueHabits] has a completed log that day.
///
/// Empty [dueHabits] is **not** a perfect day (caller should skip streak update).
bool isPerfectDay(
  List<Habit> dueHabits,
  Map<String, HabitLog> logsForThatDay,
) {
  if (dueHabits.isEmpty) return false;
  for (final habit in dueHabits) {
    final log = logsForThatDay[habit.id];
    if (log == null || !log.completed) return false;
  }
  return true;
}

/// Updates the app-wide perfect-day streak after [date] becomes perfect.
///
/// Same consecutive logic as [updateHabitStreak]: the previous *eligible*
/// day (from [allEligibleDatesInOrder]) must equal
/// [PerfectDayStreak.lastPerfectDate]. Days with no due habits are omitted
/// from [allEligibleDatesInOrder] so they neither break nor extend the streak.
PerfectDayStreak updatePerfectDayStreak(
  PerfectDayStreak current,
  DateTime date,
  List<DateTime> allEligibleDatesInOrder,
) {
  final day = dateOnlyOf(date);
  final dayKey = HabitRepository.formatDate(day);
  final previous = _previousDateBefore(allEligibleDatesInOrder, day);

  final int newCurrent;
  if (previous == null) {
    newCurrent = 1;
  } else {
    final previousKey = HabitRepository.formatDate(previous);
    if (current.lastPerfectDate == previousKey) {
      newCurrent = current.currentStreak + 1;
    } else {
      newCurrent = 1;
    }
  }

  return PerfectDayStreak(
    currentStreak: newCurrent,
    longestStreak: math.max(current.longestStreak, newCurrent),
    lastPerfectDate: dayKey,
  );
}

/// Full recompute of a habit streak from logs (due days only).
///
/// Used for display and after un-completing a day.
HabitStreak calculateHabitStreak({
  required Habit habit,
  required Iterable<HabitLog> logs,
  DateTime? asOf,
}) {
  final today = dateOnlyOf(asOf ?? DateTime.now());
  final start = dateOnlyOf(habit.createdAt);
  final completed = {
    for (final log in logs)
      if (log.habitId == habit.id && log.completed) log.date,
  };

  final dueDays = dueDatesInRange(habit, start, today);

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

/// Full recompute of perfect-day streak from [isPerfect] results per eligible day.
PerfectDayStreak calculatePerfectDayStreak({
  required List<DateTime> eligibleDatesAscending,
  required bool Function(DateTime date) isPerfect,
  DateTime? asOf,
}) {
  final today = dateOnlyOf(asOf ?? DateTime.now());
  final dates =
      eligibleDatesAscending.map(dateOnlyOf).where((d) => !d.isAfter(today)).toList();

  var longest = 0;
  var run = 0;
  String? lastPerfect;
  for (final day in dates) {
    if (isPerfect(day)) {
      run++;
      lastPerfect = HabitRepository.formatDate(day);
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  var current = 0;
  String? lastCompleted;
  for (var i = dates.length - 1; i >= 0; i--) {
    final day = dates[i];
    final perfect = isPerfect(day);
    final isToday = day == today;
    if (isToday && !perfect) continue;
    if (!perfect) break;
    current++;
    lastCompleted ??= HabitRepository.formatDate(day);
  }

  return PerfectDayStreak(
    currentStreak: current,
    longestStreak: math.max(longest, current),
    lastPerfectDate: lastCompleted ?? lastPerfect,
  );
}
