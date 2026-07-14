import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/services/stats_calculator.dart';

void main() {
  test('buildHabitWindowStats uses due days only in the window', () {
    final habit = Habit(
      id: 'fast',
      name: 'Voluntary Fasting',
      icon: 'moon-star',
      colorHex: '#5A6B8C',
      frequencyType: FrequencyType.specificWeekdays,
      weekdays: const [1, 4],
      createdAt: DateTime(2026, 6, 1),
    );

    // Window ending Jul 19: due Mon Jul 13, Thu Jul 16 only in last part
    final logs = [
      HabitLog(id: '1', habitId: 'fast', date: '2026-07-13', completed: true),
      HabitLog(id: '2', habitId: 'fast', date: '2026-07-16', completed: false),
      HabitLog(id: '3', habitId: 'fast', date: '2026-06-15', completed: true),
    ];

    final stats = buildHabitWindowStats(
      habits: [habit],
      allLogs: logs,
      asOf: DateTime(2026, 7, 19),
      windowDays: 7,
    );

    expect(stats, hasLength(1));
    expect(stats.single.totalDueDays, 2); // Mon 13, Thu 16
    expect(stats.single.completedDueDays, 1);
    expect(stats.single.completionRate, 0.5);
    expect(stats.single.lifetimeCompletions, 2); // Jun 15 + Jul 13
  });
}
