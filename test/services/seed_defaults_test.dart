import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:muslim_habit_tracker/models/frequency_type.dart';
import 'package:muslim_habit_tracker/models/habit.dart';
import 'package:muslim_habit_tracker/models/habit_log.dart';
import 'package:muslim_habit_tracker/models/habit_streak.dart';
import 'package:muslim_habit_tracker/models/hive_setup.dart';
import 'package:muslim_habit_tracker/models/perfect_day_streak.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/services/seed_defaults.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;
  late Box settings;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('seed_defaults_test_');
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
    settings = await Hive.openBox(HiveBoxes.settings);

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
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seeds five defaults once and sets hasSeeded', () async {
    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);

    final habits = repo.getAllHabits();
    expect(habits, hasLength(5));
    expect(habits.every((h) => h.isCustom == false), isTrue);
    expect(habits.every((h) => h.isActive), isTrue);
    expect(settings.get(hasSeededKey), isTrue);

    expect(
      habits.map((h) => h.name),
      containsAll([
        "Qur'an Reading",
        'Dhikr',
        'Sadaqah',
        'Voluntary Fasting',
        'Night Prayer (Qiyam)',
      ]),
    );

    final fasting = habits.firstWhere((h) => h.id == 'seed_fasting');
    expect(fasting.frequencyType, FrequencyType.specificWeekdays);
    expect(fasting.weekdays, [1, 4]);
    expect(fasting.icon, 'moon-star');

    final colors = habits.map((h) => h.colorHex).toSet();
    expect(colors, hasLength(5));
  });

  test('does not re-seed on second launch', () async {
    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);
    await repo.archiveHabit('seed_dhikr');

    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);

    expect(repo.getAllHabits(), hasLength(5));
    expect(repo.getHabit('seed_dhikr')!.isActive, isFalse);
  });
}
