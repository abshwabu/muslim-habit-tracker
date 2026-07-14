import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit_log.dart';
import '../services/habit_repository.dart';
import 'grid_range_provider.dart';
import 'habit_repository_provider.dart';
import 'habits_provider.dart';

/// Last [gridRangeProvider] calendar days, oldest → newest (today last).
final gridDatesProvider = Provider<List<DateTime>>((ref) {
  final n = ref.watch(gridRangeProvider);
  final today = todayDate();
  if (n <= 0) return const [];
  return List<DateTime>.unmodifiable(
    List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i))),
  );
});

/// Logs for the visible grid range, keyed by [HabitRepository.logKey].
final gridLogsProvider = Provider<Map<String, HabitLog>>((ref) {
  ref.watch(todayLogsRevisionProvider);
  final dates = ref.watch(gridDatesProvider);
  final repo = ref.watch(habitRepositoryProvider);
  if (dates.isEmpty) return const {};

  final logs = repo.getLogsForDateRange(dates.first, dates.last);
  return {
    for (final log in logs) HabitRepository.logKey(log.habitId, log.date): log,
  };
});

/// How many of today's due habits are completed.
final todayCompletionCountProvider = Provider<({int done, int total})>((ref) {
  final due = ref.watch(dueTodayProvider);
  final logs = ref.watch(todayLogsProvider);
  final done = due.where((h) => logs[h.id]?.completed == true).length;
  return (done: done, total: due.length);
});
