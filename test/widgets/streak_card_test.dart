import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/widgets/streak_card.dart';

void main() {
  testWidgets('StreakCard shows app name, streak, and habit status icons',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final habit = Habit(
      id: 'h1',
      name: 'Fajr',
      icon: 'mosque',
      colorHex: '#5B7C5A',
      frequencyType: FrequencyType.daily,
    );
    final logs = {
      'h1': HabitLog(
        id: 'l1',
        habitId: 'h1',
        date: '2026-07-14',
        completed: true,
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreakCard(
            streakDays: 12,
            date: DateTime(2026, 7, 14),
            dueHabits: [habit],
            todayLogs: logs,
          ),
        ),
      ),
    );

    expect(find.text('Muslim Habit Tracker'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('incomplete habit shows cancel icon', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final habit = Habit(
      id: 'h2',
      name: 'Dhikr',
      icon: 'favorite',
      colorHex: '#8B7355',
      frequencyType: FrequencyType.daily,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreakCard(
            streakDays: 0,
            date: DateTime(2026, 7, 14),
            dueHabits: [habit],
            todayLogs: const {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });
}
