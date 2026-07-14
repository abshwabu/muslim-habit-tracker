import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/models/habit_streak.dart';
import 'package:muslim_habit_tracker/models/hive_setup.dart';
import 'package:muslim_habit_tracker/models/perfect_day_streak.dart';
import 'package:muslim_habit_tracker/providers/providers.dart';
import 'package:muslim_habit_tracker/screens/habit_detail_screen.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/seed_defaults.dart';
import 'package:muslim_habit_tracker/theme/app_theme.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habit_detail_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FrequencyTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HabitLogAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HabitStreakAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PerfectDayStreakAdapter());
    }

    final habits = await Hive.openBox<Habit>(HiveBoxes.habits);
    final logs = await Hive.openBox<HabitLog>(HiveBoxes.habitLogs);
    final streaks = await Hive.openBox<HabitStreak>(HiveBoxes.habitStreaks);
    final perfect =
        await Hive.openBox<PerfectDayStreak>(HiveBoxes.perfectDayStreak);
    final settings = await Hive.openBox(HiveBoxes.settings);

    await Future.wait([
      habits.clear(),
      logs.clear(),
      streaks.clear(),
      perfect.clear(),
      settings.clear(),
    ]);

    repo = HabitRepository(
      habitsBox: habits,
      logsBox: logs,
      streaksBox: streaks,
      perfectDayBox: perfect,
    );
    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('HabitDetailScreen shows name, frequency, streaks, actions',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HabitDetailScreen(habitId: 'seed_fasting'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Voluntary Fasting'), findsWidgets);
    expect(find.textContaining('صيام'), findsOneWidget);
    expect(find.text('Every Monday and Thursday'), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Longest streak'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
  });
}
