import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/services/notification_planner.dart';

Habit _habit({
  required String id,
  required FrequencyType frequencyType,
  List<int> weekdays = const [],
  bool isActive = true,
}) {
  return Habit(
    id: id,
    name: id,
    icon: 'book',
    colorHex: '#3D6B4F',
    frequencyType: frequencyType,
    weekdays: weekdays,
    isActive: isActive,
  );
}

void main() {
  group('planEveningReminder', () {
    test('returns null when all due habits are complete', () {
      final due = [
        _habit(id: 'a', frequencyType: FrequencyType.daily),
        _habit(id: 'b', frequencyType: FrequencyType.daily),
      ];
      final logs = {
        'a': HabitLog(id: '1', habitId: 'a', date: '2026-07-14', completed: true),
        'b': HabitLog(id: '2', habitId: 'b', date: '2026-07-14', completed: true),
      };

      expect(planEveningReminder(dueToday: due, todayLogs: logs), isNull);
    });

    test('builds Y of Z body for incomplete habits', () {
      final due = [
        _habit(id: 'a', frequencyType: FrequencyType.daily),
        _habit(id: 'b', frequencyType: FrequencyType.daily),
        _habit(id: 'c', frequencyType: FrequencyType.daily),
      ];
      final logs = {
        'a': HabitLog(id: '1', habitId: 'a', date: '2026-07-14', completed: true),
      };

      final plan = planEveningReminder(dueToday: due, todayLogs: logs);
      expect(plan, isNotNull);
      expect(plan!.incompleteCount, 2);
      expect(plan.dueCount, 3);
      expect(
        plan.body,
        "2 of 3 today's habits left — keep the streak alive",
      );
    });

    test('returns null when nothing is due', () {
      expect(
        planEveningReminder(dueToday: const [], todayLogs: const {}),
        isNull,
      );
    });
  });

  group('planFastingMorningReminders', () {
    test('plans Mon and Thu for seed fasting habit only', () {
      final habits = [
        _habit(id: 'seed_quran', frequencyType: FrequencyType.daily),
        _habit(
          id: 'seed_fasting',
          frequencyType: FrequencyType.specificWeekdays,
          weekdays: const [1, 4],
        ),
      ];

      final plans = planFastingMorningReminders(activeHabits: habits);
      expect(plans.map((p) => p.weekday), [1, 4]);
      expect(plans.map((p) => p.notificationId), [
        ReminderIds.fastingMonday,
        ReminderIds.fastingThursday,
      ]);
    });

    test('does not plan fasting nudges for daily habits alone', () {
      final habits = [
        _habit(id: 'seed_quran', frequencyType: FrequencyType.daily),
      ];
      expect(planFastingMorningReminders(activeHabits: habits), isEmpty);
    });

    test('isSunnahFastingHabit matches Mon/Thu-only customs', () {
      final custom = _habit(
        id: 'custom_fast',
        frequencyType: FrequencyType.specificWeekdays,
        weekdays: const [1, 4],
      );
      expect(isSunnahFastingHabit(custom), isTrue);
      expect(
        isSunnahFastingHabit(
          _habit(
            id: 'weekend',
            frequencyType: FrequencyType.specificWeekdays,
            weekdays: const [6, 7],
          ),
        ),
        isFalse,
      );
    });
  });
}
