import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_streak.dart';
import '../services/streak_calculator.dart';
import 'habit_repository_provider.dart';
import 'habits_provider.dart';

/// Logs for one habit, newest first. Rebuilds when completions change.
final habitLogsProvider =
    Provider.family<List<HabitLog>, String>((ref, habitId) {
  ref.watch(todayLogsRevisionProvider);
  final logs =
      ref.watch(habitRepositoryProvider).getLogsForHabit(habitId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  return logs;
});

/// Live streak for one habit (due days only).
final habitComputedStreakProvider =
    Provider.family<HabitStreak, String>((ref, habitId) {
  ref.watch(todayLogsRevisionProvider);
  final repo = ref.watch(habitRepositoryProvider);
  final habit = repo.getHabit(habitId);
  if (habit == null) {
    return HabitStreak(habitId: habitId);
  }
  final logs = ref.watch(habitLogsProvider(habitId));
  return calculateHabitStreak(habit: habit, logs: logs);
});

/// Resolves a habit by id from the repository (includes archived).
final habitByIdProvider = Provider.family<Habit?, String>((ref, habitId) {
  ref.watch(habitsProvider); // rebuild when active list changes
  return ref.watch(habitRepositoryProvider).getHabit(habitId);
});
