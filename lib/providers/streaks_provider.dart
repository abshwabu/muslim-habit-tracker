import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/habit_streak.dart';
import '../models/perfect_day_streak.dart';
import '../services/habit_repository.dart';
import 'habit_repository_provider.dart';

/// Per-habit streaks keyed by habitId. Writes via [save].
class HabitStreaksNotifier extends StateNotifier<Map<String, HabitStreak>> {
  HabitStreaksNotifier(this._ref) : super(const {}) {
    refresh();
  }

  final Ref _ref;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  void refresh() {
    final habits = _repo.getAllHabits().where((h) => h.isActive);
    state = {
      for (final habit in habits) habit.id: _repo.getHabitStreak(habit.id),
    };
  }

  Future<void> save(HabitStreak streak) async {
    await _repo.saveHabitStreak(streak);
    state = {...state, streak.habitId: streak};
  }
}

final habitStreaksProvider =
    StateNotifierProvider<HabitStreaksNotifier, Map<String, HabitStreak>>(
  (ref) => HabitStreaksNotifier(ref),
);

/// App-wide perfect-day streak. Writes via [save].
class PerfectDayStreakNotifier extends StateNotifier<PerfectDayStreak> {
  PerfectDayStreakNotifier(this._ref) : super(PerfectDayStreak()) {
    refresh();
  }

  final Ref _ref;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  void refresh() {
    state = _repo.getPerfectDayStreak();
  }

  Future<void> save(PerfectDayStreak streak) async {
    await _repo.savePerfectDayStreak(streak);
    state = streak;
  }
}

final perfectDayStreakProvider =
    StateNotifierProvider<PerfectDayStreakNotifier, PerfectDayStreak>((ref) {
  return PerfectDayStreakNotifier(ref);
});
