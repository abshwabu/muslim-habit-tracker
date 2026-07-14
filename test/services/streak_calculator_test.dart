import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/models/habit_streak.dart';
import 'package:muslim_habit_tracker/models/perfect_day_streak.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/streak_calculator.dart';

Habit _habit({
  required String id,
  required FrequencyType frequencyType,
  List<int> weekdays = const [],
  DateTime? createdAt,
}) {
  return Habit(
    id: id,
    name: id,
    icon: 'book',
    colorHex: '#3D6B4F',
    frequencyType: frequencyType,
    weekdays: weekdays,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
  );
}

HabitLog _log(
  String habitId,
  String date, {
  bool completed = true,
}) {
  return HabitLog(
    id: '$habitId|$date',
    habitId: habitId,
    date: date,
    completed: completed,
  );
}

void main() {
  group('frequencyDescription', () {
    test('Monday and Thursday', () {
      expect(
        frequencyDescription(
          _habit(
            id: 'fast',
            frequencyType: FrequencyType.specificWeekdays,
            weekdays: const [1, 4],
          ),
        ),
        'Every Monday and Thursday',
      );
    });
  });

  group('updateHabitStreak — Mon/Thu fasting', () {
    // Jul 2026: Mon 13, Thu 16, Mon 20, Thu 23
    late Habit fasting;
    late List<DateTime> dueDates;

    setUp(() {
      fasting = _habit(
        id: 'fast',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
        createdAt: DateTime(2026, 7, 13),
      );
      dueDates = dueDatesInRange(
        fasting,
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 31),
      );
      expect(
        dueDates.map(HabitRepository.formatDate).take(4).toList(),
        ['2026-07-13', '2026-07-16', '2026-07-20', '2026-07-23'],
      );
    });

    test('complete Monday, skip Tue/Wed (not due), complete Thursday → streak 2',
        () {
      var streak = HabitStreak(habitId: fasting.id);

      streak = updateHabitStreak(
        fasting,
        streak,
        DateTime(2026, 7, 13), // Mon
        dueDates,
      );
      expect(streak.currentStreak, 1);
      expect(streak.lastCompletedDueDate, '2026-07-13');

      // Tue 14 / Wed 15 are not due — never passed to updateHabitStreak.

      streak = updateHabitStreak(
        fasting,
        streak,
        DateTime(2026, 7, 16), // Thu
        dueDates,
      );
      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 2);
      expect(streak.lastCompletedDueDate, '2026-07-16');
    });

    test('complete Monday, MISS Thursday, complete next Monday → streak 1', () {
      var streak = HabitStreak(habitId: fasting.id);

      streak = updateHabitStreak(
        fasting,
        streak,
        DateTime(2026, 7, 13), // Mon
        dueDates,
      );
      expect(streak.currentStreak, 1);

      // Thursday 16 missed — no updateHabitStreak call.

      streak = updateHabitStreak(
        fasting,
        streak,
        DateTime(2026, 7, 20), // next Mon
        dueDates,
      );
      // Previous due date is Thu 16, but lastCompleted was Mon 13 ≠ Thu → reset.
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
      expect(streak.lastCompletedDueDate, '2026-07-20');
    });
  });

  group('isPerfectDay', () {
    test('true only when every due habit is completed', () {
      final a = _habit(id: 'a', frequencyType: FrequencyType.daily);
      final b = _habit(id: 'b', frequencyType: FrequencyType.daily);
      expect(
        isPerfectDay(
          [a, b],
          {
            'a': _log('a', '2026-07-14'),
            'b': _log('b', '2026-07-14'),
          },
        ),
        isTrue,
      );
      expect(
        isPerfectDay(
          [a, b],
          {
            'a': _log('a', '2026-07-14'),
            'b': _log('b', '2026-07-14', completed: false),
          },
        ),
        isFalse,
      );
    });

    test('empty dueHabits is not a perfect day', () {
      expect(isPerfectDay([], {}), isFalse);
    });
  });

  group('updatePerfectDayStreak', () {
    test('skips ineligible days between perfect days', () {
      // Eligible Mon + Thu only (simulate days that had due habits).
      final eligible = [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
        DateTime(2026, 7, 20),
      ];
      var streak = PerfectDayStreak();

      streak = updatePerfectDayStreak(
        streak,
        DateTime(2026, 7, 13),
        eligible,
      );
      expect(streak.currentStreak, 1);

      // Tue/Wed not in eligible → not passed in.

      streak = updatePerfectDayStreak(
        streak,
        DateTime(2026, 7, 16),
        eligible,
      );
      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 2);
    });

    test('missed eligible day resets streak', () {
      final eligible = [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 16),
        DateTime(2026, 7, 20),
      ];
      var streak = PerfectDayStreak();
      streak = updatePerfectDayStreak(streak, DateTime(2026, 7, 13), eligible);
      // miss 16
      streak = updatePerfectDayStreak(streak, DateTime(2026, 7, 20), eligible);
      expect(streak.currentStreak, 1);
    });
  });

  group('calculateHabitStreak', () {
    test('still recomputes Mon/Thu fasting streak from logs', () {
      final habit = _habit(
        id: 'fast',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
        createdAt: DateTime(2026, 7, 13),
      );
      final streak = calculateHabitStreak(
        habit: habit,
        logs: [
          _log('fast', '2026-07-13'),
          _log('fast', '2026-07-16'),
        ],
        asOf: DateTime(2026, 7, 16),
      );
      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 2);
    });
  });
}
