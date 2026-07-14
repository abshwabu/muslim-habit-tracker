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

void main() {
  late Directory tempDir;
  late HabitRepository repo;

  Habit buildHabit({
    String id = 'h1',
    bool isActive = true,
  }) {
    return Habit(
      id: id,
      name: 'Test Habit',
      icon: 'prayer',
      colorHex: '#5B7C5A',
      frequencyType: FrequencyType.daily,
      isActive: isActive,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habit_repo_test_');
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

    await habits.clear();
    await logs.clear();
    await streaks.clear();
    await perfect.clear();

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

  group('habits', () {
    test('addHabit and getAllHabits round-trip', () async {
      final habit = buildHabit();
      await repo.addHabit(habit);

      expect(repo.getAllHabits(), hasLength(1));
      expect(repo.getAllHabits().first.id, 'h1');
    });

    test('updateHabit replaces stored habit', () async {
      await repo.addHabit(buildHabit());
      await repo.updateHabit(buildHabit().copyWith(name: 'Updated'));

      expect(repo.getAllHabits().single.name, 'Updated');
    });

    test('archiveHabit soft-deletes and keeps habit + logs', () async {
      await repo.addHabit(buildHabit());
      final day = DateTime(2026, 7, 14);
      await repo.toggleCompletion('h1', day);

      await repo.archiveHabit('h1');

      final archived = repo.getAllHabits().single;
      expect(archived.isActive, isFalse);

      final logs = repo.getLogsForDateRange(day, day);
      expect(logs, hasLength(1));
      expect(logs.single.completed, isTrue);
      expect(Hive.box<Habit>(HiveBoxes.habits).containsKey('h1'), isTrue);
    });
  });

  group('logs', () {
    test('getLogForDate creates incomplete log when missing', () async {
      final day = DateTime(2026, 7, 14);
      final log = await repo.getLogForDate('h1', day);

      expect(log.habitId, 'h1');
      expect(log.date, '2026-07-14');
      expect(log.completed, isFalse);

      final again = await repo.getLogForDate('h1', day);
      expect(again.id, log.id);
    });

    test('toggleCompletion flips completed state', () async {
      final day = DateTime(2026, 7, 14);

      final first = await repo.toggleCompletion('h1', day);
      expect(first.completed, isTrue);

      final second = await repo.toggleCompletion('h1', day);
      expect(second.completed, isFalse);
      expect(second.id, first.id);
    });

    test('getLogsForDateRange returns inclusive range only', () async {
      await repo.toggleCompletion('h1', DateTime(2026, 7, 13));
      await repo.toggleCompletion('h1', DateTime(2026, 7, 14));
      await repo.toggleCompletion('h1', DateTime(2026, 7, 15));
      await repo.toggleCompletion('h1', DateTime(2026, 7, 20));

      final logs = repo.getLogsForDateRange(
        DateTime(2026, 7, 14),
        DateTime(2026, 7, 15),
      );

      expect(logs.map((l) => l.date).toList()..sort(), ['2026-07-14', '2026-07-15']);
    });
  });

  group('streaks storage', () {
    test('getHabitStreak returns zeros when missing; saveHabitStreak persists',
        () async {
      expect(repo.getHabitStreak('h1').currentStreak, 0);

      await repo.saveHabitStreak(
        HabitStreak(
          habitId: 'h1',
          currentStreak: 3,
          longestStreak: 5,
          lastCompletedDueDate: '2026-07-14',
        ),
      );

      final stored = repo.getHabitStreak('h1');
      expect(stored.currentStreak, 3);
      expect(stored.longestStreak, 5);
      expect(stored.lastCompletedDueDate, '2026-07-14');
    });

    test('perfect day streak get/save round-trip', () async {
      expect(repo.getPerfectDayStreak().currentStreak, 0);

      await repo.savePerfectDayStreak(
        PerfectDayStreak(
          currentStreak: 2,
          longestStreak: 4,
          lastPerfectDate: '2026-07-14',
        ),
      );

      final stored = repo.getPerfectDayStreak();
      expect(stored.currentStreak, 2);
      expect(stored.longestStreak, 4);
      expect(stored.lastPerfectDate, '2026-07-14');
    });
  });
}
