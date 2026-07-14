import 'dart:io';

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
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/seed_defaults.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('providers_test_');
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

    await habits.clear();
    await logs.clear();
    await streaks.clear();
    await perfect.clear();
    await settings.clear();

    repo = HabitRepository(
      habitsBox: habits,
      logsBox: logs,
      streaksBox: streaks,
      perfectDayBox: perfect,
    );

    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);

    container = ProviderContainer(
      overrides: [
        habitRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('habitsProvider exposes active seeded habits', () {
    final habits = container.read(habitsProvider);
    expect(habits, hasLength(5));
    expect(habits.every((h) => h.isActive), isTrue);
  });

  test('dueTodayProvider includes daily habits and Mon/Thu fasting when due', () {
    final due = container.read(dueTodayProvider);
    final dailyCount = due.where((h) => h.frequencyType == FrequencyType.daily).length;
    expect(dailyCount, 4);

    final fasting = due.where((h) => h.id == 'seed_fasting');
    final weekday = todayDate().weekday;
    if (weekday == 1 || weekday == 4) {
      expect(fasting, hasLength(1));
    } else {
      expect(fasting, isEmpty);
    }
  });

  test('toggleCompletion writes through provider and updates todayLogsProvider',
      () async {
    await container.read(habitsProvider.notifier).ensureTodayLogs();
    final due = container.read(dueTodayProvider);
    expect(due, isNotEmpty);

    final habitId = due.first.id;
    expect(container.read(todayLogsProvider)[habitId]!.completed, isFalse);

    await container.read(habitsProvider.notifier).toggleCompletion(habitId);
    expect(container.read(todayLogsProvider)[habitId]!.completed, isTrue);
  });

  test('archiveHabit removes habit from habitsProvider', () async {
    await container.read(habitsProvider.notifier).archiveHabit('seed_dhikr');
    expect(
      container.read(habitsProvider).any((h) => h.id == 'seed_dhikr'),
      isFalse,
    );
  });

  test('habitStreaksProvider and perfectDayStreakProvider save via notifiers',
      () async {
    await container.read(habitStreaksProvider.notifier).save(
          HabitStreak(habitId: 'seed_quran', currentStreak: 2, longestStreak: 2),
        );
    expect(container.read(habitStreaksProvider)['seed_quran']!.currentStreak, 2);

    await container.read(perfectDayStreakProvider.notifier).save(
          PerfectDayStreak(currentStreak: 1, longestStreak: 1),
        );
    expect(container.read(perfectDayStreakProvider).currentStreak, 1);
  });

  test('gridRangeProvider defaults to 30', () {
    expect(container.read(gridRangeProvider), 30);
    container.read(gridRangeProvider.notifier).state = 14;
    expect(container.read(gridRangeProvider), 14);
  });
}
