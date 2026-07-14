import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_streak.dart';
import '../services/habit_repository.dart';
import '../services/streak_calculator.dart';

/// Completion window used by [StatsScreen] rate bars.
const int kStatsWindowDays = 30;

class HabitWindowStats {
  const HabitWindowStats({
    required this.habit,
    required this.streak,
    required this.completedDueDays,
    required this.totalDueDays,
    required this.lifetimeCompletions,
  });

  final Habit habit;
  final HabitStreak streak;
  final int completedDueDays;
  final int totalDueDays;

  /// All-time completed log count for overall totals.
  final int lifetimeCompletions;

  double get completionRate =>
      totalDueDays == 0 ? 0.0 : completedDueDays / totalDueDays;
}

/// Builds per-habit stats for [habits] over the last [windowDays] ending [asOf].
List<HabitWindowStats> buildHabitWindowStats({
  required List<Habit> habits,
  required List<HabitLog> allLogs,
  required DateTime asOf,
  int windowDays = kStatsWindowDays,
}) {
  final end = dateOnlyOf(asOf);
  final start = end.subtract(Duration(days: windowDays - 1));

  final logsByHabit = <String, List<HabitLog>>{};
  for (final log in allLogs) {
    logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
  }

  final result = <HabitWindowStats>[];
  for (final habit in habits) {
    final logs = logsByHabit[habit.id] ?? const <HabitLog>[];
    final completedKeys = {
      for (final log in logs)
        if (log.completed) log.date,
    };
    final due = dueDatesInRange(habit, start, end);
    final completedInWindow = due
        .where((d) => completedKeys.contains(HabitRepository.formatDate(d)))
        .length;
    final streak = calculateHabitStreak(
      habit: habit,
      logs: logs,
      asOf: end,
    );
    result.add(
      HabitWindowStats(
        habit: habit,
        streak: streak,
        completedDueDays: completedInWindow,
        totalDueDays: due.length,
        lifetimeCompletions: completedKeys.length,
      ),
    );
  }
  return result;
}
