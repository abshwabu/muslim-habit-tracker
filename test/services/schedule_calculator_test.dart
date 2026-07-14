import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/services/schedule_calculator.dart';

Habit _habit({
  required String id,
  required FrequencyType frequencyType,
  List<int> weekdays = const [],
  bool isActive = true,
}) {
  return Habit(
    id: id,
    name: id,
    icon: 'prayer',
    colorHex: '#5B7C5A',
    frequencyType: frequencyType,
    weekdays: weekdays,
    isActive: isActive,
  );
}

/// Fixed Mon–Sun week: 2026-07-13 (Mon) … 2026-07-19 (Sun).
List<DateTime> get _testWeek {
  return List.generate(
    7,
    (i) => DateTime(2026, 7, 13 + i),
  );
}

void main() {
  group('isDueOn', () {
    test('daily habit is due every day of the week', () {
      final habit = _habit(
        id: 'daily_dhikr',
        frequencyType: FrequencyType.daily,
      );

      for (final day in _testWeek) {
        expect(
          isDueOn(habit, day),
          isTrue,
          reason: 'daily habit should be due on ${day.weekday}',
        );
      }
    });

    test('Monday/Thursday habit is due on exactly 2 of 7 days', () {
      // Mon=1, Thu=4 — classic Sunnah fasting days.
      final habit = _habit(
        id: 'fasting',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
      );

      final dueDays = _testWeek.where((d) => isDueOn(habit, d)).toList();

      expect(dueDays, hasLength(2));
      expect(dueDays.map((d) => d.weekday), [1, 4]);

      for (final day in _testWeek) {
        final expected = day.weekday == 1 || day.weekday == 4;
        expect(
          isDueOn(habit, day),
          expected,
          reason: 'weekday ${day.weekday} expected due=$expected',
        );
      }
    });

    test('specificWeekdays with empty weekdays is never due', () {
      final habit = _habit(
        id: 'empty',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [],
      );

      for (final day in _testWeek) {
        expect(isDueOn(habit, day), isFalse);
      }
    });

    test('DateTime.weekday matches Habit weekdays convention (1=Mon..7=Sun)', () {
      expect(DateTime(2026, 7, 13).weekday, 1); // Mon
      expect(DateTime(2026, 7, 19).weekday, 7); // Sun

      final sundayOnly = _habit(
        id: 'sunday',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [7],
      );

      expect(isDueOn(sundayOnly, DateTime(2026, 7, 19)), isTrue);
      expect(isDueOn(sundayOnly, DateTime(2026, 7, 13)), isFalse);
    });
  });

  group('getDueHabitsForDate', () {
    test('includes only active habits that are due', () {
      final daily = _habit(
        id: 'daily',
        frequencyType: FrequencyType.daily,
      );
      final monThu = _habit(
        id: 'fasting',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
      );
      final inactiveDaily = _habit(
        id: 'inactive_daily',
        frequencyType: FrequencyType.daily,
        isActive: false,
      );
      final inactiveMonThu = _habit(
        id: 'inactive_fasting',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
        isActive: false,
      );

      final habits = [daily, monThu, inactiveDaily, inactiveMonThu];
      final monday = DateTime(2026, 7, 13);
      final tuesday = DateTime(2026, 7, 14);

      final mondayDue = getDueHabitsForDate(habits, monday);
      expect(mondayDue.map((h) => h.id), ['daily', 'fasting']);

      final tuesdayDue = getDueHabitsForDate(habits, tuesday);
      expect(tuesdayDue.map((h) => h.id), ['daily']);
    });

    test('inactive habit is never returned regardless of frequency', () {
      final inactiveDaily = _habit(
        id: 'inactive_daily',
        frequencyType: FrequencyType.daily,
        isActive: false,
      );
      final inactiveWeekdays = _habit(
        id: 'inactive_weekdays',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: false,
      );

      for (final day in _testWeek) {
        expect(
          getDueHabitsForDate([inactiveDaily, inactiveWeekdays], day),
          isEmpty,
          reason: 'inactive habits must not be due on $day',
        );
      }
    });

    test('isDueOn ignores isActive so callers can reason about schedule alone', () {
      final inactive = _habit(
        id: 'paused',
        frequencyType: FrequencyType.daily,
        isActive: false,
      );

      // Schedule logic itself is independent of active flag.
      expect(isDueOn(inactive, DateTime(2026, 7, 13)), isTrue);
      // Filtering for due + active excludes it.
      expect(getDueHabitsForDate([inactive], DateTime(2026, 7, 13)), isEmpty);
    });
  });
}
