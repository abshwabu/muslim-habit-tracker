import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_log.dart';
import '../services/stats_calculator.dart';
import 'habit_repository_provider.dart';
import 'habits_provider.dart';

/// All logs (any habit), refreshed when completions change.
final allLogsProvider = Provider<List<HabitLog>>((ref) {
  ref.watch(todayLogsRevisionProvider);
  final repo = ref.watch(habitRepositoryProvider);
  final habits = ref.watch(habitsProvider);
  return [
    for (final habit in habits) ...repo.getLogsForHabit(habit.id),
  ];
});

/// Per-habit streaks + 30-day completion rates for the stats screen.
final habitStatsProvider = Provider<List<HabitWindowStats>>((ref) {
  final habits = ref.watch(habitsProvider);
  final logs = ref.watch(allLogsProvider);
  return buildHabitWindowStats(
    habits: habits,
    allLogs: logs,
    asOf: todayDate(),
  );
});
