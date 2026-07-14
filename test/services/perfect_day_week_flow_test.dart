import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/models/perfect_day_streak.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/schedule_calculator.dart';
import 'package:muslim_habit_tracker/services/seed_defaults.dart';
import 'package:muslim_habit_tracker/services/streak_calculator.dart';

/// Full Mon → Tue → Wed walkthrough with seeded habits including Mon/Thu fasting.
void main() {
  // Jul 2026: Mon 13, Tue 14, Wed 15
  final monday = DateTime(2026, 7, 13);
  final tuesday = DateTime(2026, 7, 14);
  final wednesday = DateTime(2026, 7, 15);

  late final habits = buildDefaultHabits(createdAt: DateTime(2026, 7, 1));
  late final dailyIds = [
    'seed_quran',
    'seed_dhikr',
    'seed_sadaqah',
    'seed_qiyam',
  ];

  HabitLog done(String habitId, DateTime day) => HabitLog(
        id: '$habitId|${HabitRepository.formatDate(day)}',
        habitId: habitId,
        date: HabitRepository.formatDate(day),
        completed: true,
      );

  Map<String, HabitLog> logsForDay(DateTime day, Iterable<String> habitIds) => {
        for (final id in habitIds) id: done(id, day),
      };

  PerfectDayStreak perfectThrough(
    List<DateTime> perfectDates,
    DateTime asOf,
  ) {
    final eligible = eligiblePerfectDatesInRange(habits, monday, asOf);
    return calculatePerfectDayStreak(
      eligibleDatesAscending: eligible,
      isPerfect: (d) {
        final key = HabitRepository.formatDate(d);
        return perfectDates
            .map(HabitRepository.formatDate)
            .contains(key);
      },
      asOf: asOf,
    );
  }

  test('Monday: all due including fasting → perfect streak 1, fasting streak 1',
      () {
    final dueMon = getDueHabitsForDate(habits, monday);
    expect(dueMon.map((h) => h.id), containsAll([...dailyIds, 'seed_fasting']));

    final logs = logsForDay(monday, dueMon.map((h) => h.id));
    expect(isPerfectDay(dueMon, logs), isTrue);

    final perfect = perfectThrough([monday], monday);
    expect(perfect.currentStreak, 1);

    final fasting = habits.firstWhere((h) => h.id == 'seed_fasting');
    final fastingStreak = calculateHabitStreak(
      habit: fasting,
      logs: [done('seed_fasting', monday)],
      asOf: monday,
    );
    expect(fastingStreak.currentStreak, 1);
  });

  test('Tuesday: daily habits only (fasting not due) still counts perfect day',
      () {
    final dueTue = getDueHabitsForDate(habits, tuesday);
    expect(dueTue.map((h) => h.id), unorderedEquals(dailyIds));
    expect(dueTue.any((h) => h.id == 'seed_fasting'), isFalse);

    final logs = logsForDay(tuesday, dailyIds);
    expect(isPerfectDay(dueTue, logs), isTrue);

    final perfect = perfectThrough([monday, tuesday], tuesday);
    expect(perfect.currentStreak, 2);

    // Fasting wasn't due Tue — streak still reflects Monday only.
    final fasting = habits.firstWhere((h) => h.id == 'seed_fasting');
    final fastingStreak = calculateHabitStreak(
      habit: fasting,
      logs: [done('seed_fasting', monday)],
      asOf: tuesday,
    );
    expect(fastingStreak.currentStreak, 1);
  });

  test(
      'After Wednesday miss (viewed next morning): perfect resets; fasting unchanged',
      () {
    final dueWed = getDueHabitsForDate(habits, wednesday);
    expect(dueWed.map((h) => h.id), unorderedEquals(dailyIds));

    // Complete everything except qiyam on Wednesday.
    final withoutQiyam = dailyIds.where((id) => id != 'seed_qiyam');
    final logs = logsForDay(wednesday, withoutQiyam);
    expect(isPerfectDay(dueWed, logs), isFalse);

    // Streak recompute on Thursday morning: Wednesday is a closed imperfect day.
    final thursday = DateTime(2026, 7, 16);
    final perfect = perfectThrough([monday, tuesday], thursday);
    expect(perfect.currentStreak, 0);
    expect(perfect.longestStreak, greaterThanOrEqualTo(2));

    final fasting = habits.firstWhere((h) => h.id == 'seed_fasting');
    // Thursday is a fasting due day, but we only logged Monday — streak 1.
    final fastingStreak = calculateHabitStreak(
      habit: fasting,
      logs: [done('seed_fasting', monday)],
      asOf: thursday,
    );
    expect(fastingStreak.currentStreak, 1);
    expect(fastingStreak.lastCompletedDueDate, '2026-07-13');
  });
}
