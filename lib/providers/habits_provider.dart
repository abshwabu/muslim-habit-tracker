import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/habit_repository.dart';
import '../services/schedule_calculator.dart';
import '../services/streak_calculator.dart';
import 'habit_repository_provider.dart';
import 'streaks_provider.dart';

/// Active habits only. All habit writes go through this notifier.
class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier(this._ref) : super(const []) {
    refresh();
  }

  final Ref _ref;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  void refresh() {
    final active = _repo.getAllHabits().where((h) => h.isActive).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = active;
  }

  Future<void> addHabit(Habit habit) async {
    await _repo.addHabit(habit);
    refresh();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.updateHabit(habit);
    refresh();
  }

  Future<void> archiveHabit(String habitId) async {
    await _repo.archiveHabit(habitId);
    refresh();
  }

  /// Ensures a log row exists for each habit due today, then refreshes
  /// [todayLogsRevisionProvider] so [todayLogsProvider] rebuilds.
  Future<void> ensureTodayLogs() async {
    final due = getDueHabitsForDate(state, todayDate());
    for (final habit in due) {
      await _repo.getLogForDate(habit.id, todayDate());
    }
    _bumpLogsRevision();
  }

  Future<HabitLog> toggleCompletion(String habitId, {DateTime? date}) async {
    final day = dateOnly(date ?? DateTime.now());
    final habit = _repo.getHabit(habitId);
    final updated = await _repo.toggleCompletion(habitId, day);

    if (habit != null) {
      await _syncHabitStreak(habit, day, completed: updated.completed);
      await _syncPerfectDayStreak(day);
    }

    _bumpLogsRevision();
    return updated;
  }

  Future<void> _syncHabitStreak(
    Habit habit,
    DateTime day, {
    required bool completed,
  }) async {
    if (completed) {
      final current = _repo.getHabitStreak(habit.id);
      final dueDates = dueDatesInRange(habit, habit.createdAt, day);
      final next = updateHabitStreak(habit, current, day, dueDates);
      await _repo.saveHabitStreak(next);
    } else {
      final logs = _repo.getLogsForHabit(habit.id);
      final recomputed = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: todayDate(),
      );
      await _repo.saveHabitStreak(recomputed);
    }
    _ref.read(habitStreaksProvider.notifier).refresh();
  }

  Future<void> _syncPerfectDayStreak(DateTime day) async {
    final due = getDueHabitsForDate(state, day);
    if (due.isEmpty) return; // not eligible — skip, don't break/extend

    final logsForDay = {
      for (final log in _repo.getLogsForDateRange(day, day)) log.habitId: log,
    };

    final start = state.isEmpty
        ? day
        : state
            .map((h) => dateOnlyOf(h.createdAt))
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final eligible = eligiblePerfectDatesInRange(state, start, day);

    if (isPerfectDay(due, logsForDay)) {
      final current = _repo.getPerfectDayStreak();
      final next = updatePerfectDayStreak(current, day, eligible);
      await _repo.savePerfectDayStreak(next);
    } else {
      final recomputed = calculatePerfectDayStreak(
        eligibleDatesAscending: eligiblePerfectDatesInRange(
          state,
          start,
          todayDate(),
        ),
        isPerfect: (d) {
          final dueThatDay = getDueHabitsForDate(state, d);
          if (dueThatDay.isEmpty) return false;
          final logs = {
            for (final log in _repo.getLogsForDateRange(d, d)) log.habitId: log,
          };
          return isPerfectDay(dueThatDay, logs);
        },
        asOf: todayDate(),
      );
      await _repo.savePerfectDayStreak(recomputed);
    }
    _ref.read(perfectDayStreakProvider.notifier).refresh();
  }

  void _bumpLogsRevision() {
    _ref.read(todayLogsRevisionProvider.notifier).state++;
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier(ref);
});

/// Habits due on the current local calendar day.
final dueTodayProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsProvider);
  return getDueHabitsForDate(habits, todayDate());
});

/// Bumped whenever today's logs are written so [todayLogsProvider] re-reads Hive.
final todayLogsRevisionProvider = StateProvider<int>((ref) => 0);

/// Map of habitId → today's [HabitLog] for habits due today.
///
/// Prefer calling [HabitsNotifier.ensureTodayLogs] after load so missing rows
/// are persisted; until then incomplete placeholders may appear.
final todayLogsProvider = Provider<Map<String, HabitLog>>((ref) {
  ref.watch(todayLogsRevisionProvider);
  final due = ref.watch(dueTodayProvider);
  final repo = ref.watch(habitRepositoryProvider);
  final today = todayDate();
  final dateKey = HabitRepository.formatDate(today);

  final existing = {
    for (final log in repo.getLogsForDateRange(today, today)) log.habitId: log,
  };

  return {
    for (final habit in due)
      habit.id: existing[habit.id] ??
          HabitLog(
            id: HabitRepository.logKey(habit.id, dateKey),
            habitId: habit.id,
            date: dateKey,
            completed: false,
          ),
  };
});
