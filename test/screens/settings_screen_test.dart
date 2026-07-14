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
import 'package:muslim_habit_tracker/screens/settings_screen.dart';
import 'package:muslim_habit_tracker/services/app_info.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/seed_defaults.dart';
import 'package:muslim_habit_tracker/theme/app_theme.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_screen_test_');
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

  testWidgets('SettingsScreen shows preferences, reset, and about',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Grid range'), findsOneWidget);
    expect(find.text('Week starts on'), findsOneWidget);
    expect(find.text('Reset all data'), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.textContaining('Version'), findsOneWidget);
  });

  test('clearAllHabitData then reseed restores defaults', () async {
    expect(repo.getAllHabits(), isNotEmpty);
    await repo.toggleCompletion(repo.getAllHabits().first.id, DateTime.now());
    expect(repo.getLogsForHabit(repo.getAllHabits().first.id), isNotEmpty);

    await repo.clearAllHabitData();
    expect(repo.getAllHabits(), isEmpty);

    final settings = Hive.box(HiveBoxes.settings);
    await settings.delete(hasSeededKey);
    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);
    expect(repo.getAllHabits().where((h) => h.isActive).length, 5);
  });
}
