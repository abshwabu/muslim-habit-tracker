import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/streak_calculator.dart';

Habit _habit({
  required FrequencyType frequencyType,
  List<int> weekdays = const [],
  DateTime? createdAt,
}) {
  return Habit(
    id: 'h1',
    name: 'Test',
    icon: 'book',
    colorHex: '#3D6B4F',
    frequencyType: frequencyType,
    weekdays: weekdays,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
  );
}

HabitLog _log(String date, {bool completed = true}) {
  return HabitLog(
    id: 'l-$date',
    habitId: 'h1',
    date: date,
    completed: completed,
  );
}

void main() {
  group('frequencyDescription', () {
    test('daily', () {
      expect(
        frequencyDescription(
          _habit(frequencyType: FrequencyType.daily),
        ),
        'Every day',
      );
    });

    test('Monday and Thursday', () {
      expect(
        frequencyDescription(
          _habit(
            frequencyType: FrequencyType.specificWeekdays,
            weekdays: const [1, 4],
          ),
        ),
        'Every Monday and Thursday',
      );
    });
  });

  group('calculateHabitStreak', () {
    test('daily streak counts consecutive due days only', () {
      final habit = _habit(
        frequencyType: FrequencyType.daily,
        createdAt: DateTime(2026, 7, 10),
      );
      final logs = [
        _log('2026-07-12'),
        _log('2026-07-13'),
        _log('2026-07-14'),
      ];

      final streak = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: DateTime(2026, 7, 14),
      );

      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
      expect(streak.lastCompletedDueDate, '2026-07-14');
    });

    test('missed due day breaks current but keeps longest', () {
      final habit = _habit(
        frequencyType: FrequencyType.daily,
        createdAt: DateTime(2026, 7, 10),
      );
      final logs = [
        _log('2026-07-10'),
        _log('2026-07-11'),
        _log('2026-07-12'),
        // 13 missed
        _log('2026-07-14'),
      ];

      final streak = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: DateTime(2026, 7, 14),
      );

      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 3);
    });

    test('Mon/Thu fasting ignores non-due days between completions', () {
      // Week: Mon 13, Tue 14, Wed 15, Thu 16 Jul 2026
      final habit = _habit(
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
        createdAt: DateTime(2026, 7, 13),
      );
      final logs = [
        _log('2026-07-13'), // Mon
        _log('2026-07-16'), // Thu
      ];

      final streak = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: DateTime(2026, 7, 16),
      );

      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 2);
    });

    test('incomplete today does not break current streak', () {
      final habit = _habit(
        frequencyType: FrequencyType.daily,
        createdAt: DateTime(2026, 7, 12),
      );
      final logs = [
        _log('2026-07-12'),
        _log('2026-07-13'),
        // today 14 incomplete
      ];

      final streak = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: DateTime(2026, 7, 14),
      );

      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 2);
      expect(streak.lastCompletedDueDate, '2026-07-13');
    });

    test('incomplete log for past due day is a miss', () {
      final habit = _habit(
        frequencyType: FrequencyType.daily,
        createdAt: DateTime(2026, 7, 13),
      );
      final logs = [
        _log('2026-07-13'),
        _log('2026-07-14', completed: false),
      ];

      final streak = calculateHabitStreak(
        habit: habit,
        logs: logs,
        asOf: DateTime(2026, 7, 14),
      );

      // Today incomplete → skipped; yesterday complete → current 1
      expect(streak.currentStreak, 1);
    });
  });

  test('formatDate helper stays aligned with log keys', () {
    expect(HabitRepository.formatDate(DateTime(2026, 7, 4)), '2026-07-04');
  });
}
