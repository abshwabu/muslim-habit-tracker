import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_streak.dart';
import '../models/hive_setup.dart';
import '../models/perfect_day_streak.dart';

/// Pure Hive data-access layer. No streak calculation.
class HabitRepository {
  HabitRepository({
    Box<Habit>? habitsBox,
    Box<HabitLog>? logsBox,
    Box<HabitStreak>? streaksBox,
    Box<PerfectDayStreak>? perfectDayBox,
    Uuid? uuid,
  })  : _habits = habitsBox ?? Hive.box<Habit>(HiveBoxes.habits),
        _logs = logsBox ?? Hive.box<HabitLog>(HiveBoxes.habitLogs),
        _streaks = streaksBox ?? Hive.box<HabitStreak>(HiveBoxes.habitStreaks),
        _perfectDay =
            perfectDayBox ??
            Hive.box<PerfectDayStreak>(HiveBoxes.perfectDayStreak),
        _uuid = uuid ?? const Uuid();

  static const String perfectDayKey = 'singleton';

  final Box<Habit> _habits;
  final Box<HabitLog> _logs;
  final Box<HabitStreak> _streaks;
  final Box<PerfectDayStreak> _perfectDay;
  final Uuid _uuid;

  /// Formats [date] as `"yyyy-MM-dd"`.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Deterministic Hive key for a habit+date log.
  static String logKey(String habitId, String date) => '$habitId|$date';

  // --- Habits ---

  List<Habit> getAllHabits() => _habits.values.toList();

  Habit? getHabit(String id) => _habits.get(id);

  Future<void> addHabit(Habit habit) => _habits.put(habit.id, habit);

  Future<void> updateHabit(Habit habit) => _habits.put(habit.id, habit);

  /// Soft-deletes by setting [Habit.isActive] to false.
  ///
  /// Never hard-deletes habits (including those with existing logs).
  Future<void> archiveHabit(String habitId) async {
    final habit = _habits.get(habitId);
    if (habit == null) return;
    await _habits.put(habitId, habit.copyWith(isActive: false));
  }

  // --- Logs ---

  /// Returns the log for [habitId] on [date], creating one with
  /// `completed: false` if none exists yet.
  Future<HabitLog> getLogForDate(String habitId, DateTime date) async {
    final dateKey = formatDate(date);
    final key = logKey(habitId, dateKey);
    final existing = _logs.get(key);
    if (existing != null) return existing;

    final created = HabitLog(
      id: _uuid.v4(),
      habitId: habitId,
      date: dateKey,
      completed: false,
    );
    await _logs.put(key, created);
    return created;
  }

  /// Flips [HabitLog.completed] for [habitId] on [date] and returns the update.
  Future<HabitLog> toggleCompletion(String habitId, DateTime date) async {
    final log = await getLogForDate(habitId, date);
    final updated = log.copyWith(completed: !log.completed);
    await _logs.put(logKey(habitId, log.date), updated);
    return updated;
  }

  /// Logs whose date falls within `[start, end]` inclusive (`yyyy-MM-dd`).
  List<HabitLog> getLogsForDateRange(DateTime start, DateTime end) {
    final startKey = formatDate(start);
    final endKey = formatDate(end);
    return _logs.values
        .where(
          (log) =>
              log.date.compareTo(startKey) >= 0 &&
              log.date.compareTo(endKey) <= 0,
        )
        .toList();
  }

  // --- Habit streaks (storage only) ---

  /// Returns the stored streak, or a zeroed streak if none exists yet.
  HabitStreak getHabitStreak(String habitId) {
    return _streaks.get(habitId) ?? HabitStreak(habitId: habitId);
  }

  Future<void> saveHabitStreak(HabitStreak streak) {
    return _streaks.put(streak.habitId, streak);
  }

  // --- Perfect-day streak (storage only) ---

  /// Returns the stored perfect-day streak, or zeros if none exists yet.
  PerfectDayStreak getPerfectDayStreak() {
    return _perfectDay.get(perfectDayKey) ?? PerfectDayStreak();
  }

  Future<void> savePerfectDayStreak(PerfectDayStreak streak) {
    return _perfectDay.put(perfectDayKey, streak);
  }
}
