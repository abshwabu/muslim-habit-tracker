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
import 'package:muslim_habit_tracker/screens/add_habit_screen.dart';
import 'package:muslim_habit_tracker/services/habit_repository.dart';
import 'package:muslim_habit_tracker/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('add_habit_test_');
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
    await Hive.openBox(HiveBoxes.settings);

    await Future.wait([
      habits.clear(),
      logs.clear(),
      streaks.clear(),
      perfect.clear(),
    ]);

    repo = HabitRepository(
      habitsBox: habits,
      logsBox: logs,
      streaksBox: streaks,
      perfectDayBox: perfect,
    );

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

  Future<void> openForm(
    WidgetTester tester, {
    String? habitId,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AddHabitScreen(habitId: habitId),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('requires name before create', (tester) async {
    await openForm(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create habit'));
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(repo.getAllHabits(), isEmpty);
  });

  testWidgets('requires weekdays when specific days selected', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Fajr sunnah');
    await tester.tap(find.text('Specific days'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create habit'));
    await tester.pump();
    expect(find.text('Select at least one weekday'), findsOneWidget);
    expect(repo.getAllHabits(), isEmpty);
  });

  test('creates custom active habit via provider', () async {
    await container.read(habitsProvider.notifier).addHabit(
          Habit(
            id: const Uuid().v4(),
            name: 'Morning dua',
            icon: 'book',
            colorHex: '#3D6B4F',
            frequencyType: FrequencyType.daily,
            isCustom: true,
            isActive: true,
          ),
        );

    final habits = container.read(habitsProvider);
    expect(habits, hasLength(1));
    expect(habits.single.name, 'Morning dua');
    expect(habits.single.isCustom, isTrue);
    expect(habits.single.isActive, isTrue);
  });

  test('edit changes frequency without rewriting logs', () async {
    const id = 'custom_1';
    await repo.addHabit(
      Habit(
        id: id,
        name: 'Old daily',
        icon: 'book',
        colorHex: '#3D6B4F',
        frequencyType: FrequencyType.daily,
        isCustom: true,
        createdAt: DateTime(2026, 7, 1),
      ),
    );
    await repo.toggleCompletion(id, DateTime(2026, 7, 2));
    await repo.toggleCompletion(id, DateTime(2026, 7, 3));
    expect(repo.getLogsForHabit(id), hasLength(2));

    container.read(habitsProvider.notifier).refresh();
    await container.read(habitsProvider.notifier).updateHabit(
          Habit(
            id: id,
            name: 'Old daily',
            icon: 'book',
            colorHex: '#3D6B4F',
            frequencyType: FrequencyType.specificWeekdays,
            weekdays: const [1, 4],
            isCustom: true,
            isActive: true,
            createdAt: DateTime(2026, 7, 1),
          ),
        );

    final updated = repo.getHabit(id)!;
    expect(updated.frequencyType, FrequencyType.specificWeekdays);
    expect(updated.weekdays, [1, 4]);
    expect(updated.createdAt, DateTime(2026, 7, 1));

    final logsAfter = repo.getLogsForHabit(id);
    expect(logsAfter, hasLength(2));
    expect(
      logsAfter.map((l) => l.date).toSet(),
      {'2026-07-02', '2026-07-03'},
    );
    expect(logsAfter.every((l) => l.completed), isTrue);
  });
}
