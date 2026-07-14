import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/habit_repository.dart';
import '../services/schedule_calculator.dart';
import 'habit_repository_provider.dart';

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
    final updated = await _repo.toggleCompletion(habitId, day);
    _bumpLogsRevision();
    return updated;
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
